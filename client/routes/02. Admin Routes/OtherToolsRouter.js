OtherToolsRouter = AdminRouter.extend({
	template: 'othertools',

	data: function() {
		return {
			tools: OtherTools.find({}, {sort: {displayText: 1}}).fetch()
		}
	}
});