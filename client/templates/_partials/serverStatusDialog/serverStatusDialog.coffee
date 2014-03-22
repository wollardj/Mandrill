Session.setDefault 'statusDialogMomentTimer', null

Template.serverStatusDialog._momentInterval = null

Template.serverStatusDialog.watchConnectionStatus = ->

	status = Meteor.status()

	if status? and status.status? and status.status is 'connected'
		if Template.serverStatusDialog._momentInterval?
			Meteor.clearInterval Template.serverStatusDialog._momentInterval
	else
		if Template.serverStatusDialog._momentInterval?
			Meteor.clearInterval Template.serverStatusDialog._momentInterval

		Template.serverStatusDialog._momentInterval = Meteor.setInterval ->
			Session.set 'statusDialogMomentTimer', new Date()
		, 1000
	''


Template.serverStatusDialog.className = ->
	status = Meteor.status()
	dialog = $('#meteor_connection_status_dialog')

	if status? and status.status? and status.status is 'connected'
		if dialog.hasClass('elastic-in') is true
			dialog.removeClass('elastic-in').addClass('elastic-out')
	else
		dialog.removeClass('elastic-out').addClass('elastic-in')

	''




Template.serverStatusDialog.title = ->
	status = Meteor.status()

	if status? and status.status?
		if status.status is 'waiting'
			'Lost Connection To Server'
		else if status.status is 'connecting'
			'Connecting'
		else
			''
	else
		''


Template.serverStatusDialog.isWaiting = ->
	status = Meteor.status()
	status? and status.status? and status.status is 'waiting'


Template.serverStatusDialog.body = ->
	status = Meteor.status()
	now = Session.get 'statusDialogMomentTimer'
	if status? and status.status?
		if status.status is 'connecting'
			new Handlebars.SafeString '<span class="glyphicon glyphicon-time"></span>'
		else if status.status is 'offline'
			'offline'
		else if status.status is 'waiting'
			countdown = Meteor.status().retryTime
			new Handlebars.SafeString 'We\'ll try again in ' +
				moment(countdown).countdown().toString() +
				'<br />Attempts so far: ' + Meteor.status().retryCount
		else if status.status is 'failed'
			'Connect Failed'
		else
			''
	else
		''


Template.serverStatusDialog.events {
	'click #meteorRetryNowButton': (event)->
		event.stopPropagation()
		event.preventDefault()
		Meteor.reconnect()
}