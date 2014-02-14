Meteor.startup(function() {
	var setupAfterPortIsBound = Meteor.bindEnvironment(function() {
			// Make sure the database and repo filesystem are in sync
			Meteor.call('updateWatchr', true);


			// Start polling and updating the system stats, but call it once right
			// now so that we have information as of server startup time.
			ServerStatsCollector.collect();
			Meteor.setInterval(function() {
				ServerStatsCollector.collect();
			}, 60 * 1000);
	}, function(e) {
		throw e;
	});


	WebApp.httpServer.on('listening', function() {

		// If the environment variable 'MANDRILL_MODE' is set to 'production',
		// assume we're running as root for the purpose of binding to ports
		// below 1024 and demote our privileges. This is done by switching the
		// process owner to the '_mandrill' user - similar to what Apache does.

		if (process.env.MANDRILL_MODE && process.env.MANDRILL_MODE === 'production') {
			// Make sure we're running as the _mandrill user
			var oldUid = process.getuid();
			try {
				process.setuid('_mandrill');
				console.log('Changed process uid from ' + oldUid +
					' to ' + process.getuid());
			}
			catch (err) {
				console.error('Refusing to run as any user other than _mandrill');
				process.abort();
			}
		}

		setupAfterPortIsBound();

	});


	// Only allow new accounts to be created on the server-side.
	Accounts.config({
		forbidClientAccountCreation: true
	});


	// Create the initial admin account
	if (Meteor.users.find().count() === 0) {

		var id = Accounts.createUser({
			username: 'admin',
			password: 'admin',
			email: 'admin@localhost',
			profile: {
				name: 'Mandrill Admin'
			}
		});

		console.log('Added factory admin account [_id: ' + id + ']');
		Meteor.users.update({_id: id}, {'$set': {
			'mandrill.isAdmin': true
		}});
	}


	// Setup some default settings
	if (MandrillSettings.find().count() === 0) {
		MandrillSettings.insert({
			'munkiRepoPath': '/Users/Shared/munki_repo/',
			'gitIsEnabled': false,
			'gitBinaryPath': '/usr/bin/git'
		});
	}
});
