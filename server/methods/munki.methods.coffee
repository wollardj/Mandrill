shell = Meteor.require 'shelljs'
Meteor.methods {
	'runMakeCatalogs': ->
		settings = MandrillSettings.findOne()

		if settings.makeCatalogsIsEnabled is true or Mandrill.user.isAdmin(this.userId) is true

			# @TODO This information should be logged and made available to
			# the end user, not just simply returned.
			if shell.test('-f', '/usr/local/munki/makecatalogs') is false
				throw new Meteor.Error 500, '/usr/local/munki/makecatalogs is missing!'

			try
				force = if settings.makeCatalogsSanityIsDisabled is true then '-f ' else ''
				result = shell.exec(
					'/usr/local/munki/makecatalogs ' + force +
					Mandrill.util.escapeShellArg(settings.munkiRepoPath)
				)

			catch e
				throw new Meteor.Error 500, 'Failed to execute makecatalogs for some reason.'

			result.output.split '\n'
		
		else
			throw new Meteor.Error( 403,
				'You do not have permission to run makecatalogs.'
			)
}