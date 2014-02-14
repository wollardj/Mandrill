/*
	Provides data for updating the currently logged
	in user's information. "/me"
 */
MeRouter = AppRouter.extend({
	template: 'me',
	data: function() {
		return Meteor.user();
	}
});