Template.manifestEditor.created = function() {

	Template.MandrillEditor.backLinkText = function() {
		return 'Manifests';
	};

	Template.MandrillEditor.backLinkTarget = function() {
		return Router.url('manifests');
	};

	Template.MandrillEditor.saveHook = function(docText) {
		var data = Router.current().getData();
		Session.set('workingOnDocument', true);
		Meteor.call(
			'filePutContents',
			data.path, docText, function(err) {
				Session.set('workingOnDocument', false);
				if (err) {
					Mandrill.show.error(err);
				}
			}
		);
	};


	Template.MandrillEditor.documentPath = function() {
		return Router.current().getData().path;
	};


	Template.MandrillEditor.documentTitle = function() {
		var settings = MandrillSettings.findOne(),
			data = Router.current().getData();
		if (!settings.munkiRepoPath) {
			return this.path;
		}

		if (data.path) {
			return data.path.replace(settings.munkiRepoPath + 'manifests/', '');
		}
		return '??';
	};


	Template.MandrillEditor.deleteHook = function(_id, docText) {
		var data = Router.current().getData();
		Meteor.call('unlinkManifest', data.path, function(err, data) {
			if (err) {
				Mandrill.show.error(err);
			}
		});
	};


	Template.MandrillEditor.documentBody = function() {
		var data = Router.current().getData();
		return data.raw;
	};
};