###
	Global route configurations
###
Router.configure {
	layoutTemplate: 'appLayout'
	loadingTemplate: 'loading'
	notFoundTemplate: 'notFound'

	###
		Makes sure the collections that are needed across all (or at least most)
		routes are loaded before the route renders.
	###
	waitOn: ->
		user = Meteor.user()
		if not user?
			return []

		[
			Meteor.subscribe 'MandrillAccounts'
			Meteor.subscribe 'MandrillStats'
			Meteor.subscribe 'MandrillSettings'
			Meteor.subscribe 'MunkiSettings'
			# Meteor.subscribe 'MunkiLogs'
		]


	###
		If no one is logged in, display the login form.
		If the route's path starts with '/admin', make sure the user is actually
		an admin, and if not, render the notFound route.
		If the two above conditions don't provoke any action, display the user's
		desired route
	###
	onBeforeAction: ->
		if Meteor.loggingIn()
			this.render 'loading'
		else
			user = Meteor.user()
			isAdmin = user? and user.mandrill? and user.mandrill.isAdmin is true
			adminOnly = this.route.path()?.match(/^\/admin/) isnt null

			if user?
				if isAdmin is false and adminOnly is true
					this.render 'notFound'
				else
					this.next()
			else
				this.render 'login'
}





Router.route 'home', {
	path: '/'
	template:'index'
	waitOn: -> Meteor.subscribe 'ServerStats'
}


Router.route 'repo', {
	path: '/munki'
	template: 'repo'
	waitOn: -> Meteor.subscribe 'MunkiRepo'
}


Router.route 'repo_edit', {
	path: '/munki/edit'
	template: 'repo_edit'
	waitOn: -> Meteor.subscribe 'MunkiRepo'
	data: ->
		path = Mandrill.path.concat Munki.repoPath(), this.params.query.c
		MunkiRepo.findOne {path: path}
}


Router.route 'me', {
	path: '/whoami'
	template: 'me'
	data: -> Meteor.user()
}


Router.route 'accounts', {
	path: '/admin/accounts'
	template: 'accounts'
}


Router.route 'accounts-access', {
	path: '/admin/accounts/access/:_id'
	template: 'accountsAccess'
	data: ->
		{
			user: Meteor.users.findOne {_id: this.params._id}
		}
}


Router.route 'login-services', {
	path: '/admin/loginServices'
	template: 'loginServices'
}


Router.route 'mandrill-settings', {
	path: '/admin/mandrill/settings'
	template: 'mandrillSettings'
}


Router.route 'not-found', {
	path: '*',
	controller: 'NotFoundRouter'
}
