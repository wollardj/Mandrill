//
// Options which when passed to an instance of watchr, define
// how watchr operates. See https://github.com/bevry/watchr
// It needs the paths array to be set manually though. Setting
// them here in this file would require even more calls to
// Meteor.bindEnvironment when we could just do it in the main
// fiber.
//
WatcherConfig = {
	paths: [],
	ignoreHiddenFiles: true,


	// We're going to wrap all of these calls to Meteor.bindEnvironment
	// since we expect that they'll likely be called now, and again
	// after the current fiber has exited.
	listeners: {
		log: Meteor.bindEnvironment(function(logLevel) {
			if (logLevel !== 'debug') {
				console.log('a log message occured:', arguments);
			}
		}, function(e) {
			throw e;
		}),

		error: function(err) {
			// This function seems to get null passed to it quite a bit
			if (err !== null) {
				console.error('an error occured:', arguments);
			}
		},

		watching: function(err, watcherInstance) {
			var paths;

			if (err) {
				console.error('Could not setup watchr for ' +
					watcherInstance.path, err);
			}
			else {
				console.log('Watching for changes in ' +
					watcherInstance.path);

				// watchr has finished adding its watcher for this path,
				// so now we can harvest that information and start
				// putting stuff in the database.
				paths = WatchHandler.watcherPaths(watcherInstance);
				for(var j = 0; j < paths.length; j++) {
					WatchHandler.processFile(paths[j]);
				}

			}
		},

		// When a file is updated, created, or deleted, this method
		// gets called.
		change: Meteor.bindEnvironment(
			function(type, path) {
				if (type !== 'delete') {
					WatchHandler.processFile(path);
				}
				else {
					WatchHandler.deleteFile(path);
				}
			}, function(e) {
				throw e;
			}
		)
	}
};