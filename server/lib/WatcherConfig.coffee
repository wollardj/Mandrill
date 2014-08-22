#
# Options which when passed to an instance of watchr, define
# how watchr operates. See https://github.com/bevry/watchr
# It needs the paths array to be set manually though. Setting
# them here in this file would require even more calls to
# Meteor.bindEnvironment when we could just do it in the main
# fiber.
#
@WatcherConfig = {
	paths: []
	ignoreCommonPatterns: true
	ignoreHiddenFiles: false


	# We're going to wrap all of these calls to Meteor.bindEnvironment
	# since we expect that they'll likely be called now, and again
	# after the current fiber has exited.
	listeners: {
		log: Meteor.bindEnvironment (logLevel)->
			if logLevel isnt 'debug'
				console.log 'a log message occured:', arguments
		, (e)->
			throw e

		error: (err)->
			console.error 'an error occured:', arguments


		watching: Meteor.bindEnvironment (err, watcherInstance)->

			if err?
				console.error 'Could not setup watchr for ' +
					watcherInstance.path, err

			else
				console.log 'Watching for changes in ' +
					watcherInstance.path

				# watchr has finished adding its watcher for this path,
				# so now we can harvest that information and start
				# putting stuff in the database.
				WatcherConfig.paths = WatchHandler.watcherPaths watcherInstance
				console.log 'Processing', WatcherConfig.paths.length, 'files...'
				for path in WatcherConfig.paths
					WatchHandler.processFile path
				console.log "Done!"

				# Make sure the files for the path are in the git repo for bug
				# https://github.com/wollardj/Mandrill/issues/14
				if GitBroker.gitIsEnabled() is true
					GitBroker.add watcherInstance.path + '/*'
					GitBroker.commit(
						'Mandrill Admin'
						watcherInstance.path + '/*'
						'[Mandrill] Adding all new files to the repo'
						''
						true
					)
		, (e)->
			throw e


		# When a file is updated, created, or deleted, this method
		# gets called.
		change: Meteor.bindEnvironment (type, path)->
			if type isnt 'delete'
				WatchHandler.processFile path
				# Make sure the files for the path are in the git repo for bug
				# https://github.com/wollardj/Mandrill/issues/14
				if GitBroker.gitIsEnabled() is true
					GitBroker.add path
					GitBroker.commit(
						'Mandrill Admin'
						path
						'[Mandrill] Importing ' + _.last(path.split('/')) + ' to the repo'
						'Full path: ' + path,
						true
					)

			else
				WatchHandler.deleteFile path
		, (e)->
			throw e
	}
}
