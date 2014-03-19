Template.gitLogs.loadLogsForPath = (aPath)->
	if aPath?
		Meteor.call 'git-log', aPath, (err, data)->
			GitLogs.remove {}
			Session.set 'loadingGitLogs', false
			if err?
				Mandrill.show.error err

			else
				GitLogs.insert log for log in data


Template.gitLogs.gitLogs = ->
	GitLogs.find().fetch()


Template.gitLogs.numberOfLogs = ->
	return GitLogs.find().count()