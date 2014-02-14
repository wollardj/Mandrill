Template.gitLogs.created = function() {
	GitLogs.remove({});
	Meteor.call('git-log',
		Template.MandrillEditor.documentPath(),
		function(err, data) {
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