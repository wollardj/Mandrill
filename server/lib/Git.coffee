shell = Meteor.npmRequire 'shelljs'

# prevent shelljs from echoing the output of each command
# to the server console.
shell.config.silent = true


#
#	Provides some basic interactions with git.
#

class @Git
	constructor: (@repo, gitPath)->
		@gitCmd = gitPath or shell.which('git')


	#
	#	Pass as many or as few arguments as needed. They'll be escaped
	#	and passed along to git, otherwise unmodified.
	#
	exec: ->
		cmd = @gitCmd
		parseOnNull = false

		if not this.repo?
			throw new Meteor.Error 'Git.repo must be set to a repo path'

		for own key, arg of arguments
			if parseOnNull is false and arg is '-z'
				parseOnNull = true
			cmd += ' ' + Mandrill.util.escapeShellArg arg

		console.log cmd

		shell.pushd this.repo
		result = shell.exec cmd
		shell.popd()
		# The '-z' operator means the caller wanted the lines of the output
		# denoted by the null character, which means they want to parse it.
		# Let's help them out a bit by splitting on null characters.
		if parseOnNull is true
			result.output = result.output.split String.fromCharCode(0)
			if result.output.reverse()[0] is ''
				result.output.reverse().pop()

		result



	#
	#	Initializes a git repo at the path provided to the constructor.
	#	Example:
	#	var git = new Git('/some/path');
	#	git.init();
	#
	init: ->
		result = this.exec('init')
		result.code is 0




	#
	#	Determines if the path given to Git's constructor represents a
	#	valid repo. If it is valid, this returns true; false if not.
	#
	repoIsInitialized: ()->
		result = this.exec('status');
		result.code isnt 128
