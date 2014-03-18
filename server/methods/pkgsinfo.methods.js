var plist = Meteor.require('plist-native'),
	shell = Meteor.require('shelljs');

Meteor.methods({
	'urlNameForPkginfo': function(pkgName, pkgVersion) {
		var record = MunkiPkgsinfo.findOne({'$and': [
			{'dom.name': pkgName},
			{'dom.version': pkgVersion}
		]});
		if (record) {
			return record.urlName;
		}
		else {
			throw new Meteor.Error('-1',
				'Couldn\'t figure out which pkginfo file represents "' +
				pkgName + '-'+ pkgVersion + '"');
		}
	},




	/*
		Returns an array of catalog names. This can be a different list
		than what's found in the `MunkiCatalogs` collection if modifications
		have been made to a pkginfo file but makecatalogs has not yet been
		executed.
	 */
	'listCatalogs': function() {
		var catalogs = [],
			pkgs = MunkiPkgsinfo.find({}, {'fields': {'catalogs': 1}}).fetch();

		for(var i = 0; i < pkgs.length; i++) {
			if (!pkgs[i].catalogs) {
				continue;
			}
			for(var j = 0; j < pkgs[i].catalogs.length; j++) {
				if (catalogs.indexOf(pkgs[i].catalogs[j]) === -1) {
					catalogs.push(pkgs[i].catalgs[j]);
				}
			}
		}
		return catalogs;
	},



	/*
		Returns `true` if the pkginfo file with a matching urlName refers to
		an installer_item_location file, provided that file exists. If the
		pkginfo is missing that attribute, or if it's present but the target
		file is missing, this method will return `false`.
	 */
	'pkginfoHasInstallerItem': function(urlName) {
		var record = MunkiPkgsinfo.findOne({urlName: urlName}),
			settings = MandrillSettings.findOne(),
			location = (settings ? settings.munkiRepoPath : '/');

		if (!record) {
			throw new Meteor.Error(404,
				'That pkginfo file is no longer in the database.');
		}

		if (!record.dom || !record.dom.installer_item_location) {
			return false;
		}
		else {
			location += 'pkgs/' + record.dom.installer_item_location;
			if (shell.test('-f', location) === true) {
				return true;
			}
			else {
				return false;
			}
		}
	},



	'createPkginfo': function(pkgsinfoPath) {

		Mandrill.user.canModifyPath(this.userId, pkgsinfoPath, true);

		var repoPath = GitBroker.git().repo,
			d = new Date(),
			relativePath = pkgsinfoPath.replace(repoPath, ''),
			name = pkgsinfoPath.split('/').reverse()[0],
			record = {
				path: pkgsinfoPath,
				dom: {
					'catalogs': ['testing'],
					'installer_type': 'nopkg',
					'name': name,
					'display_name': name,
					'description': '',
					'version': d.getFullYear() + '.' +
						d.getMonth() + '.' +
						d.getDay()
				}
			};

		// If there's a '-' in the pkginfo name, assume it's a version number
		// and update the appropriate values in the template we're about to
		// create.
		if (relativePath.indexOf('-')) {
			record.dom.name = name.split('-')[0];
			record.dom.display_name = record.dom.name;
			record.dom.version = name.replace(record.dom.name + '-', '');
		}

		Meteor.log.info('Creating pkginfo file "' + record.path + '"');

		if (shell.test('-e', record.path)) {
			throw new Meteor.Error(403,
				'A file already exists with that name');
		}

		shell.mkdir('-p', record.path.replace(/\/[^/]*$/, ''));
		if (shell.error() !== null) {
			throw new Meteor.Error(500, shell.error());
		}

		record.raw = plist.buildString(record.dom);
		record.raw.to(record.path);

		if (shell.error() !== null) {
			throw new Meteor.Error(500, shell.error());
		}

		record.urlName = record.path
			.replace(repoPath + 'pkgsinfo/', '')
			.replace(/\//g, '_');
		
		MunkiPkgsinfo.insert(record);
		if (GitBroker.gitIsEnabled() === true) {
			GitBroker.add(relativePath);
			GitBroker.commit(this.userId, relativePath, '[Mandrill] Added "' +
				relativePath + '"');
		}

		return record;
	},





	'unlinkPkginfo': function(pkgsinfoPath, unlinkInstallerItem) {
		Mandrill.user.canModifyPath(this.userId, pkgsinfoPath, true);

		var gitResults,
			repo = GitBroker.git().repo,
			relativePath = pkgsinfoPath.replace(repo, ''),
			unlinkInstallerItem = unlinkInstallerItem || false,
			installerItemPath = '';


		if (unlinkInstallerItem === true) {
			installerItemPath = Meteor.call(
				'unlinkPkginfoInstallerItem',
				pkgsinfoPath);
		}


		if (GitBroker.gitIsEnabled() === true) {
			gitResults = GitBroker.remove(relativePath);

			if (gitResults.code === 0) {
				if (unlinkInstallerItem === true) {
					GitBroker.commit(this.userId, relativePath,
						'[Mandrill] Removed "' + relativePath + '"',
						'Also removed the corresponding installer item at "' +
						installerItemPath + '"');
				}
				else {
					GitBroker.commit(this.userId, relativePath,
						'[Mandrill] Removed "' + relativePath + '"');
				}
				MunkiManifests.remove({path: pkgsinfoPath});
			}
			else {
				throw new Meteor.Error(gitResults.code, gitResults.output);
			}
		}
		else {
			shell.rm(pkgsinfoPath);
			if (shell.error() !== null) {
				throw new Meteor.Error(500, shell.error());
			}

			MunkiPkgsinfo.remove({path: pkgsinfoPath});
		}
	},



	/*
		Accepts a full path to a pkginfo file and attempts to remove its
		referenced installer_item_location file. If installer_item_locaton
		isn't present in the dom (meaning the file must be a valid plist)
		or the attribute is present but refers to a missing file, this method
		will throw a Meteor.Error. It's best to call `pkginfoHasInstallerItem`
		and avoid calling this method if that one returns `false`.
	 */
	'unlinkPkginfoInstallerItem': function(pkginfoPath) {
		var settings = MandrillSettings.findOne(),
			pkginfo = MunkiPkgsinfo.findOne({path: pkginfoPath}),
			location = settings.munkiRepoPath || '/';

		Mandrill.user.canModifyPath(this.userId, pkginfoPath, true);

		if (!pkginfo || !pkginfo.dom || !pkginfo.dom.installer_item_location) {
			throw new Meteor.Error(404,
				'Unable to read installer_item_location. No installer item ' +
				'was removed.');
		}
		else {
			location += 'pkgs/' + pkginfo.dom.installer_item_location;
			shell.rm(location);
			if (shell.error() !== null) {
				throw new Meteor.Error(500, shell.error());
			}
		}
		return location;
	}
});