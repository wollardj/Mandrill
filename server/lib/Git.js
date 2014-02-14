var shell = Meteor.require('shelljs');

// prevent shelljs from echoing the output of each command
// to the server console.
shell.config.silent = true;


/*
	Provides some basic interactions with git.
 */

Git = function(aRepo, gitPath) {
	this.gitCmd = gitPath || shell.which('git');
	this.repo = aRepo;
};


Git.prototype._cmd = null;
Git.prototype.repo = null;



/*
	Pass as many or as few arguments as needed. They'll be escaped
	and passed along to git, otherwise unmodified.
 */
Git.prototype.exec = function() {
	var cmd = this.gitCmd,
		parseOnNull = false,
		result;

	if (!this.repo) {
		throw new Meteor.Error('Git.repo must be set to a repo path');
	}

	for(var i = 0; i < arguments.length; i++) {
		if (parseOnNull === false && arguments[i] === '-z') {
			parseOnNull = true;
		}
		cmd += ' ' + Mandrill.util.escapeShellArg(arguments[i]);
	}

	console.log(cmd);

	shell.pushd(this.repo);
	result = shell.exec(cmd);
	shell.popd();
	// The '-z' operator means the caller wanted the lines of the output
	// denoted by the null character, which means they want to parse it.
	// Let's help them out a bit by splitting on null characters.
	if (parseOnNull === true) {
		result.output = result.output.split(String.fromCharCode(0));
		if (result.output.reverse()[0] === '') {
			result.output.reverse().pop();
		}
	}
	return result;
};




/*
	Initializes a git repo at the path provided to the constructor.
	Example:
	var git = new Git('/some/path');
	git.init();
*/
Git.prototype.init = function() {
	var result = this.exec('init');
	return result.code === 0;
};




/*
	Determines if the path given to Git's constructor represents a
	valid repo. If it is valid, this returns true; false if not.
*/
Git.prototype.repoIsInitialized = function() {
	var result = this.exec('status');
	return result.code !== 128;
};