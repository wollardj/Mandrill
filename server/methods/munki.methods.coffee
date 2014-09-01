shell = Meteor.npmRequire 'shelljs'
plist = Meteor.npmRequire 'plist-native'


Meteor.methods {
	'getRawRepoItemContent': (_id)->
		item = MunkiRepo.findOne({_id: _id})
		if item? and item.raw? and item.stat.size > 0
			item.raw
		else
			false


	'runMakeCatalogs': ->
		repoPath = MandrillSettings.get 'munkiRepoPath', ''
		insane = MandrillSettings.get 'makeCatalogsSanityIsDisabled', false
		partyMode = MandrillSettings.get 'makeCatalogsIsEnabled', false
		catalogPath = repoPath + 'catalogs/'
		isAdmin = Mandrill.user.isAdmin this.userId
		canMakecatalogs = isAdmin is true or partyMode is true
		errors = []
		logs = []
		catalogs = {all:[]}


		if canMakecatalogs is false
			throw new Meteor.Error 403, 'You do not have permission to run makecatalogs'

		if repoPath is ''
			throw new Meteor.Error 500, 'Unable to determine the full path to your repo!'


		for pkginfo in MunkiPkgsinfo.find({'err': {'$exists': false}}).fetch()

			# don't copy admin notes
			if pkginfo.dom.notes?
				delete pkginfo.dom.notes
			# strip out any keys that start with "_"
			# (example: pkginfo _metadata)
			for own key, val of pkginfo.dom
				if key.indexOf('_') is 0
					delete pkginfo.dom[key]

			# simple sanity checking
			doPkgCheck = true
			installerType = pkginfo.dom.installer_type
			if installerType in ['nopkg', 'apple_update_metadata']
				doPkgCheck = false
			if pkginfo.dom.PackageCompleteURL?
				doPkgCheck = false
			if pkginfo.dom.PackageURL?
				doPkgCheck = false

			if doPkgCheck is true
				if not pkginfo.dom.installer_item_location?
					errors.push 'WARNING: file ' + pkginfo.path +
						' is missing installer_item_location'
					# Skip this pkginfo unless we're running with the force flag
					if not insane
						continue

				# form a path for the installer item location
				installerItemPath = repoPath + 'pkgs/' + pkginfo.dom.installer_item_location

				# Check if the installer item actually exists
				if not shell.test('-f', installerItemPath)
					errors.push 'WARNING: Info file ' + pkginfo.path +
						' refers to missing installer item ' + pkginfo.dom.installer_item_location

					# Skip this pkginfo unless we're running with force flag
					if not insane
						continue

			catalogs.all.push pkginfo.dom
			for catalogName in pkginfo.dom.catalogs
				if not catalogName? or catalogName is ''
					errors.push 'WARNING: Info file ' + pkginfo.path +
						' has an empty catalog name!'
					continue

				if not catalogs[catalogName]?
					catalogs[catalogName] = []
				catalogs[catalogName].push pkginfo.dom
				logs.push 'Adding ' + pkginfo.path + ' to ' + catalogName + '...'

		if errors.length > 0
			# print errors to the server console so they can be logged.
			for error in errors
				console.error error

		# clear out old catalogs
		catalogPath = repoPath + 'catalogs/'
		if not shell.test('-d', catalogPath)
			shell.mkdir '-p', catalogPath
		shell.rm '-f', catalogPath + '*'

		# write the new catalogs
		for own key, catalog of catalogs
			catalogPath = repoPath + 'catalogs/' + key
			if shell.test('-f', catalogPath) is true
				errors.push 'WARNING: catalog ' + key + ' already exists at ' +
					catalogPath + '. Perhaps this is a non0case sensitive ' +
					'filesystem and you have catalogs with names differing ' +
					'only in case?'
			else if catalog.length > 0
				plist.buildString(catalog).to(catalogPath)
				console.log 'Created catalog ' + key + '...'
			else
				console.error 'WARNING: Did not create catalog ' + key +
				' because it is empty'

		# send the logs and error messages back to the caller.
		{logs: logs, errors: errors}
}
