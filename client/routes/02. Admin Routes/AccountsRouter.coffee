@AccountsRouter = AdminRouter.extend {
	template: 'accounts',
	
	data: ->
		{
			accounts: Meteor.users.find({}, {
				sort: {
					'mandrill.is_admin': -1,
					'profile.name': 1
				}
			}).fetch()
		}
}