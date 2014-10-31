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
		isAdmin = user? and user.mandrill? and user.mandrill.isAdmin is true

		if user?
			# Setup global data subscriptions once the user has logged in.
			return [
				Meteor.subscribe('MandrillStats')
				Meteor.subscribe('MandrillSettings')
				Meteor.subscribe('MandrillAccounts')
				Meteor.subscribe('ServerStats')
				Meteor.subscribe('MunkiSettings')
				Meteor.subscribe('MunkiRepo')
				Meteor.subscribe('MunkiLogs')
			]
		else
			# Return an empty array if no one is logged in.
			[]


	onBeforeAction: ->
		user = Meteor.user()
		isAdmin = user? and user.mandrill? and user.mandrill.isAdmin is true

		if user?
			# If this is an admin-only route, but the user isn't an admin,
			# we'll redirect them to the 'home' route.
			if isAdmin is false and this.adminOnly is true
				this.render 'notFound'
			else
				this.next()

		# No one is logged in, so display the login page instead.
		# This won't change the URL.
		else
			this.render 'login'
