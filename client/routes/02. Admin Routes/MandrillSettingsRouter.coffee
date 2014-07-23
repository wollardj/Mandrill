@MandrillSettingsRouter  = AdminRouter.extend {
	template: 'mandrillSettings',

	data: ->
		{settings: MandrillSettings.findOne()}
}