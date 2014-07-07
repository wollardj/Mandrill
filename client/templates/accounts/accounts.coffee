Template.accounts.accounts = ->
	Meteor.users.find({}, {
		sort: {
			'mandrill.is_admin': -1,
			'profile.name': 1
		}
	})



Template.accounts.rendered = ->
	Mandrill.tpl.activateTooltips()


Template.accounts.emailAddresses = ->
	emails = []
	emails.push e.address for e in this.emails
	emails.join(', ')



Template.accounts.accessPatternsCount = ->
	patt = this.mandrill.accessPatterns or []
	"#{patt.length} rule" + (if patt.length isnt 1 then 's' else '')


Template.accounts.isLoggedIn = ->
	this.services and
		this.services.resume and
		this.services.resume.loginTokens and
		this.services.resume.loginTokens.length > 0


Template.accounts.isBanned = ->
	this.mandrill.isBanned



Template.accounts.isCurrentUser = ->
	Meteor.userId() is this._id



Template.accounts.loginServicesIcons = ->
	icons = ''
	name = if this.profile and this.profile.name then this.profile.name else this.username

	icons += '<i data-toggle="tooltip" title="' + name +
		' has a local account" class="glyphicon glyphicon-user"></i>'

	if this.services and this.services.google
		icons += ' <img data-toggle="tooltip" title="' + name +
			' has logged in using Google" height="15px" ' +
			'style="margin-bottom: 6px" src="' +
			'https://www.google.com/favicon.ico" />'

	if this.services and this.services.github
		icons += ' <img data-toggle="tooltip" title="' + name +
			' has logged in using Github" height="15px" ' +
			'style="margin-bottom: 6px" ' +
			'src="http://www.github.com/favicon.ico" />'

	new Handlebars.SafeString(icons)




Template.accounts.events {



	#/// ---- editing emails ---- ///
	'click td.edit-email': (event)->
		target = $(event.target).closest('td')
		span = target.find 'span'
		textarea = target.find 'textarea'

		span.addClass 'hidden'
		textarea.removeClass 'hidden'
		textarea.focus()


	'blur textarea': (event)->
		target = $(event.target).closest('td')
		record = this
		cleanedEmails = []

		span = target.find 'span'
		textarea = target.find 'textarea'

		#// Clean up the email list.
		for email in textarea.val().split(/[, ]/g)
			do (email) ->
				if email.search(/^[^@]*@[^@]*$/) is 0
					#// We should be preserving the verified state, but
					#// it' not quite as important to Mandrill as it would be
					#// to a public-facing social media site. Plust there's no
					#// UI mechanism for sending verification emails yet.
					cleanedEmails.push {address: email, verified: false}
		cleanedEmails


		#// Commit the new email list back to the database.
		Meteor.users.update {_id: this._id}, {'$set':{'emails': cleanedEmails}}

		_emailAddressExists = (service, emails)->
			found = false
			for email in emails
				if service.email is email.email
					found = true
					break
			found
		
		#// Look for orphaned service accounts and remove them.
		for own key, value of this.services
			if key is 'password' or key is 'resume'
				continue

			if _emailAddressExists(value, cleanedEmails) is false
				path = 'services.' + key
				obj = {'$unset':{}};
				obj.$unset[path] = '';
				Meteor.users.update {_id: record._id}, obj

		#// Reset the page
		textarea.addClass 'hidden'
		span.removeClass 'hidden'




	#/// ---- managing user state ---- ///




	'click a.glyphicon-trash': (event)->
		event.stopPropagation()
		event.preventDefault()

		answer = confirm 'Are you sure you want to delete this account?'
		if answer is yes
			Meteor.users.remove {_id: this._id}


	'click button.logout': (event)->
		event.stopPropagation()
		event.preventDefault()
		username = this.username
		Meteor.call 'logoutUserWithId', this._id, (err)->
			if err?
				Mandrill.show.error err
			else
				Mandrill.show.success 'Logout Successful', username +
					' has been logged out of all browser sessions.'


	#//
	#// Ban the selected user as long as it's not the current admin.
	#//
	'click button.ban-user': ->
		if Meteor.userId() is this._id
			return
		
		if this.mandrill.isBanned is true
			Meteor.users.update {_id: this._id}, {'$set': {
					'mandrill.isBanned': false
				}
			}
		else
			Meteor.users.update {_id: this._id}, {'$set': {
					'mandrill.isBanned': true
				}
			}


	'click button.reset-password': (event)->
		event.stopPropagation()
		event.preventDefault()
		username = this.username

		Meteor.call 'resetLocalPasswordForUserId', this._id, (err, data)->
			if err?
				Mandrill.show.error err
				return
	
			Mandrill.show.success(
					'Password reset for "' + username + '"',
					'The new password is <code>' + data.result + '</code>'
			)


	#//
	#// Inverts the selected accounts admin status, as long as it's not
	#// the account of the current admin.
	#//
	'click button[data-toggle-admin]': (event)->
		event.stopPropagation()
		event.preventDefault()
		
		if Meteor.userId() is this._id
			return

		if this.mandrill.isAdmin is true
			Meteor.users.update {_id: this._id}, {'$set': {
					'mandrill.isAdmin': false
				}
			}
		else
			Meteor.users.update {_id: this._id}, {'$set': {
					'mandrill.isAdmin': true
				}
			}


	#//
	#// Re-routes the admin to /accounts/access/<user-id>
	#//
	'click button[data-show-access]': (event)->
		event.stopPropagation()
		event.preventDefault()
		Router.go 'accounts-access', {_id: this._id}



	#/// ---- adding a new account ---- ///


	'submit form': (event)->
		event.stopPropagation()
		event.preventDefault()
		email = $('#new_email').val().toLowerCase()
		username = email.replace(/@.*$/, '')

		$('#new_email').val('')

		Meteor.call(
			'createLocalAccount',
			username,
			email,
			(error, data)->
				if error?
					Mandrill.show.error error
				else
					Mandrill.show.success(
						'Account Created',
						'The password for this account is <code>' + data +
						'</code>'
					)
		)
}