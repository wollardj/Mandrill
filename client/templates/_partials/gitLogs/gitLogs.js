Template.gitLogs.loadLogsForPath = function(aPath) {
	if (!aPath) {
		return;
	}

	Meteor.call('git-log',
		aPath,
		function(err, data) {
			GitLogs.remove({});
			Session.set('loadingGitLogs', false);
			if (err) {
				Mandrill.show.error(err);
			}
			else {
				for(var i = 0; i < data.length; i++) {
					GitLogs.insert(data[i]);
				}
			}
		}
	);	
};


Template.gitLogs.gitLogs = function() {
	return GitLogs.find().fetch();
};


Template.gitLogs.numberOfLogs = function() {
	return GitLogs.find().count();
};