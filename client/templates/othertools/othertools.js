Template.othertools.rendered = function () {
	Mandrill.tpl.activateTooltips();
};




Template.othertools.events({
	'submit form': function(event) {
		event.stopPropagation();
		event.preventDefault();
		
		var $displayTextField = $('#displayText'),
			$linkUrlField = $('#linkUrl'),
			displayText = $displayTextField.val(),
			linkUrl = $linkUrlField.val(),
			obj = {displayText: displayText, linkUrl: linkUrl};

		if (displayText === '' || linkUrl === '') {
			return;
		}

		if (this._id) {
			OtherTools.update({_id: this._id}, {$set: obj});
		}
		else {
			OtherTools.insert(obj);

			// Let's go ahead and reset the fields.
			$displayTextField.val('');
			$linkUrlField.val('');
			$displayTextField.focus();
		}
	},


	'click button.delete-link': function(event) {
		event.stopPropagation();
		event.preventDefault();

		if (this._id) {
			OtherTools.remove(this._id);
		}
		else {
			alert('I can\'t delete that.');
		}
	},


	'click td.edit-display-text, click td.edit-link-url': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var target = $(event.target);
		while (target && target.prop('tagName') !== 'TD') {
			target = $(target.parent());
		}

		target.find('span').addClass('hidden');
		target.find('input').removeClass('hidden');
		target.find('input').focus();
	},


	'blur input.edit-display-text-field, blur input.edit-link-url-field':
	function(event) {
		event.stopPropagation();
		event.preventDefault();

		var target = $(event.target),
			linkOrText = target.hasClass('edit-display-text-field') ?
				'text' :
				'link';
		while (target && target.prop('tagName') !== 'TD') {
			target = $(target.parent());
		}

		target.find('span').removeClass('hidden');
		target.find('input').addClass('hidden');

		if (linkOrText === 'text') {
			OtherTools.update(this._id, {'$set':
				{displayText: target.find('input').val()}
			});
		}
		else {
			OtherTools.update(this._id, {'$set':
				{linkUrl: target.find('input').val()}
			});
		}
	}
});