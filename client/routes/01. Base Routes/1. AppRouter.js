/*
	The base route controller for all route controllers in Mandrill.
	This is where global data subscrptions are made. It's also responsible
	for deciding when to halt the current route in order to display the
	login page as making sure non-admins cannot see admin-only routes.
 */
AppRouter = RouteController.extend({
	onBeforeAction: function (pause) {
		
		var user = Meteor.user(),
			isLoggedIn = user !== null,
			isAdmin = user && user.mandrill && user.mandrill.isAdmin === true;

		if (isLoggedIn === true) {
			// Setup global data subscriptions once the user has logged in.
			this.subscribe('OtherTools');
			this.subscribe('MandrillSettings').wait();
			this.subscribe('repoStats', Meteor.user()).wait();
			this.subscribe('MandrillAccounts').wait();
			this.subscribe('ServerStats');

			// If this is an admin-only route, but the user isn't an admin,
			// we'll redirect them to the 'home' route.
			if (isAdmin === false && this.adminOnly === true) {
				this.redirect('home');
				pause();
			}
		}

		// No one is logged in, so display the login page instead.
		// This won't change the URL.
		else {
			this.render('login');
			pause();
		}
	},

	layoutTemplate: 'appLayout',
	loadingTemplate: 'loading',
	notFoundTemplate: 'notFound'
});