var fs = Meteor.require('fs'),
	plist = Meteor.require('plist-native'),
	shell = Meteor.require('shelljs');

CurrentWatcherPath = new Meteor.EnvironmentVariable();


WatchHandler = {

	repoPath: '',


	// Returns one of 'catalog', 'manifest', 'pkgsinfo', pr 'unknown'
	// depending on which subdirectory within the repo the file is found.
	repoTypeForPath: Meteor.bindEnvironment(function(aPath) {
		var settings = MandrillSettings.findOne(),
			repo = settings && settings.munkiRepoPath ?
				settings.munkiRepoPath :
				'';
		
		if (repo !== '') {
			WatchHandler.repoPath = repo;
		}

		if (aPath.indexOf(repo + 'manifests/') !== -1) {
			return 'manifests';
		}
		else if (aPath.indexOf(repo + 'catalogs/') !== -1) {
			return 'catalogs';
		}
		else if (aPath.indexOf(repo + 'pkgsinfo/') !== -1) {
			return 'pkgsinfo';
		}
		else {
			return 'unknown';
		}
	}, function(e) {
		throw e;
	}),




	// Removes a file from the database, using its path to find
	// the document
	deleteFile: Meteor.bindEnvironment(function(path) {
		var repoType = WatchHandler.repoTypeForPath(path);

		if (repoType === 'manifests') {
			MunkiManifests.remove({path: path});
		}
		else if (repoType === 'pkgsinfo') {
			MunkiPkgsinfo.remove({path: path});
		}
		else if (repoType === 'catalogs') {
			MunkiCatalogs.remove({path: path});
		}
	}),




	//
	// Reads a file at the given path and attempts to parse its plist
	// contents. If the file cannot be read from disk, an exception is
	// thrown. In all other cases, including a failure to parse, a document
	// is added to the databse.
	// If there were errors while parsing, those errors will be added to
	// that document.
	// Both the parsed (when succesful) and raw text repesentations of the
	// file live in the document as well. The full structure is...
	//
	// {
	//		dom:  [Object],	// the parsed object structure
	//		raw:  [String],	// the raw text of the file
	//		path: [String],	// the full path to the file on disk
	//		err:  [String],	// Only present to indicate parsing errors.
	// }
	//
	processFile: Meteor.bindEnvironment(function(path) {
		CurrentWatcherPath.withValue(path, function() {
			// Skip non-regular files.
			if (shell.test('-f', path) === false) {
				return;
			}
			fs.readFile(
				path,
				{encoding: 'utf8'},
				Meteor.bindEnvironment(function(err, data) {
					var parsedData = null,
						parseError = null,
						urlName = '',
						basePath = '',
						mongoDocument = {},
						path = CurrentWatcherPath.get(),
						repoType = WatchHandler.repoTypeForPath(path);


					// deal with any errors from fs.readFile()
					if (err) {
						parseError = 'Unable to read file ' + path;
					}
					else {
						// Attempt to parse the plist file
						try {
							parsedData = plist.parse(fs.readFileSync(path));
						} catch(e) {
							parseError = e.toString();
						}
					}


					// we'll add a url 'safe'-ish value to be used by the
					// router for better linking
					basePath = WatchHandler.repoPath + repoType + '/';
					urlName = path.replace(basePath, '')
						.replace(/\//g, '_');
					mongoDocument = {
						path: path,
						dom: parsedData,
						raw: data,
						urlName: urlName
					};

					if (parseError !== null) {
						mongoDocument.err = parseError;
					}


					// For the uninitiated, 'upsert' does just what it
					// sounds like it should. If it finds a matching
					// document or documents, it/they are updated. If not,
					// the information is inserted as a new document.

					// Inserting a manifest
					if (repoType === 'manifests') {
						MunkiManifests.upsert(
							{path: path},
							mongoDocument,
							function(err) {
								if (err) {console.error(err);}
							}
						);
					}

					// Inserting a pkgsinfo
					else if (repoType === 'pkgsinfo') {
						MunkiPkgsinfo.upsert(
							{path: path},
							mongoDocument,
							function(err) {
								if (err) {console.error(err);}
							}
						);
					}

					// Inserting a catalog
					else if (repoType === 'catalogs') {
						MunkiCatalogs.upsert(
							{path: path},
							mongoDocument,
							function(err) {
								if (err) {console.error(err);}
							}
						);
					}

				}, function(e){
					throw e;
				})
			);
		});
	}, function(e) {
		throw e;
	}),



	//
	// Obtains a flat array of paths being watched by a watcher
	// and its child watchers.
	//
	watcherPaths: function(watcher) {
		var children = watcher.children,
			stat,
			files = [];

		for (var nodeName in children) {
			if (children.hasOwnProperty(nodeName)) {
				
				try {
					stat = fs.lstatSync(children[nodeName].path);
				} catch(e) {
					// the file does not appear to exist, so we'll skip it
					continue;
				}

				if (stat.isDirectory()) {
					files = files.concat(
						WatchHandler.watcherPaths(children[nodeName]));
				}
				else {
					files.push(children[nodeName].path);
				}
			}
		}
		return files;
	}
};