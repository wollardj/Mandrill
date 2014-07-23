fs = Meteor.require 'fs'
plist = Meteor.require 'plist-native'
shell = Meteor.require 'shelljs'

@CurrentWatcherPath = new Meteor.EnvironmentVariable()


@WatchHandler = {

	repoPath: ''


	# Returns one of 'catalog', 'manifest', 'pkgsinfo', pr 'unknown'
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
		else
			'unknown'

	, (e)->
		throw e




	# Removes a file from the database, using its path to find
	# the document
	deleteFile: Meteor.bindEnvironment (path)->
		repoType = WatchHandler.repoTypeForPath path

		if repoType is 'manifests'
			MunkiManifests.remove {path: path}

		else if repoType is 'pkgsinfo'
			MunkiPkgsinfo.remove {path: path}

		else if repoType is 'catalogs'
			MunkiCatalogs.remove {path: path}




	
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

		contents = shell.cat path
		parsedData = null
		parseError = null
		urlName = ''
		basePath = ''
		mongoDocument = {}
		repoType = WatchHandler.repoTypeForPath path


		# deal with any errors from fs.readFile()
		if err?
			parseError = 'Unable to read file ' + path

		else
			# Attempt to parse the plist file
			try
				parsedData = plist.parse contents
			catch e
				parseError = e.toString()


		# we'll add a url 'safe'-ish value to be used by the
		# router for better linking
		basePath = WatchHandler.repoPath + repoType + '/'
		urlName = path.replace basePath, ''
			.replace /\//g, '_'

		mongoDocument = {
			path: path
			dom: parsedData
			raw: contents
			urlName: urlName
		}

		if parseError?
			mongoDocument.err = parseError


		# For the uninitiated, 'upsert' does just what it
		# sounds like it should. If it finds a matching
		# document or documents, it/they are updated. If not,
		# the information is inserted as a new document.

		# Inserting a manifest
		if repoType is 'manifests'
			MunkiManifests.upsert {path: path}, mongoDocument,
				(err)->
					if err?
						console.error err

		# Inserting a pkgsinfo
		else if repoType is 'pkgsinfo'
			MunkiPkgsinfo.upsert {path: path}, mongoDocument,
				(err)->
					if err?
						console.error err

		# Inserting a catalog
		else if repoType is 'catalogs'
			MunkiCatalogs.upsert {path: path}, mongoDocument,
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