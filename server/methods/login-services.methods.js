Meteor.methods({


	'purgeLoginServiceConfiguration': function(serviceName) {
		Accounts.loginServiceConfiguration.remove({service: serviceName});
	},


	'configureGithubOAuth': function(clientId, secret) {
		Accounts.loginServiceConfiguration.remove({service: 'github'});
		Accounts.loginServiceConfiguration.insert({
			service: 'github',
			clientId: clientId,
			secret: secret
		});
	},


	'configureGoogleOAuth': function(clientId, secret) {
		Accounts.loginServiceConfiguration.remove({service: 'google'});
		Accounts.loginServiceConfiguration.insert({
			service: 'google',
			clientId: clientId,
			secret: secret
		});
	}
});