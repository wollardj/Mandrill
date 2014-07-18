watchr = Meteor.require('watchr')
shell = Meteor.require('shelljs')
MandrillWatchers = null


Meteor.methods {

	# Shuts down any current watchers, reads the base
	# repo path from the database, clears all repo items from
	# the database, then re-initializes the watchers.
	# In otherwords, this is a way to purge and refresh the manifests and
	# other repo data from Mandrill's database.
	'updateWatchr': (gracefull)->
		repoPath = MandrillSettings.get 'munkiRepoPath'
		gracefull = gracefull or false

		if gracefull is false
			# The settings have changed, so we'll want to
			# clean out the database to make way for data from
			# any new paths that were defined.
			MunkiRepo.remove {}

		# WatcherConfig.closeWatchers();
		if MandrillWatchers?

			console.log 'Closing ' + MandrillWatchers.length +
				' top-level watchers'
			for watcher in MandrillWatchers
				watcher.close()

		if not repoPath?
			console.log 'munkiRepoPath was not defined'
			{}
		else

			MandrillSettings.set 'munkiRepoPathIsValid', shell.test('-d', repoPath)

			WatcherConfig.paths = [ repoPath ]

			MandrillWatchers = watchr.watch WatcherConfig
			{repoPath: repoPath}
}
