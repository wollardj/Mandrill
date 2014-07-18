#/*
#	The base route controller for all route controllers in Mandrill.
#	This is where global data subscrptions are made. It's also responsible
#	for deciding when to halt the current route in order to display the
#	login page as making sure non-admins cannot see admin-only routes.
#*/
class @AppRouter extends RouteController


	layoutTemplate: 'appLayout'
	loadingTemplate: 'loading'
	notFoundTemplate: 'notFound'


	waitOn: ->
		user = Meteor.user()
		isLoggedIn = user?
		isAdmin = user? and user.mandrill? and user.mandrill.isAdmin is true

		if isLoggedIn is true
			# Setup global data subscriptions once the user has logged in.
			return [
				Meteor.subscribe('MandrillStats')
				Meteor.subscribe('MandrillSettings')
				Meteor.subscribe('MandrillAccounts')
				Meteor.subscribe('ServerStats')
				Meteor.subscribe('MunkiRepo')
			]
		else
			# Return an empty array if no one is logged in.
			[]


	onBeforeAction: (pause)->

		user = Meteor.user()
		isLoggedIn = user?
		isAdmin = user? and user.mandrill? and user.mandrill.isAdmin is true

		if isLoggedIn is true
			# If this is an admin-only route, but the user isn't an admin,
			# we'll redirect them to the 'home' route.
			if isAdmin is false and this.adminOnly is true
				this.redirect 'home'
				pause()

		# No one is logged in, so display the login page instead.
		# This won't change the URL.
		else
			this.render 'login'
			pause()
