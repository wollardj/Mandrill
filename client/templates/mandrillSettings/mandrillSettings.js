Session.setDefault('runningMakeCatalogs', false);

Template.mandrillSettings.munkiRepoPathClass = function() {
	var settings = Router.current().data().settings;
	if (settings.munkiRepoPathIsValid === true) {
		return 'has-success';
	}
	else {
		return 'has-error';
	}
};


Template.mandrillSettings.makecatalogsIsChecked = function() {
	return this.settings.makeCatalogsIsEnabled === true ? 'checked' : '';
};


Template.mandrillSettings.makecatalogsDisableSanityIsChecked = function() {
	return this.settings.makeCatalogsSanityIsDisabled === true ? 'checked' : '';
};


Template.mandrillSettings.gitIsChecked = function() {
	return this.settings.gitIsEnabled === true ? 'checked' : ''
};


Template.mandrillSettings.munkiRepoPathFeedbackIcon = function() {
	var settings = Router.current().data().settings;
	if (settings.munkiRepoPathIsValid === true) {
		return 'ok';
	}
	else {
		return 'warning-sign';
	}
};


Template.mandrillSettings.runningMakeCatalogs = function() {
	return Session.get('runningMakeCatalogs');
};



Template.mandrillSettings.events({
	'change #gitIsEnabled': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var settings = MandrillSettings.findOne(),
			value = $('#gitIsEnabled').is(':checked');

		MandrillSettings.update({_id: settings._id},
		{
			'$set': {'gitIsEnabled': value}
		});

		if (value === true) {
			// initialize the repo if needed.
			Meteor.call('git-init');
		}
	},


	'change #gitBinaryPath': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var settings = MandrillSettings.findOne();

		MandrillSettings.update({_id: settings._id}, {
			'$set': {'gitBinaryPath': $('#gitBinaryPath').val()}
		});
	},

	'change #makeCatalogsIsEnabled': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var settings = MandrillSettings.findOne(),
			value = $('#makeCatalogsIsEnabled').is(':checked');

		MandrillSettings.update({_id: settings._id},
		{
			'$set': {'makeCatalogsIsEnabled': value}
		});

		if (value === true) {
			// initialize the repo if needed.
			Meteor.call('git-init');
		}
	},


	'change #makeCatalogsSanityIsDisabled': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var settings = MandrillSettings.findOne(),
			value = $('#makeCatalogsSanityIsDisabled').is(':checked');

		MandrillSettings.update({_id: settings._id},
		{
			'$set': {'makeCatalogsSanityIsDisabled': value}
		});

		if (value === true) {
			// initialize the repo if needed.
			Meteor.call('git-init');
		}
	},


	'change #munkiRepoPath': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var settings = MandrillSettings.findOne(),
			value = $('#munkiRepoPath').val();

		// Make sure the path has a trailing '/'
		if (/\/$/.test(value) === false) {
			value += '/';
			$('#munkiRepoPath').val(value);
		}

		MandrillSettings.update({_id: settings._id}, {
			'$set': {'munkiRepoPath': value}
		});

		Meteor.call('updateWatchr');
	},


	'click #makecatalogs': function(event) {
		event.stopPropagation();
		event.preventDefault();
		Session.set('runningMakeCatalogs', true);
		Meteor.call('runMakeCatalogs', function(err, data) {
			Session.set('runningMakeCatalogs', false);
			if (err) {
				Mandrill.show.error(err);
			}
		});
	},


	'click #rebuildCaches': function(event) {
		event.stopPropagation();
		event.preventDefault();
		var confirmMsg = 'During this process, all users will see zero ' +
			'manifests, pkgsinfo, and catalogs. Are you sure you want to do ' +
			'this right now?';
		if(confirm(confirmMsg) === true) {
			Meteor.call('updateWatchr', function(err, data) {
				if (err) {
					Mandrill.show.error(err);
				}
			});
		}
		$(event.target).blur();
	}
});