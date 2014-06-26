Session.setDefault 'runningMakeCatalogs', false



Template.appNavbar.routeIsActive = (aRoute) ->
	routerName = Router.current().route.name
	if routerName? and routerName is aRoute
		'active'
	else
		''



Template.appNavbar.otherTools = ->
	OtherTools.find({}, {sort: {displayText: 1}}).fetch()



Template.appNavbar.manifestsCount = ->
	stats = RepoStats.findOne 'manifests'
	if stats? and stats.count
		stats.count
	else
		0



Template.appNavbar.manifestErrorsCount = ->
	stats = RepoStats.findOne 'manifestErrors'
	if stats? and stats.count
		stats.count
	else
		0



Template.appNavbar.installsCount = ->
	stats = RepoStats.findOne 'pkgsinfo'
	if stats? and stats.count
		stats.count
	else
		0



Template.appNavbar.installsErrorsCount = ->
	stats = RepoStats.findOne 'pkgsinfoErrors'
	if stats? and stats.count
		stats.count
	else
		0



Template.appNavbar.catalogsCount = ->
	stats = RepoStats.findOne 'catalogs'
	if stats? and stats.count
		stats.count
	else
		0



Template.appNavbar.catalogsErrorsCount = ->
	stats = RepoStats.findOne 'catalogErrors'
	if stats? and stats.count
		stats.count
	else
		0



Template.appNavbar.makeCatalogsIsEnabled = ->
	MandrillSettings.get 'makeCatalogsIsEnabled', false



Template.appNavbar.loggedInUserDisplayName = ->
	act = Meteor.users.findOne()
	if act? and act.profile? and act.profile.name?
		act.profile.name
	else
		'??'



Template.appNavbar.runningMakeCatalogs = ->
	Session.get 'runningMakeCatalogs'



Template.appNavbar.makecatalogsCommand = ->
	insane = MandrillSettings.get 'makeCatalogsSanityIsDisabled', false
	if insane is true
		'makecatalogs -f'
	else
		'makecatalogs'



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