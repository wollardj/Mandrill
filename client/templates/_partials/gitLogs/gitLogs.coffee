Template.gitLogs.loadLogs = ->
	doc = Session.get 'activeDocument'
	if doc? and doc.path? and doc.path isnt ''
		Meteor.call 'git-log', doc.path, (err, data)->
			GitLogs.remove {}
			Session.set 'loadingGitLogs', false
			if err?
				Mandrill.show.error err

			else
				GitLogs.insert log for log in data


Template.gitLogs.filePath = ->
	doc Session.get 'activeDocument'
	if doc? and doc.path?
		doc.path
	else
		''


Template.gitLogs.gitLogs = ->
	GitLogs.find().fetch()


Template.gitLogs.numberOfLogs = ->
	GitLogs.find().count()