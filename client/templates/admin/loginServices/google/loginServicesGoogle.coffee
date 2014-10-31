Template.loginServicesGoogle.helpers {
	clientId: ->
		data = Accounts.loginServiceConfiguration.findOne {service: 'google'}
		if data? and data.clientId?
			data.clientId
		else
			''
}


Template.loginServicesGoogle.events {
	'click #purge-google': ->
		really = confirm 'You will no longer be able to use Google ' +
			'to authenticate to Mandrill. Are you sure?'
		if really is yes
			Meteor.call(
				'purgeLoginServiceConfiguration',
				'google',
				(error)->
					if error?
						alert JSON.stringify(error)
			)


	'submit form': (event)->
		event.stopPropagation()
		event.preventDefault()
		clientId = $('#google_clientId').val()
		secret = $('#google_secret').val()

		Meteor.call 'configureGoogleOAuth', clientId, secret
}
