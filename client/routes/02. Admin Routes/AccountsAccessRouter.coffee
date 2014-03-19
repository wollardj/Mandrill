@AccountsAccessRouter = AdminRouter.extend {
	template: 'accountsAccess',

	data: ->
		{user: Meteor.users.findOne({_id: this.params._id})}
}