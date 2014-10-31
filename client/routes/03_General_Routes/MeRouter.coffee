@MeRouter = AppRouter.extend {
	template: 'me',
	data: ->
		Meteor.user()
}