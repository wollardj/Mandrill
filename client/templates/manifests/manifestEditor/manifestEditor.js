Template.manifestEditor.created = function() {

	Template.MandrillEditor.backLinkText = function() {
		return 'Manifests';
	};

	Template.MandrillEditor.backLinkTarget = function() {
		return Router.url('manifests');
	};

	Template.MandrillEditor.saveHook = function(docText) {
		var data = Router.current().data();
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
		return Router.current().data().path;
	};


	Template.MandrillEditor.documentTitle = function() {
		var settings = MandrillSettings.findOne();
		if (settings.munkiRepoPath) {
			return this.path.replace(settings.munkiRepoPath + 'manifests/', '');
		}
		else if (this.path) {
			return this.path;
		}
		return '??';
	};


	Template.MandrillEditor.deleteHook = function(_id, docText) {
		var data = Router.current().data();
		Meteor.call('unlinkManifest', data.path, function(err, data) {
			if (err) {
				Mandrill.show.error(err);
			}
		});
	};


	Template.MandrillEditor.documentBody = function() {
		var data = Router.current().data();
		return data.raw;
	};



	Meteor.startup( function () {
		Deps.autorun(function() {
			var data = MunkiManifests.findOne();
			Template.MandrillEditor.setDocumentBody(
				data && data.raw ? data.raw : '');
		});
	});
};