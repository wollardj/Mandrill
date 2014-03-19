@OtherToolsRouter = AdminRouter.extend {
	template: 'othertools',

	data: ->
		{
			tools: OtherTools.find({}, {sort: {displayText: 1}}).fetch()
		}
}