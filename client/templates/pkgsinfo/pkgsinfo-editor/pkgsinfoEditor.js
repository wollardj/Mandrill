Template.MandrillEditor.backLinkTarget = function() {
	return Router.url('pkgsinfo');
};

Template.MandrillEditor.saveHook = function(docText) {
	Session.set('workingOnDocument', true);
	var data = Router.current().getData();
	Meteor.call('filePutContents', data.path, docText, function(err) {
		Session.set('workingOnDocument', false);
		if (err) {
			Mandrill.show.error(err);
		}
	});
};

Template.MandrillEditor.deleteHook = function() {
	var data = Router.current().getData();
	// First, we'll find out if the pkgsinfo file refers to an
	// installer_item_location. If it does, we'll ask the user if that
	// file should be removed as well before deleting the plist.
	Meteor.call('pkginfoHasInstallerItem', data.urlName,
		function(err, hasInstallerItem) {
			if (err) {
				Mandrill.show.error(err);
			}
			else {
				if (hasInstallerItem === true) {
					hasInstallerItem = confirm(
						'Do you want to delete the corresponding installer ' +
						'item as well? Files in pkgs/ are not tracked, ' +
						'which means you cannot undo this action.'
					);
				}
				Meteor.call('unlinkPkginfo', data.path, hasInstallerItem,
					function(err, data) {
						if (err) {
							Mandrill.show.error(err);
						}
					}
				);
			}
		}
	);
};


Template.MandrillEditor.documentPath = function() {
	return Router.current().getData().path;
};

Template.MandrillEditor.documentTitle = function() {
	var settings = MandrillSettings.findOne();
	if (settings.munkiRepoPath) {
		return this.path.replace(settings.munkiRepoPath + 'pkgsinfo/', '');
	}
	else if (this.path) {
		return this.path;
	}
	return '??';
};


Template.MandrillEditor.documentBody = function() {
	return Router.current().getData().raw;
};



Meteor.startup( function () {
	Deps.autorun(function() {
		var data = MunkiPkgsinfo.findOne();
		Template.MandrillEditor.setDocumentBody(
			data && data.raw ? data.raw : '');
	});
});