var watchr = Meteor.require('watchr'),
	shell = Meteor.require('shelljs'),
	MandrillWatchers;


Meteor.methods({

	// Shuts down any current watchers, reads the base
	// repo path from the database, clears all repo items from
	// the database, then re-initializes the watchers.
	// In otherwords, this is a way to purge and refresh the manifests and
	// other repo data from Mandrill's database.
	'updateWatchr': function(gracefull) {
		var settings = MandrillSettings.findOne(),
			gracefull = gracefull || false;

		if (gracefull === false) {
			// The settings have changed, so we'll want to
			// clean out the database to make way for data from
			// any new paths that were defined.
			MunkiManifests.remove({});
			MunkiCatalogs.remove({});
			MunkiPkgsinfo.remove({});
		}

		//WatcherConfig.closeWatchers();
		if (MandrillWatchers) {

			console.log('Closing ' +
				MandrillWatchers.length +
				' top-level watchers');
			for(var i = 0; i < MandrillWatchers.length; i++) {
				MandrillWatchers[i].close();
			}
		}

		if (!settings.munkiRepoPath) {
			console.log('munkiRepoPath was not defined');
			return {};
		}

		MandrillSettings.update(settings._id, {
			'$set':{
				munkiRepoPathIsValid: shell.test('-d', settings.munkiRepoPath)
			}
		});


		WatcherConfig.paths = [
			settings.munkiRepoPath + 'pkgsinfo/',
			settings.munkiRepoPath + 'manifests/',
			settings.munkiRepoPath + 'catalogs/'
		];

		MandrillWatchers = watchr.watch(WatcherConfig);
		return {repoPath: settings.munkiRepoPath};
	}
});