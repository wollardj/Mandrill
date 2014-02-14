Template.loginServicesGithub.clientId = function () {
	var data = Accounts.loginServiceConfiguration.findOne(
		{service: 'github'}
	);
	if (data) {
		return data.clientId;
	}
	return '';
};



Template.loginServicesGithub.events({
	'click #purge-github': function() {
		var really = confirm('You will no longer be able to use GitHub ' +
			'to authenticate to Mandrill. Are you sure?');
		if (really === true) {
			Meteor.call(
				'purgeLoginServiceConfiguration',
				'github',
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
		var clientId = $('#github_clientId').val(),
			secret = $('#github_secret').val();

		Meteor.call('configureGithubOAuth', clientId, secret);
	}
});