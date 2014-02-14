GitBroker = {

	'authorString': Meteor.bindEnvironment(function(userId) {
		var account = Meteor.users.findOne(userId);
		if (userId && account && account.profile && account.emails) {
			return account.profile.name + ' <' + account.emails[0].address +
				'>';
		}
		else {
			throw new Meteor.Error(403, 'Could not determine who is logged ' +
				'in. Blocking commit request.');
		}

	}, function(e) {
		throw e;
	}),



	'relativePathForFile': Meteor.bindEnvironment(function(aFile) {
		var settings = MandrillSettings.findOne();
		if (settings.munkiRepoPath) {
			return aFile.replace(settings.munkiRepoPath, '');
		}
		return aFile;
	}, function(e) {
		throw e;
	}),



	'init': Meteor.bindEnvironment(function() {
		var git = GitBroker.git();
		if (git.repoIsInitialized() === false) {
			git.init();
			GitBroker.add('pkgsinfo');
			GitBroker.add('manifests');
			GitBroker.commit('pkgsinfo', '[Mandrill] Initial commit of pkgsinfo');
			GitBroker.commit('manifests', '[Mandrill] Initial commit of manifests');
		}
		return git.repoIsInitialized();
	}),



	'gitIsEnabled': Meteor.bindEnvironment(function() {
		var settings = MandrillSettings.findOne();
		return settings.gitIsEnabled && settings.gitIsEnabled === true;
	}, function(e) {
		throw e;
	}),



	'git': Meteor.bindEnvironment(function() {
		var settings = MandrillSettings.findOne();
		return new Git(settings.munkiRepoPath, settings.gitBinaryPath);

	}, function(e) {
		throw e;
	}),



	'add': Meteor.bindEnvironment(function(path) {
		return GitBroker.git().exec('add', path);
	}, function(e) {
		throw e;
	}),



	'remove': Meteor.bindEnvironment(function(path) {
		return GitBroker.git().exec('rm', '-f', path);
	}, function(e) {
		throw e;
	}),



	'status': Meteor.bindEnvironment(function(path) {
		var results = GitBroker.git().exec('status', path, '-z'),
			codes = [];
		for(var i = 0; i < results.output.length; i++) {
			codes.push(results.output[i].trim());
		}
		return codes;
	}, function(e) {
		throw e;
	}),


	'log': Meteor.bindEnvironment(function(path) {
		var results = GitBroker.git().exec('log', '-z',
			'--pretty=%H%x1F%h%x1F%aN%x1F%ae%x1F%s%x1F%b%x1F%aD',
			path),
			logs = [],
			fields;

		if (results.code !== 0) {
			throw new Meteor.Error(results.code, 'Unable to retrieve logs for \'' + path + '\'.');
		}

		for(var i = 0; i < results.output.length; i++) {
			fields = results.output[i].split(String.fromCharCode(31));
			logs.push({
				'longHash': fields[0],
				'hash': fields[1],
				'authorName': fields[2],
				'authorEmail': fields[3],
				'subject': fields[4],
				'body': fields[5],
				'authorDate': new Date(fields[6]) // RFC2822 formatted date
			});
		}
		return logs;
	}, function(e) {
		throw e;
	}),



	'commit': Meteor.bindEnvironment(function(committerId, path, subject, body) {

		var git = GitBroker.git(),
			results,
			commitArgs = [
				'commit',
				'--author', GitBroker.authorString(committerId),
				'-m', (subject || ''),
				'-m', (body || ''),
				path
			];

		results = git.exec.apply(git, commitArgs);

		if (results.code !== 0) {
			// For whatever reason, it seems git needs to have a user.name and
			// user.email configured within a project or globally before it will
			// allow us to override it with --author=<author>
			git.exec('config', 'user.name', 'Mandrill');
			git.exec('config', 'user.email', 'noreply@localhost.com');
			results = git.exec.apply(git, commitArgs);
		}

		return results;

	}, function(e) {
		throw e;
	}),
};