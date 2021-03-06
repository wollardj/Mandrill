Accounts.validateNewUser (user)->
	# The username is set when an account is created in the admin
	# interface. If that's not present, the admin didn't create this
	# account, so it shouldn't be allowed to be created.
	service = _.keys(user.services)[0]
	email = user.services[service].email
	if not user.username?
		throw new Meteor.Error 403,
			'Ask your Mandrill admin to create an account using your ' +
			'<strong>' + email + '</strong> email address.'
	true




#
#	A hackish method of merging two or more OAuth accounts into one using
#	the email address as a joining key. The method was adapted from
#	https://groups.google.com/d/msg/meteor-talk/GedMfxVdohQ/Ad861PRk3pwJ
#
Accounts.onCreateUser (options, user)->

	extractEmail = (service)->
		if service is 'password'
			email = user.emails[0].address
		else
			email = user.services[service].email

		if not email?
			throw new Meteor.Error 400,
				'Unable to detect an email address for the new account'
		email
	

	if user.services?
		service = _.keys(user.services)[0]
		email = extractEmail service
		existingUser = Meteor.users.findOne {'$or': [
			{'mandrill.email_address': email}
			{'emails.address': email}
			{'services.google.email': email}
			{'services.github.email': email}
		]}

		if not options.profile?
			options.profile = {}

		if not options.profile.name?
			options.profile.name = email.replace /@.*$/, ''

		if not existingUser?
			if options.profile?
				user.profile = options.profile

			user.mandrill = {}
			return user

		# precaution, these will exist from accounts-password if used
		if not existingUser? or not existingUser.services?
			existingUser.services = {resume: {loginTokens: []}}

		# create or overwrite the existing profile (e.g. 'name')
		existingUser.profile = options.profile

		# copy accross new service info
		existingUser.services[service] = user.services[service]
		if existingUser.services.resume? and
				existingUser.services.resume.loginTokens? and
				user.services.resume? and
				user.services.resume.loginTokens?

			existingUser.services.resume.loginTokens.push(
				user.services.resume.loginTokens[0]
			)

		if not existingUser? or not existingUser.mandrill?
			existingUser.mandrill = {}

		# even worse hackery
		# remove existing record
		Meteor.users.remove {_id: existingUser._id}
		existingUser # record is re-inserted