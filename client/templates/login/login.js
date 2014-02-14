Template.login.events({
	'submit form': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var username = $('#login_username').val(),
			password = $('#login_password').val();

		$('#login_password').val('');
		Meteor.loginWithPassword(username, password, function(err) {
			if (err) {Mandrill.show.error(err);}
		});
	},


	'click #login-with-google': function() {
		Meteor.loginWithGoogle(null, function(err) {
			if (err) {Mandrill.show.error(err);}
		});
	},

	'click #login-with-github': function() {
		Meteor.loginWithGithub(null, function(err) {
			if (err) {Mandrill.show.error(err);}
		});
	}
});