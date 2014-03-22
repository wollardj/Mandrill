Meteor.methods {
	# initializes the munkiRepoPath as a git repository, but only
	# if it's not already a valid git repo.
	'git-init': ->
		if Mandrill.user.isAdmin(this.userId) is true
			if GitBroker.gitIsEnabled() is true
				GitBroker.init()


	'git-log': (aFile)->
		if Mandrill.user.isValid(this.userId) is true
			if GitBroker.gitIsEnabled() is true
				GitBroker.log aFile
			else
				[]
		else
			[]
}