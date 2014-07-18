fs = Meteor.require 'fs'
plist = Meteor.require 'plist-native'
shell = Meteor.require 'shelljs'

@CurrentWatcherPath = new Meteor.EnvironmentVariable()


@WatchHandler = {

	repoPath: ''


	# Returns one of 'catalog', 'manifest', 'pkgsinfo', 'icons', or 'unknown'
	# depending on which subdirectory within the repo the file is found.
	repoTypeForPath: Meteor.bindEnvironment (aPath)->
		repo = MandrillSettings.get 'munkiRepoPath', ''

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
	#		err:  [String],	// Only present to indicate parsing errors.
	# }
	#
	processFile: Meteor.bindEnvironment (path)->
		if shell.test('-f', path) is false
			return

		repoType = WatchHandler.repoTypeForPath path
		parseable_types = ['pkgsinfo', 'manifests', 'catalogs']
		maybe_parseable = parseable_types.indexOf(repoType) isnt -1

		if maybe_parseable is true or
				(repoType isnt 'pkgs' and repoType isnt 'icons')
			contents = shell.cat path

		parsedData = null
		parseError = null
		urlName = ''
		basePath = ''
		mongoDocument = {}

		# deal with any errors from fs.readFile()
		if err?
			parseError = 'Unable to read file ' + path

		else if maybe_parseable is true
			# Attempt to parse the plist file
			try
				parsedData = plist.parse contents
			catch e
				parseError = e.toString()


		mongoDocument = {
			path: path
			dom: parsedData
			raw: contents
			stat: fs.statSync(path)
		}

		# add some metadata about the files in the /icons dir
		if repoType is 'icons'
			icons_path = MandrillSettings.get('munkiRepoPath') + 'icons/'
			icon_file = path.replace(icons_path, '')
			mongoDocument.icon_file = icon_file
			mongoDocument.icon_name = icon_file.split('.')[0]

		if parseError?
			mongoDocument.err = parseError


		# For the uninitiated, 'upsert' does just what it
		# sounds like it should. If it finds a matching
		# document or documents, it/they are updated. If not,
		# the information is inserted as a new document.

		MunkiRepo.upsert {path: path}, mongoDocument,
			(err)->
				if err?
					console.error err
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
