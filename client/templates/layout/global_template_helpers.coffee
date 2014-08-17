Meteor.startup ->


	UI.registerHelper 'session_get', (key)->
		Session.get key

	UI.registerHelper 'session_equals', (key, val)->
		Session.equals key, val


	UI.registerHelper 'formatBytes', (bytes)->
		suffix = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
		if bytes?
			i = 0
			size = bytes
			while size > 1024
				size /= 1024
				i++
			Math.round(size) + suffix[i]
		else
			'??'


	Handlebars.registerHelper 'momentFromNow', (someDate)->
		moment(someDate).fromNow()


	Handlebars.registerHelper 'meteorOnline', ->
		Meteor.status().status is 'connected'

	#/*
	#	Analyes Meteor.status() and returns en empty string if we're
	#	connected. Otherwise, this will return a message.
	#	Examples of strings:
	#
	#	- when status is "waiting"
	#		"Attempt 1. Will try again in 3 seconds"
	#	- when status is "connecting"
	#		"connecting..."
	#	- when status is "offline"
	#		"Offline"
	#	- when status is "failed"
	#		"Connection failed. [...]" where [...] is the failure message
	#*/
	Handlebars.registerHelper 'meteorStatus', ->
		status = Meteor.status()
		if status.status is 'connected'
			true
		else if status.status is 'connecting'
			'connecting...'
		else if status.status is 'offline'
			'offline'
		else if status.status is 'waiting'
			'Attempt ' + status.retryCount +
				'. Will try again in ' + status.retryTime
		else if status.status is 'failed'
			'Connection failed. ' + status.reason


	Handlebars.registerHelper 'currentRoute', ->
		Router.current().route.name


	Handlebars.registerHelper 'mandrillVersion', ->
		Mandrill.version


	Handlebars.registerHelper 'meteorVersion', ->
		Meteor.release

	Handlebars.registerHelper 'absoluteUrl', ->
		Meteor.absoluteUrl()


	UI.registerHelper 'timeago', (a_date)->
		moment(a_date).fromNow()


	#// Determines if the current user is an admin.
	Handlebars.registerHelper 'isAdmin', ->
		user = Meteor.user()
		user? and user.mandrill? and user.mandrill.isAdmin is true


	Handlebars.registerHelper 'loginServiceIsConfigured', (serviceName)->
		service = Accounts.loginServiceConfiguration.findOne {service: serviceName}
		if service?
				true
		else
			false

	Handlebars.registerHelper 'loginServicesOAuthIsAvailable', ->
		services = Accounts.loginServiceConfiguration.find().count()
		if services? and services > 0
			true
		else
			false
