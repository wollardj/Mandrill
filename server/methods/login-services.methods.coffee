Meteor.methods {

	'purgeLoginServiceConfiguration': (serviceName)->
		if Mandrill.user.isAdmin(this.userId) is true
			Accounts.loginServiceConfiguration.remove {service: serviceName}
		else
			throw new Meteor.Error 403, 'Only administrators can do this.'


	'configureGithubOAuth': (clientId, secret)->
		if Mandrill.user.isAdmin(this.userId) is true
			Accounts.loginServiceConfiguration.remove {service: 'github'}
			Accounts.loginServiceConfiguration.insert {
				service: 'github'
				clientId: clientId
				secret: secret
			}
		else
			throw new Meteor.Error 403, 'Only administrators can do this.'


	'configureGoogleOAuth': (clientId, secret)->
		if Mandrill.user.isAdmin(this.userId) is true
			Accounts.loginServiceConfiguration.remove {service: 'google'}
			Accounts.loginServiceConfiguration.insert {
				service: 'google'
				clientId: clientId
				secret: secret
			}
		else
			throw new Meteor.Error 403, 'Only administrators can do this.'
}