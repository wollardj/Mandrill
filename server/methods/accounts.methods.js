Meteor.methods({

	'isCurrentUserAnAdmin': function() {
		var user = Meteor.user();
		if (!user) {
			return false;
		}
		return user.mandrill.isAdmin;
	},


	'logoutUserWithId': function(id) {
		if (!id) {
			throw new Meteor.Error(400,
				'Cannot logout a user without a user id.');
		}
		// set services.resume to an empty array, which wipes out the
		// loginTokens.
		Meteor.users.update({_id: id}, {
			'$set': {
				'services.resume.loginTokens': []
			}
		});
	},


	'resetLocalPasswordForUserId': function(id) {
		var pass = Mandrill.util.generateRandomString(15);
		if (!id) {
			throw new Meteor.Error(400, 'Cannot change the password for ' +
				'an account without an account id');
		}

		Accounts.setPassword(id, pass);
		return {id: id, result: pass};
	},



	// Allows an admin to create a local account without that account then
	// being automatically logged in, which is the default behavior when
	// performed from the client.
	'createLocalAccount': function(username, email) {
		var pass = Mandrill.util.generateRandomString(15),
			userExists = Meteor.users.findOne({'emails.address': email});

		// Make sure the email address is at least valid enough to _look_
		// like one. Basically, an address meeting the minimum
		// requirements would be three characters long, with the middle
		// character being '@' and neither of the outer characters
		// being '@'
		if (!email.match(/^[^@]+@[^@]+$/)) {
			throw new Meteor.Error(406,
				'"' + email + '" is not a valid email address');
		}

		if (userExists) {
			throw new Meteor.Error(403,
				'An account with that email address already exists.');
		}
		
		Accounts.createUser({
			username: username,
			email: email,
			password: pass
		});
		return pass;
	}
});