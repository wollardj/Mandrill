var plist = Meteor.require('plist-native'),
	shell = Meteor.require('shelljs');

shell.config.silent = true;
shell.config.fatal = false;

Meteor.methods({
	'createManifest': function(manifestPath) {
		var repoPath = GitBroker.git().repo,
			relativePath = manifestPath.replace(repoPath, ''),
			record = {
				path: manifestPath,
				dom: {
					'catalogs': [],
					'conditional_items': [],
					'managed_installs': [],
					'managed_uninstalls': [],
					'managed_updates': [],
					'optional_installs': []
				}
			};


		Mandrill.user.canModifyPath(this.userId, record.path, true);

		if (shell.test('-e', record.path)) {
			throw new Meteor.Error(403,
				'A file already exists with that name');
		}

		shell.mkdir('-p', record.path.replace(/\/[^/]*$/, ''));
		if (shell.error() !== null) {
			throw new Meteor.Error(500, shell.error());
		}

		record.raw = plist.buildString(record.dom);
		record.raw.to(record.path);

		if (shell.error() !== null) {
			throw new Meteor.Error(500, shell.error());
		}

		record.urlName = record.path
			.replace(repoPath + 'manifests/', '')
			.replace(/\//g, '_');
		
		MunkiManifests.insert(record);
		if (GitBroker.gitIsEnabled() === true) {
			GitBroker.add(relativePath);
			GitBroker.commit(this.userId, relativePath, '[Mandrill] Added "' +
				relativePath + '"');
		}

		return record;
	},




	/*
		Deletes the named manifest (path relative to the manifests dir).
	 */
	'unlinkManifest': function(manifestPath) {

		Mandrill.user.canModifyPath(this.userId, manifestPath, true);

		var gitResults,
			repo = GitBroker.git().repo,
			relativePath = manifestPath.replace(repo, '');

		if (GitBroker.gitIsEnabled() === true) {
			gitResults = GitBroker.remove(relativePath);

			if (gitResults.code === 0) {
				GitBroker.commit(this.userId, relativePath, '[Mandrill] Removed "' +
					relativePath + '"');
				MunkiManifests.remove({path: manifestPath});
			}
			else {
				throw new Meteor.Error(gitResults.code, gitResults.output);
			}
		}
		else {
			shell.rm(manifestPath);
			if (shell.error() !== null) {
				throw new Meteor.Error(500, shell.error());
			}
			MunkiManifests.remove({path: manifestPath});
		}
	}
});