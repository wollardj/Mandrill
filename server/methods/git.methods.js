Meteor.methods({
	// initializes the munkiRepoPath as a git repository, but only
	// if it's not already a valid git repo.
	'git-init': function() {
		if (Mandrill.user.isAdmin(this.userId) === true) {
			if (GitBroker.gitIsEnabled() === true) {
				GitBroker.init();
			}
		}
	},


	'git-log': function(aFile) {
		if (Mandrill.user.isValid(this.userId) === true) {
			if (GitBroker.gitIsEnabled() === true) {
				return GitBroker.log(aFile);
			}
		}
		return [];
	}
})