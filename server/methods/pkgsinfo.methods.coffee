plist = Meteor.require 'plist-native'
shell = Meteor.require 'shelljs'

Meteor.methods {
	'urlNameForPkginfo': (pkgName, pkgVersion)->
		record = MunkiPkgsinfo.findOne {'$and': [
			{'dom.name': pkgName}
			{'dom.version': pkgVersion}
		]}
		
		if record? and record.urlName?
			record.urlName

		else
			throw new Meteor.Error('-1',
				'Couldn\'t figure out which pkginfo file represents "' +
				pkgName + '-'+ pkgVersion + '"')




	#
	#	Returns `true` if the pkginfo file with a matching urlName refers to
	#	an installer_item_location file, provided that file exists. If the
	#	pkginfo is missing that attribute, or if it's present but the target
	#	file is missing, this method will return `false`.
	#
	'pkginfoHasInstallerItem': (urlName)->
		record = MunkiPkgsinfo.findOne({urlName: urlName})
		location = MandrillSettings.get 'munkiRepoPath', '/'

		if not record?
			throw new Meteor.Error(404,
				'That pkginfo file is no longer in the database.')

		if not record.dom? or not record.dom.installer_item_location?
			false

		else
			location += 'pkgs/' + record.dom.installer_item_location
			if shell.test('-f', location) is true
				true

			else
				false



	'createPkginfo': (pkgsinfoPath)->

		Mandrill.user.canModifyPath this.userId, pkgsinfoPath, true

		repoPath = GitBroker.git().repo
		d = new Date()
		relativePath = pkgsinfoPath.replace(repoPath, '')
		name = pkgsinfoPath.split('/').reverse()[0]
		record = {
			path: pkgsinfoPath,
			dom: {
				'catalogs': ['testing']
				'installer_type': 'nopkg'
				'name': name
				'display_name': name
				'description': ''
				'version': d.getFullYear() + '.' +
					d.getMonth() + '.' +
					d.getDay()
			}
		}

		# If there's a '-' in the pkginfo name, assume it's a version number
		# and update the appropriate values in the template we're about to
		# create.
		if relativePath.indexOf('-') >= 0
			record.dom.name = name.split('-')[0]
			record.dom.display_name = record.dom.name
			record.dom.version = name.replace record.dom.name + '-', ''

		Meteor.log.info 'Creating pkginfo file "' + record.path + '"'

		if shell.test('-e', record.path) is true
			throw new Meteor.Error(403,
				'A file already exists with that name')

		shell.mkdir '-p', record.path.replace(/\/[^/]*$/, '')
		if shell.error()?
			throw new Meteor.Error 500, shell.error()

		record.raw = plist.buildString record.dom
		record.raw.to record.path

		if shell.error()?
			throw new Meteor.Error 500, shell.error()

		record.urlName = record.path
			.replace repoPath + 'pkgsinfo/', ''
			.replace /\//g, '_'
		
		MunkiPkgsinfo.insert record
		if GitBroker.gitIsEnabled() is true
			GitBroker.add relativePath
			GitBroker.commit this.userId, relativePath, '[Mandrill] Added "' +
				relativePath + '"'

		record





	'unlinkPkginfo': (pkgsinfoPath, unlinkInstallerItem)->
		Mandrill.user.canModifyPath this.userId, pkgsinfoPath, true

		repo = GitBroker.git().repo
		relativePath = pkgsinfoPath.replace(repo, '')
		unlinkInstallerItem = unlinkInstallerItem or false
		installerItemPath = ''


		if unlinkInstallerItem is true
			installerItemPath = Meteor.call(
				'unlinkPkginfoInstallerItem',
				pkgsinfoPath)


		if GitBroker.gitIsEnabled() is true
			gitResults = GitBroker.remove relativePath

			if gitResults.code is 0
				if unlinkInstallerItem is true
					GitBroker.commit this.userId, relativePath,
						'[Mandrill] Removed "' + relativePath + '"',
						'Also removed the corresponding installer item at "' +
						installerItemPath + '"'
				else
					GitBroker.commit this.userId, relativePath,
						'[Mandrill] Removed "' + relativePath + '"'
				
				MunkiManifests.remove {path: pkgsinfoPath}

			# The file probably isn't under revision control
			else if gitResults.code is 128
				shell.rm pkgsinfoPath
				if shell.error()?
					throw new Meteor.Error 500, shell.error()
				MunkiPkgsinfo.remove {path: pkgsinfoPath}
			else
				throw new Meteor.Error gitResults.code, gitResults.output

		else
			shell.rm pkgsinfoPath
			if shell.error()?
				throw new Meteor.Error 500, shell.error()

			MunkiPkgsinfo.remove {path: pkgsinfoPath}



	#
	#	Accepts a full path to a pkginfo file and attempts to remove its
	#	referenced installer_item_location file. If installer_item_locaton
	#	isn't present in the dom (meaning the file must be a valid plist)
	#	or the attribute is present but refers to a missing file, this method
	#	will throw a Meteor.Error. It's best to call `pkginfoHasInstallerItem`
	#	and avoid calling this method if that one returns `false`.
	#
	'unlinkPkginfoInstallerItem': (pkginfoPath)->
		location = MandrillSettings.get 'munkiRepoPath', '/'
		pkginfo = MunkiPkgsinfo.findOne {path: pkginfoPath}

		Mandrill.user.canModifyPath this.userId, pkginfoPath, true

		if not pkginfo? or not pkginfo.dom? or not pkginfo.dom.installer_item_location?
			throw new Meteor.Error 404,
				'Unable to read installer_item_location. No installer item ' +
				'was removed.'
		else
			location += 'pkgs/' + pkginfo.dom.installer_item_location
			shell.rm location
			if shell.error()?
				throw new Meteor.Error 500, shell.error()

		location
}