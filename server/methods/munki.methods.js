var shell = Meteor.require('shelljs');
Meteor.methods({
	'runMakeCatalogs': function() {
		var settings = MandrillSettings.findOne(),
			result;
		if (settings.makeCatalogsIsEnabled === true ||
			Mandrill.user.isAdmin(this.userId)) {

			// @TODO This information should be logged and made available to
			// the end user, not just simply returned.
			if (shell.test('-f', '/usr/local/munki/makecatalogs') === false) {
				throw new Meteor.Error(500, '/usr/local/munki/makecatalogs is missing!');
			}
			try {
			result = shell.exec(
				'/usr/local/munki/makecatalogs ' +
				(settings.makeCatalogsSanityIsDisabled === true ? '-f ' : '') +
				Mandrill.util.escapeShellArg(settings.munkiRepoPath)
			);
			}
			catch (e) {
				throw new Meteor.Error(500, 'Failed to execute makecatalogs for some reason.');
			}

			return result.output.split('\n');
		}
		else {
			throw new Meteor.Error(
				403,
				'You do not have permission to run makecatalogs.'
			);
		}
	}
})
