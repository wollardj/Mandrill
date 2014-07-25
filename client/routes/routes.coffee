Router.configure {
	layoutTemplate: 'appLayout'
	loadingTemplate: 'loading'
	notFoundTemplate: 'notFound'
}



Router.map ->

	this.route 'home', {
		path: '/',
		controller: 'HomeRouter'
	}

	this.route 'repo', {
		path: '/repo/'
		controller: 'RepoRouter'
	}

	this.route 'manifests', {
		path: '/manifests/:urlName?',
		controller: 'ManifestsRouter'
	}

	this.route 'pkgsinfo', {
		path: '/pkgsinfo/:urlName?',
		controller: 'PkgsinfoRouter'
	}

	this.route 'catalogs', {
		path: '/catalogs/:urlName?',
		controller: 'CatalogsRouter'
	}

	this.route 'me', {
		path: '/me',
		controller: 'MeRouter'
	}



	#// --- Admin Routes --- //

	this.route 'accounts', {
		path: '/accounts',
		controller: 'AccountsRouter'
	}

	this.route 'accounts-access', {
		path: '/accounts/access/:_id',
		controller: 'AccountsAccessRouter'
	}

	this.route 'othertools', {
		path: '/othertools',
		controller: 'OtherToolsRouter'
	}

	this.route 'login-services', {
		path: '/login-services',
		controller: 'LoginServicesRouter'
	}

	this.route 'mandrill-settings', {
		path: '/mandrill-settings',
		controller: 'MandrillSettingsRouter'
	}


	this.route 'not-found', {
		path: '*',
		controller: 'NotFoundRouter'
	}
