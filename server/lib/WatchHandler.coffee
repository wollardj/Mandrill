fs = Meteor.npmRequire 'fs'
plist = Meteor.npmRequire 'plist-native'
shell = Meteor.npmRequire 'shelljs'

@CurrentWatcherPath = new Meteor.EnvironmentVariable()


@WatchHandler = {

	repoPath: ''


	# Returns one of 'catalog', 'manifest', 'pkgsinfo', 'icons', or 'unknown'
	# depending on which subdirectory within the repo the file is found.
	repoTypeForPath: Meteor.bindEnvironment (aPath)->
		repo = Munki.repoPath()

		if repo isnt ''
			WatchHandler.repoPath = repo

		if aPath.indexOf(repo + 'manifests/') isnt -1
			'manifests'

		else if aPath.indexOf(repo + 'catalogs/') isnt -1
			'catalogs'
		else if aPath.indexOf(repo + 'pkgsinfo/') isnt -1
			'pkgsinfo'
		else if aPath.indexOf(repo + 'pkgs/') isnt -1
			'pkgs'
		else if aPath.indexOf(repo + 'icons/') isnt -1
			'icons'
		else
			'unknown'

	, (e)->
		throw e




	# Removes a file from the database, using its path to find
	# the document
	deleteFile: Meteor.bindEnvironment (path)->
		MunkiRepo.remove {path: path}
	, (e)->
		throw e





	# Reads a file at the given path and attempts to parse its plist
	# contents. If the file cannot be read from disk, an exception is
	# thrown. In all other cases, including a failure to parse, a document
	# is added to the databse.
	# If there were errors while parsing, those errors will be added to
	# that document.
	# Both the parsed (when succesful) and raw text repesentations of the
	# file live in the document as well. The full structure is...
	#
	# {
	#		dom:  [Object],	// the parsed object structure
	#		raw:  [String],	// the raw text of the file
	#		path: [String],	// the full path to the file on disk
	#		stat: [Object], // fs stats for the file
	#		icon_file: [String]
	#		icon_name: [String]
	#		err:  [String],	// Only present to indicate parsing errors.
	# }
	#
	processFile: Meteor.bindEnvironment (path)->
		if shell.test('-f', path) is false
			console.log 'Skipping non-file', path
			return

		repoType = WatchHandler.repoTypeForPath path
		doc = {path: path, stat: fs.statSync(path)}

		# read the first 1024 bytes of the file to be used as a sample
		# for determining if the entire file is text or binary,
		buffer_size = if doc.stat.size > 1024 then 1024 else doc.stat.size
		maybe_parseable = true
		if buffer_size > 0
			handle = fs.openSync path, 'r'
			buffer = new Buffer(buffer_size)
			fs.readSync handle, buffer, 0, buffer_size
			fs.closeSync handle
			# if the file is text (not binary) we'll try to parse it and
			# store its contents in the database.
			sample = buffer.toString('utf8', 0, buffer_size)
			for i in [0...sample.length]
				code = sample.charCodeAt(i)
				if code is 65533 or code <= 8
					maybe_parseable = false
					break
		else
			maybe_parseable = false



		if maybe_parseable is true
			doc.raw = fs.readFileSync path, 'utf8'

			# Attempt to parse the plist file
			try
				doc.dom = plist.parse doc.raw
			catch e
				doc.err = e.toString()


		# add some metadata about the files in the /icons dir
		if repoType is 'icons'
			repo_path = Munki.repoPath()
			icons_path = Mandrill.path.concat(repo_path, 'icons/')
			doc.icon_file = path.replace(icons_path, '')
			doc.icon_name = Mandrill.path.concatRelative(
				doc.icon_file.split('.')[0]
			)


		# For the uninitiated, 'upsert' does just what it
		# sounds like it should. If it finds a matching
		# document or documents, it/they are updated. If not,
		# the information is inserted as a new document.

		MunkiRepo.upsert {path: path}, doc
	, (e)->
		throw e



	#
	# Obtains a flat array of paths being watched by a watcher
	# and its child watchers.
	#
	watcherPaths: (watcher)->
		children = watcher.children
		files = []

		for own key, nodeName of children
			try
				stat = fs.lstatSync nodeName.path
			catch e
				# the file does not appear to exist, so we'll skip it
				continue

			if stat.isDirectory() is true
				files = files.concat(
					WatchHandler.watcherPaths nodeName
				)

			else
				files.push nodeName.path
		files
}
