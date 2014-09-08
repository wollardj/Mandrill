plist = Meteor.npmRequire 'plist-native'
shell = Meteor.npmRequire 'shelljs'
shell.config.silent = true
shell.config.fatal = false

Meteor.methods {

	###
		Deletes the given file or directory, provided the user is permitted.
		`path` is expected to be absolute.
	###
	'unlink': (path)->
		Mandrill.user.canModifyPath this.userId, path, true
		if not path?
			throw new Meteor.Error 417, 'Expected a path to unlink.'

		repoPath = GitBroker.git().repoPath

		if GitBroker.gitIsEnabled() is true and
				/^\?\?/.test(GitBroker.status(path)[0]) is false

			GitBroker.remove path
			GitBroker.commit this.userId, path,
				'[Mandrill] Deleting file(s) at path "' +
				GitBroker.relativePathForFile(path) + '"'

		else
			shell.rm '-rf', path
			shell_rm_error = shell.error()

		# if the file still exists, let's make sure it gets put back into the
		# database, assuming it's been removed by some other code.
		if shell.test('-e', path)
			WatchHandler.processFile path
			throw new Meteor.Error 500, 'Failed to remove ' + path

		if shell_rm_error?
			throw new Meteor.Error 500, shell.error()



	###
		Atomically overwrites the file at path with the contents of body.
		If path doesn't exist, it will be created.
	###
	'filePutContents': (path, body, commitSubject='', commitBody='')->
		repoPath = GitBroker.git().repoPath

		Mandrill.user.canModifyPath this.userId, path, true

		if not path?
			throw new Meteor.Error 417, 'Expected a file path.'


		# write the file atomically
		atomic = shell.tempdir() + '/' + path.split('/').reverse()[0]
		body.to atomic
		if shell.error()?
			throw new Meteor.Error 500, shell.error()

		# If we use shell.mv() and the destination isn't writable,
		# shelljs will terminate the process. Not cool.
		# https://github.com/arturadib/shelljs/issues/64
		mvResults = shell.exec('/bin/mv -f ' +
			Mandrill.util.escapeShellArg(atomic) + ' ' +
			Mandrill.util.escapeShellArg(path)
		)

		if mvResults.code isnt 0
			throw new Meteor.Error 500, mvResults.output

		if GitBroker.gitIsEnabled() is true
			if /^\?\?/.test(GitBroker.status(path)[0]) is true
				GitBroker.add path
				commitSubject ?= 'Importing previously untracked file "' +
					GitBroker.relativePathForFile(path) + '"'
				GitBroker.commit this.userId, path, commitSubject, commitBody

			else
				commitSubject ?= '[Mandrill] Modified "' +
					GitBroker.relativePathForFile(path) + '"'
				GitBroker.commit this.userId, path, commitSubject, commitBody

		{
			atomicPath: atomic,
			realPath: path
		}


	'filePutContentsUsingObject': (path, obj, commitSubject='', commitBody='')->
		xml = plist.buildString obj
		Meteor.call 'filePutContents', path, xml, commitSubject, commitBody
}
