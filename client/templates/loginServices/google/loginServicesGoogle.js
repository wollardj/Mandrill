Template.loginServicesGoogle.clientId = function () {
	var data = Accounts.loginServiceConfiguration.findOne(
		{service: 'google'}
	);
	if (data) {
		return data.clientId;
	}
	return '';
};



Template.loginServicesGoogle.events({
	'click #purge-google': function() {
		var really = confirm('You will no longer be able to use Google ' +
			'to authenticate to Mandrill. Are you sure?');
		if (really === true) {
			Meteor.call(
				'purgeLoginServiceConfiguration',
				'google',
				function(error) {
					if (error) {
						alert(JSON.stringify(error));
					}
				}
			);
		}
	},


	'submit form': function(event) {
		event.stopPropagation();
		event.preventDefault();
		var clientId = $('#google_clientId').val(),
			secret = $('#google_secret').val();

		Meteor.call('configureGoogleOAuth', clientId, secret);
	}
});