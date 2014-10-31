Session.setDefault 'changePasswordFormIsReady', false
Session.setDefault 'changingPassword', false


Template.me.destroyed = ->
	Session.set 'changePasswordFormIsReady', null
	Session.set 'changingPassword', null


Template.me.helpers {
	formIsDisabled: ->
		if Session.get('changePasswordFormIsReady') isnt true
			'disabled'
		else
			''


	changingPassword: ->
		Session.get 'changingPassword'
}



Template.me.events {



	# ---- password change form ----
	'submit #changePasswordForm': (event)->
		event.stopPropagation()
		event.preventDefault()

		if Session.get('changePasswordFormIsReady') is true
			Session.set 'changingPassword', true

			currentField    = $('#currentPassword')
			newField        = $('#newPassword')
			verifyField     = $('#verifyPassword')

			Accounts.changePassword currentField.val(), newField.val(), (err)->
				Session.set 'changingPassword', false
				if err?
					Mandrill.show.error err
				else
					Mandrill.show.success(
						'',
						'Password Successfully Changed!'
					)

			currentField.val ''
			newField.val ''
			verifyField.val ''
			currentField.focus()


	'keyup #currentPassword, keyup #newPassword, keyup #verifyPassword': ->
		currentField    = $('#currentPassword')
		newField        = $('#newPassword')
		verifyField     = $('#verifyPassword')
		currentIsEmpty = currentField.val() is ''
		newIsEmpty     = newField.val() is ''
		passwordsMatch  = newField.val() is verifyField.val()

		Session.set 'changePasswordFormIsReady', newIsEmpty is false and
			currentIsEmpty is false and
			passwordsMatch is true





	# ---- Name change form ----


	'keyup #changeFullName': (event)->
		Meteor.users.update(
			{_id: Meteor.userId()},
			{'$set': {
				'profile.name': $(event.target).val()
			}}
		)
}
