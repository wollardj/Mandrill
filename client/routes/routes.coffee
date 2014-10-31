Router.configure {
	layoutTemplate: 'appLayout'
	loadingTemplate: 'loading'
	notFoundTemplate: 'notFound'
}


Router.onBeforeAction ->
	if Meteor.loggingIn()
		this.render 'loading'
	else
		this.next()



Router.map ->

	this.route 'home', {
		path: '/',
		controller: 'HomeRouter'
	}

	this.route 'repo', {
		path: '/munki/'
		controller: 'RepoRouter'
	}

	this.route 'repo_edit', {
		path: '/munki/edit/'
		controller: 'RepoEditRouter'

	}

	this.route 'me', {
		path: '/me',
		controller: 'MeRouter'
	}



	#// --- Admin Routes --- //

	this.route 'accounts', {
		path: '/admin/accounts',
		controller: 'AccountsRouter'
	}

	this.route 'accounts-access', {
		path: '/admin/accounts/access/:_id',
		controller: 'AccountsAccessRouter'
	}

	this.route 'login-services', {
		path: '/admin/loginServices',
		controller: 'LoginServicesRouter'
	}

	this.route 'mandrill-settings', {
		path: '/admin/mandrill/settings',
		controller: 'MandrillSettingsRouter'
	}


	this.route 'not-found', {
		path: '*',
		controller: 'NotFoundRouter'
	}
