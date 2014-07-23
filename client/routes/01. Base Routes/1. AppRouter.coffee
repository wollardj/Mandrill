#/*
#	The base route controller for all route controllers in Mandrill.
#	This is where global data subscrptions are made. It's also responsible
#	for deciding when to halt the current route in order to display the
#	login page as making sure non-admins cannot see admin-only routes.
#*/
@AppRouter = RouteController.extend {


	waitOn: ()->
		user = Meteor.user()
		isLoggedIn = user?
		isAdmin = user? and user.mandrill? and user.mandrill.isAdmin is true
		subscriptions = []

		if isLoggedIn is true
			#// Setup global data subscriptions once the user has logged in.
			subscriptions.push Meteor.subscribe('MandrillSettings')
			subscriptions.push Meteor.subscribe('repoStats', user)
			subscriptions.push Meteor.subscribe('MandrillAccounts')
			subscriptions.push Meteor.subscribe('ServerStats')
			subscriptions.push Meteor.subscribe('MunkiManifests')
			subscriptions.push Meteor.subscribe('MunkiPkgsInfo')
			subscriptions.push Meteor.subscribe('MunkiCatalogs')

		# Return the subscriptions array.
		subscriptions


	onBeforeAction: (pause)->
		
		user = Meteor.user()
		isLoggedIn = user?
		isAdmin = user? and user.mandrill? and user.mandrill.isAdmin is true

		if isLoggedIn is true
			#// Setup global data subscriptions once the user has logged in.
			###this.subscribe 'OtherTools'
			this.subscribe 'MandrillSettings'
				.wait()
			this.subscribe 'repoStats', Meteor.user()
				.wait()
			this.subscribe 'MandrillAccounts'
				.wait()
			this.subscribe 'ServerStats'
				.wait()
			this.subscribe 'MunkiManifests'
				.wait()
			this.subscribe 'MunkiPkgsInfo'
				.wait()
			this.subscribe 'MunkiCatalogs'
				.wait()###


			#// If this is an admin-only route, but the user isn't an admin,
			#// we'll redirect them to the 'home' route.
			if isAdmin is false and this.adminOnly is true
				this.redirect 'home'
				pause()

		#// No one is logged in, so display the login page instead.
		#// This won't change the URL.
		else
			this.render 'login'
			pause()

	layoutTemplate: 'appLayout'
	loadingTemplate: 'loading'
	notFoundTemplate: 'notFound'
}