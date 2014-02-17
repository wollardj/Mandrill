var shell = Meteor.require('shelljs');
shell.config.silent = true;
shell.config.fatal = false;

Meteor.methods({

	// Atomically overwrites the file at path with the contents of body.
	// If path doesn't exist, it will be created.
	'filePutContents': function(path, body) {
		var mvResults,
			repoPath = GitBroker.git().repoPath,
			atomic;


		Mandrill.user.canModifyPath(this.userId, path, true);

		if (!path) {
			throw new Meteor.Error(417, 'Expected a file path.');
		}
		
		// try to update the record if possible.
		if (path.indexOf('/manifests/') >= 0) {
			MunkiManifests.upsert({'path': path}, {'$set': {'raw': body}});
		}
		else if (path.indexOf('/pkgsinfo/') >= 0) {
			MunkiPkgsinfo.upsert({'path': path}, {'$set': {'raw': body}});
		}


		// write the file atomically
		atomic = shell.tempdir() + '/' + path.split('/').reverse()[0];
		body.to(atomic);
		if (shell.error() !== null) {
			throw new Meteor.Error(500, shell.error());
		}

		// If we use shell.mv() and the destination isn't writable,
		// shelljs will terminate the process. Not cool.
		// https://github.com/arturadib/shelljs/issues/64
		mvResults = shell.exec('/bin/mv -f ' +
			Mandrill.util.escapeShellArg(atomic) + ' ' +
			Mandrill.util.escapeShellArg(path)
		);

		if (mvResults.code !== 0) {
			throw new Meteor.Error(500, mvResults.output);
		}

		if (GitBroker.gitIsEnabled() === true) {
			if (/^\?\?/.test(GitBroker.status(path)[0]) === true) {
				GitBroker.add(path);
				GitBroker.commit(this.userId, path,
					'[Mandrill] Importing previously untracked file "' +
					GitBroker.relativePathForFile(path) + '"');
			}
			else {
				GitBroker.commit(this.userId, path, '[Mandrill] Modified "' +
					GitBroker.relativePathForFile(path) + '"');
			}
		}

		return {
			atomicPath: atomic,
			realPath: path
		};
	}
});