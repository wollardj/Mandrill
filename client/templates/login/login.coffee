Template.login.rendered = ()->
	$('#login_username').focus()



Template.login.events {
	'submit form': (event)->
		event.stopPropagation()
		event.preventDefault()

		username = $('#login_username').val()
		password = $('#login_password').val()

		$('#login_password').val('')
		Meteor.loginWithPassword username, password, (err)->
			if err?
				Mandrill.show.error err

	'click #login-with-google': ->
		Meteor.loginWithGoogle null, (err)->
			if err?
				Mandrill.show.error err

	'click #login-with-github': ->
		Meteor.loginWithGithub null, (err)->
			if err?
				Mandrill.show.error err
}