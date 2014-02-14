AccountsRouter = AdminRouter.extend({
	template: 'accounts',
	
	data: function() {
		return {accounts: Meteor.users.find({}, {
			sort: {
				'mandrill.is_admin': -1,
				'profile.name': 1
			}
		}).fetch()};
	}
});