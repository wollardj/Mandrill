Template.me.created = function() {
	Session.setDefault('changePasswordFormIsReady', false);
	Session.setDefault('changingPassword', false);
};


Template.me.destroyed = function() {
	Session.set('changePasswordFormIsReady', null);
	Session.set('changingPassword', null);
};


Template.me.formIsDisabled = function() {
	return Session.get('changePasswordFormIsReady') !== true ? 'disabled' : '';
};


Template.me.changingPassword = function() {
	return Session.get('changingPassword');
};



Template.me.events({



	/// ---- password change form ---- ///
	'submit #changePasswordForm': function(event) {
		event.stopPropagation();
		event.preventDefault();
		if (Session.get('changePasswordFormIsReady') === true) {
			Session.set('changingPassword', true);

			var currentField    = $('#currentPassword'),
				newField        = $('#newPassword'),
				verifyField     = $('#verifyPassword');

			
			Accounts.changePassword(
				currentField.val(),
				newField.val(),
				function(err) {
					Session.set('changingPassword', false);
					if (err) {
						Mandrill.show.error(err);
						return;
					}
					Mandrill.show.success(
						'',
						'Password Successfully Changed!'
					);
				}
			);

			currentField.val('');
			newField.val('');
			verifyField.val('');
			currentField.focus();
		}
	},


	'keyup #currentPassword, keyup #newPassword, keyup #verifyPassword':
	function() {
		var currentField    = $('#currentPassword'),
			newField        = $('#newPassword'),
			verifyField     = $('#verifyPassword'),
			currentIsEmpty = currentField.val() === '',
			newIsEmpty     = newField.val() === '',
			passwordsMatch  = newField.val() === verifyField.val(),
			formIsReady    = newIsEmpty === false &&
								currentIsEmpty === false &&
								passwordsMatch === true;

		Session.set('changePasswordFormIsReady', formIsReady);
	},





	/// ---- Name change form ---- ///


	'change #changeFullName': function(event) {
		Meteor.users.update(
			{_id: Meteor.userId()},
			{'$set': {
				'profile.name': $(event.target).val()
			}}
		);
	}
});