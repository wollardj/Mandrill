class @GitBroker

	@authorString: Meteor.bindEnvironment (userId)->
		account = Meteor.users.findOne userId
		if userId? and account? and account.profile? and account.emails?
			account.profile.name + ' <' + account.emails[0].address + '>'
		
		else
			throw new Meteor.Error 403, 'Could not determine who is logged ' +
				'in. Blocking commit request.'

	, (e)->
		throw e



	@relativePathForFile: Meteor.bindEnvironment (aFile)->
		settings = MandrillSettings.findOne()
		if settings? and settings.munkiRepoPath?
			aFile.replace settings.munkiRepoPath, ''
		else
			aFile
	, (e)->
		throw e



	@init: Meteor.bindEnvironment ->
		git = GitBroker.git()
		if git.repoIsInitialized() is false
			git.init()
			GitBroker.add 'pkgsinfo'
			GitBroker.add 'manifests'
			GitBroker.git().exec 'commit', '-a', '-m', '[Mandrill] - Initial commit'
		git.repoIsInitialized()
	, (e)->
		throw e;



	@gitIsEnabled: Meteor.bindEnvironment ->
		settings = MandrillSettings.findOne()
		settings? and settings.gitIsEnabled? and settings.gitIsEnabled is true
	, (e)->
		throw e



	@git: Meteor.bindEnvironment ->
		settings = MandrillSettings.findOne()
		new Git settings.munkiRepoPath, settings.gitBinaryPath
	, (e)->
		throw e



	@add: Meteor.bindEnvironment (path)->
		GitBroker.git().exec 'add', path
	, (e)->
		throw e



	@remove: Meteor.bindEnvironment (path)->
		GitBroker.git().exec 'rm', '-f', path
	, (e)->
		throw e



	@status: Meteor.bindEnvironment (path)->
		results = GitBroker.git().exec 'status', path, '-z'
		codes = []
		for line in results.output
			codes.push line.trim()

		codes
	, (e)->
		throw e


	@log: Meteor.bindEnvironment (path)->
		fmt = '--pretty=%H%x1F%h%x1F%aN%x1F%ae%x1F%s%x1F%b%x1F%aD'
		results = GitBroker.git().exec 'log', '-z', fmt, path
		logs = []
		
		if results.code isnt 0
			throw new Meteor.Error results.code, 'Unable to retrieve logs for \'' + path + '\'.'

		for line in results.output
			fields = line.split String.fromCharCode(31)
			logs.push {
				'longHash': fields[0]
				'hash': fields[1]
				'authorName': fields[2]
				'authorEmail': fields[3]
				'subject': fields[4]
				'body': fields[5]
				'authorDate': new Date(fields[6]) # RFC2822 formatted date
			}
		logs
	, (e)->
		throw e



	@commit: Meteor.bindEnvironment (committerId, path, subject, body)->

		git = GitBroker.git()
		commitArgs = [
			'commit'
			'--author', GitBroker.authorString committerId
			'-m', (subject or '')
			'-m', (body or '')
			path
		]

		results = git.exec.apply git, commitArgs

		if results.code isnt 0
			# For whatever reason, it seems git needs to have a user.name and
			# user.email configured within a project or globally before it will
			# allow us to override it with --author=<author>
			git.exec 'config', 'user.name', 'Mandrill'
			git.exec 'config', 'user.email', 'noreply@localhost.com'
			results = git.exec.apply git, commitArgs

		results

	, (e)->
		throw e