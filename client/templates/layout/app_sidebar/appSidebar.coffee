Session.setDefault 'runningMakeCatalogs', false



Template.appSidebar.routeIsActive = (aRoute) ->
	routerName = Router.current().route.name
	if routerName? and routerName is aRoute
		'active'
	else
		''



Template.appSidebar.otherTools = ->
	OtherTools.find({}, {sort: {displayText: 1}}).fetch()



Template.appSidebar.manifestsCount = ->
	stats = RepoStats.findOne 'manifests'
	if stats? and stats.count
		stats.count
	else
		0



Template.appSidebar.manifestErrorsCount = ->
	stats = RepoStats.findOne 'manifestErrors'
	if stats? and stats.count
		stats.count
	else
		0



Template.appSidebar.installsCount = ->
	stats = RepoStats.findOne 'pkgsinfo'
	if stats? and stats.count
		stats.count
	else
		0



Template.appSidebar.installsErrorsCount = ->
	stats = RepoStats.findOne 'pkgsinfoErrors'
	if stats? and stats.count
		stats.count
	else
		0



Template.appSidebar.catalogsCount = ->
	stats = RepoStats.findOne 'catalogs'
	if stats? and stats.count
		stats.count
	else
		0



Template.appSidebar.catalogsErrorsCount = ->
	stats = RepoStats.findOne 'catalogErrors'
	if stats? and stats.count
		stats.count
	else
		0



Template.appSidebar.makeCatalogsIsEnabled = ->
	MandrillSettings.get 'makeCatalogsIsEnabled', false



Template.appSidebar.loggedInUserDisplayName = ->
	act = Meteor.users.findOne()
	if act? and act.profile? and act.profile.name?
		act.profile.name
	else
		'??'



Template.appSidebar.runningMakeCatalogs = ->
	Session.get 'runningMakeCatalogs'



Template.appSidebar.makecatalogsCommand = ->
	insane = MandrillSettings.get 'makeCatalogsSanityIsDisabled', false
	if insane is true
		'makecatalogs -f'
	else
		'makecatalogs'



Template.appSidebar.events {
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