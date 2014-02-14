Template['accounts-access'].rendered = function() {
	Mandrill.tpl.activateTooltips();
};


Template['accounts-access'].munkiRepoPath = function() {
	var settings = MandrillSettings.findOne();

	if (settings && settings.munkiRepoPath) {
		return settings.munkiRepoPath;
	}
	return '';
};



Template['accounts-access'].events({

	// Add a new pattern, as long as it's not empty
	'submit form': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var $pattField = $('input[data-new-access-rule]'),
			$roField = $('input[data-new-access-readonly]'),
			patt = $pattField.val(),
			data = Router.current().getData().user;

		if (patt === '') {
			return;
		}

		Meteor.users.update(data._id, {'$addToSet':
			{
				'mandrill.accessPatterns': {
					pattern: patt,
					readonly: $roField.is(':checked')
				}
			}
		});

		// reset the form
		$pattField.val('');
		$pattField.focus();
		$roField.attr('checked', false);
	},


	'change input[data-toggle-readonly]': function(event) {
		var $tgt = $(event.target),
			val = $tgt.is(':checked'),
			data = Router.current().getData().user,
			existingPatterns = data.mandrill.accessPatterns;

		for(var i = 0; i < existingPatterns.length; i++) {
			if (existingPatterns[i].pattern === this.pattern) {
				existingPatterns[i].readonly = val;
				break;
			}
		}
		Meteor.users.update(data._id,{'$unset':
			{'mandrill.accessPatterns': ''}
		});
		Meteor.users.update(data._id, {'$set':
			{'mandrill.accessPatterns': existingPatterns}
		});
	},



	'change input[data-access-pattern]': function(event) {
		var $tgt = $(event.target),
			pattNew = $tgt.val(),
			data = Router.current().getData().user,
			existingPatterns = data.mandrill.accessPatterns;

		while (pattNew[0] === '/' && pattNew.length > 0) {
			pattNew = pattNew.substring(1);
		}

		$tgt.val(pattNew);

		for(var i = 0; i < existingPatterns.length; i++) {
			if (existingPatterns[i].pattern === this.pattern) {
				existingPatterns[i].pattern = pattNew;
				break;
			}
		}

		Meteor.users.update(data._id, {'$unset':
			{'mandrill.accessPatterns': ''}
		});
		Meteor.users.update(data._id, {'$set':
			{'mandrill.accessPatterns': existingPatterns}
		});
	},



	'click button[data-remove-pattern]': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var data = Router.current().getData().user;

		Meteor.users.update(data._id, {'$pull':
			{
				'mandrill.accessPatterns':
				{
					pattern: this.pattern,
					readonly: this.readonly
				}
			}
		});
	}
});