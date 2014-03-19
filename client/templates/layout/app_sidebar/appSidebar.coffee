Session.setDefault 'runningMakeCatalogs', false



Template.appSidebar.rendered = ->
	Template.appSidebar.resize()



Template.appSidebar.routeIsActive = (aRoute) ->
	routerName = Router.current().route.name
	if routerName? and routerName is aRoute
		'active'
	else
		''



Template.appSidebar.resize = ->
	#// Make sure the height of the sidebar matches the available height
	#// within the window.
	winHeight = $(window).height() - 25
	$sidebar = $('#appSidebar')
	currentHeight = $sidebar.height()

	#// avoid triggering a re-draw if the height of the window
	#// isn't changing.
	if currentHeight isnt winHeight
		$sidebar.height(winHeight)



Template.appSidebar.created = ->
	#// Make sure the height of the sidebar always matches the available
	#// height when the window is resized.
	$(window).on('resize', Template.appSidebar.resize)



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
	settings = MandrillSettings.findOne()
	settings? and settings.makeCatalogsIsEnabled is true



Template.appSidebar.loggedInUserDisplayName = ->
	act = Meteor.users.findOne()
	if act? and act.profile? and act.profile.name?
		act.profile.name
	else
		'??'



Template.appSidebar.runningMakeCatalogs = ->
	Session.get 'runningMakeCatalogs'



Template.appSidebar.makecatalogsCommand = ->
	settings = MandrillSettings.findOne()
	if settings? and settings.makeCatalogsSanityIsDisabled is true
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
}