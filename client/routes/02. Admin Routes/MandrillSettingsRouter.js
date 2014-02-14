MandrillSettingsRouter  = AdminRouter.extend({
	template: 'mandrillSettings',

	data: function() {
		return {settings: MandrillSettings.findOne()};
	}
});