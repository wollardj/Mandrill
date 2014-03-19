Meteor.startup ->


	displayServerStatusDialog = (id, msg)->
		if $('#' + id).length is 0
			$('body').append('<div id="' + id +
				'" class="mandrill-error alert alert-warning fade in ' +
				'text-center small">' + msg + '</div>'
			)
		else
			$('#' + id).html(msg)
		$('#meteorRetryNowButton').on 'click', ->
			Meteor.reconnect()



	#// Display an alert when we're not connected to the server.
	Deps.autorun ->
		status = Meteor.status()
		id = 'meteor_connection_status_dialog'

		Meteor.clearInterval window.meteorConnectionStatusInterval

		if status.status is 'connected'
			$('#' + id).alert 'close'
			true
		else if status.status is 'connecting'
			displayServerStatusDialog id, 'connecting...'
		else if status.status is 'offline'
			displayServerStatusDialog id, 'offline'
		else if status.status is 'waiting'
			window.meteorConnectionStatusInterval =
				Meteor.setInterval ->
					countdown = Meteor.status().retryTime
					displayServerStatusDialog(
						id,
						'<h4>Lost Connection To Server</h4>' +
							'We\'ll try again ' +
							moment(countdown).fromNow() +
							'<br />Attempts so far: ' +
							Meteor.status().retryCount +
							'<br /><a href="#" id="' +
							'meteorRetryNowButton">Retry Now</a>'
						, 1000)
		else if status.status is 'failed'
			displayServerStatusDialog(
				id,
				'Connection failed. ' +
				status.reason
			)