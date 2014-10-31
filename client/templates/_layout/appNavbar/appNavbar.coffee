Session.setDefault 'runningMakeCatalogs', false
Session.setDefault 'munki_repo_item_count', '...'

Template.appNavbar.helpers {

	routeIsActive: (aRoute) ->
		current_router = Router.current()
		if current_router? and current_router.route?
			routerName = Router.current().route.name
		if routerName? and routerName is aRoute
			'active'
		else
			''

	munki_repo_item_count: ->
		mr = MandrillStats.findOne('munki_repo')
		if mr?
			mr.count
		else
			'...'

	manifestErrorsCount: ->
		stats = RepoStats.findOne 'manifestErrors'
		if stats? and stats.count
			stats.count
		else
			0

	installsCount: ->
		stats = RepoStats.findOne 'pkgsinfo'
		if stats? and stats.count
			stats.count
		else
			0


	installsErrorsCount: ->
		stats = RepoStats.findOne 'pkgsinfoErrors'
		if stats? and stats.count
			stats.count
		else
			0


	catalogsCount: ->
		stats = RepoStats.findOne 'catalogs'
		if stats? and stats.count
			stats.count
		else
			0


	catalogsErrorsCount: ->
		stats = RepoStats.findOne 'catalogErrors'
		if stats? and stats.count
			stats.count
		else
			0


	loggedInUserDisplayName: ->
		act = Meteor.users.findOne()
		if act? and act.profile? and act.profile.name?
			act.profile.name
		else
			'??'


	runningMakeCatalogs: ->
		Session.get 'runningMakeCatalogs'


	makecatalogsCommand: ->
		insane = MandrillSettings.get 'makeCatalogsSanityIsDisabled', false
		if insane is true
			'makecatalogs -f'
		else
			'makecatalogs'
}



Template.appNavbar.events {
	'click #logout': (event) ->
		event.stopPropagation()
		event.preventDefault()
		Meteor.logout()



	'click #makecatalogs': (event) ->
		event.stopPropagation()
		event.preventDefault()
		Session.set 'runningMakeCatalogs', true
		Meteor.call 'runMakeCatalogs', (err, data)->
			Session.set 'runningMakeCatalogs', false
			if err?
				Mandrill.show.error(err)
			else
				Mandrill.show.success 'Processed ' + data.logs.length + ' files',
					' Found ' + data.errors.length + ' warnings or errors.' +
					' Open your browser console to view the output.'
				for log in data.logs
					console.log log
				for error in data.errors
					console.warn error
}
