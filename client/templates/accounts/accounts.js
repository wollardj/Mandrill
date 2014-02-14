Template.accounts.rendered = function () {
	Mandrill.tpl.activateTooltips();
};


Template.accounts.emailAddresses = function() {
	var emails = [];
	for(var i = 0; i < this.emails.length; i++) {
		emails.push(this.emails[i].address);
	}
	return emails.join(', ');
};



Template.accounts.accessPatternsCount = function() {
	var patt = this.mandrill.accessPatterns || [];
	return patt.length + ' rule' + (patt.length !== 1 ? 's' : '');
};



Template.accounts.isLoggedIn = function () {
	return this.services && this.services.resume &&
		this.services.resume.loginTokens &&
		this.services.resume.loginTokens.length > 0;
};


Template.accounts.isBanned = function () {
	return this.mandrill.isBanned;
};



Template.accounts.isCurrentUser = function() {
	return Meteor.userId() === this._id;
};



Template.accounts.loginServicesIcons = function() {
	var icons = '',
		name = this.profile && this.profile.name ?
			this.profile.name :
			this.username;

	icons += '<i data-toggle="tooltip" title="' + name +
		' has a local account" class="glyphicon glyphicon-user"></i>';

	if (this.services && this.services.google) {
		icons += ' <img data-toggle="tooltip" title="' + name +
			' has logged in using Google" height="15px" ' +
			'style="margin-bottom: 6px" src="' +
			'https://www.google.com/favicon.ico" />';
	}

	if (this.services && this.services.github) {
		icons += ' <img data-toggle="tooltip" title="' + name +
			' has logged in using Github" height="15px" ' +
			'style="margin-bottom: 6px" ' +
			'src="http://www.github.com/favicon.ico" />';
	}

	if (icons.length > 0) {
		return new Handlebars.SafeString(icons);
	}
};




Template.accounts.events({



	/// ---- editing emails ---- ///
	'click td.edit-email': function(event) {
		var target = $(event.target),
			span,
			textarea;

		while(target && target.prop('tagName') !== 'TD') {
			target = $(target.parent());
		}

		span = target.find('span');
		textarea = target.find('textarea');

		span.addClass('hidden');
		textarea.removeClass('hidden');
		textarea.focus();
	},


	'blur textarea': function(event) {
		var target = $(event.target),
			span,
			textarea,
			record = this,
			cleanedEmails = [];

		while(target && target.prop('tagName') !== 'TD') {
			target = $(target.parent());
		}
		
		span = target.find('span');
		textarea = target.find('textarea');

		// Clean up the email list.
		_.each(textarea.val().split(/[, ]/g), function(email) {
			email = email.replace(/\s/g, '');
			if (email.search(/^[^@]*@[^@]*$/) === 0) {
				// We should be preserving the verified state, but
				// it' not quite as important to Mandrill as it would be
				// to a public-facing social media site. Plust there's no
				// UI mechanism for sending verification emails yet.
				cleanedEmails.push({address: email, verified: false});
			}
		});


		// Commit the new email list back to the database.
		Meteor.users.update({_id: this._id}, {'$set':{
			'emails': cleanedEmails
		}});

		function _emailAddressExists(service, emails) {
			var found = false;
			for(var i = 0; i < emails.length; i++) {
				if (service.email === emails[i].email) {
					found = true;
					break;
				}
			}
			return found;
		}
		
		// Look for orphaned service accounts and remove them.
		for(var service in this.services) {
			if (this.services.hasOwnProperty(service)) {
				if (service === 'password' || service === 'resume') {
					continue;
				}

				var path = 'services.' + service,
					obj = this.services[service],
					found = _emailAddressExists(obj, cleanedEmails);

				if (found === false) {
					obj = {'$unset':{}};
					obj.$unset[path] = '';
					Meteor.users.update({_id: record._id}, obj);
				}
			}
		}

		// Reset the page
		textarea.addClass('hidden');
		span.removeClass('hidden');
	},




	/// ---- managing user state ---- ///




	'click a.glyphicon-trash': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var answer = confirm('Are you sure you want to delete ' +
			(this.profile && this.profile.name ?
				this.profile.name :
				'this account') + '?');
		if (answer === true) {
			Meteor.users.remove({_id: this._id});
		}
	},


	'click a.logout': function(event) {
		event.stopPropagation();
		event.preventDefault();
		var username = this.username;
		Meteor.call('logoutUserWithId', this._id, function(err) {
			if (err) {
				Mandrill.show.error(err);
				return;
			}

			Mandrill.show.success(
				'Logout Successful',
				username + ' has been logged out of all browser sessions.'
			);
		});
	},


	//
	// Ban the selected user as long as it's not the current admin.
	//
	'click a.ban-user': function() {
		if (Meteor.userId() === this._id) {
			return;
		}
		if (this.mandrill.isBanned) {
			Meteor.users.update({_id: this._id}, {'$set':
				{'mandrill.isBanned': false}
			});
		}
		else {
			Meteor.users.update({_id: this._id}, {'$set':
				{'mandrill.isBanned': true}
			});
		}
	},


	'click a.reset-password': function(event) {
		event.stopPropagation();
		event.preventDefault();
		var username = this.username;

		Meteor.call(
			'resetLocalPasswordForUserId',
			this._id,
			function(err, data) {
				if (err) {
					Mandrill.show.error(err);
					return;
				}
				Mandrill.show.success(
					'Password reset for "' + username + '"',
					'The new password is <code>' + data.result + '</code>'
				);
			}
		);
	},


	//
	// Inverts the selected accounts admin status, as long as it's not
	// the account of the current admin.
	//
	'click button[data-toggle-admin]': function(event) {
		event.stopPropagation();
		event.preventDefault();
		
		if (Meteor.userId() === this._id) {
			return;
		}

		if (this.mandrill.isAdmin === true) {
			Meteor.users.update({_id: this._id}, {'$set':
				{'mandrill.isAdmin': false}
			});
		}
		else {
			Meteor.users.update({_id: this._id}, {'$set':
				{'mandrill.isAdmin': true}
			});
		}
	},


	//
	// Re-routes the admin to /accounts/access/<user-id>
	//
	'click button[data-show-access]': function(event) {
		event.stopPropagation();
		event.preventDefault();
		Router.go('accounts-access', {_id: this._id});
	},



	/// ---- adding a new account ---- ///


	'submit form': function(event) {
		event.stopPropagation();
		event.preventDefault();
		var email = $('#new_email').val().toLowerCase(),
			username = email.replace(/@.*$/, '');

		$('#new_email').val('');

		Meteor.call(
			'createLocalAccount',
			username,
			email,
			function(error, data) {
				if (error) {
					Mandrill.show.error(error);
					return;
				}
				Mandrill.show.success(
					'Account Created',
					'The password for this account is <code>' + data +
					'</code>'
				);
			}
		);
	}
});