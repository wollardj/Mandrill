Template.loginServicesGithub.helpers {
	clientId: ->
		data = Accounts.loginServiceConfiguration.findOne {service: 'github'}
		if data? and data.clientId?
			data.clientId
		else
			''
}


Template.loginServicesGithub.events {
	'click #purge-github': ->
		really = confirm 'You will no longer be able to use GitHub ' +
			'to authenticate to Mandrill. Are you sure?'
		if really is yes
			Meteor.call(
				'purgeLoginServiceConfiguration',
				'github',
				(error)->
					if error?
						alert JSON.stringify(error)
			)


	'submit form': (event)->
		event.stopPropagation()
		event.preventDefault()
		clientId = $('#github_clientId').val()
		secret = $('#github_secret').val()

		Meteor.call 'configureGithubOAuth', clientId, secret
}
