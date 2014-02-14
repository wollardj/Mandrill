AccountsAccessRouter = AdminRouter.extend({
	template: 'accounts-access',

	data: function() {
		return {user: Meteor.users.findOne({_id: this.params._id})};
	}
});