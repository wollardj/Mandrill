# ignore/hide pkg versions when searching by default
Session.setDefault 'search_ignores_versions', true
Session.setDefault 'active_manifest', {}



Template.manifestsBrowser.active_manifest = ()->
	Session.get 'active_manifest'



# Returns true to indicate the active manifest has modifications that
# have not yet been stored in the database.
Template.manifestsBrowser.active_manifest_has_changes = ()->
	a_manifest = Session.get 'active_manifest'
	if a_manifest? and a_manifest._id?
		b_manifest = MunkiManifests.findOne({_id: a_manifest._id})
		not _.isEqual(a_manifest, b_manifest)



# Returns the relative path (a.k.a. 'name') of the active manifest
Template.manifestsBrowser.active_manifest_name = ()->
	manifest = Session.get 'active_manifest'
	repo_path = MandrillSettings.get 'munkiRepoPath'
	name = ''
	if manifest? and manifest.path? and repo_path?
		name = manifest.path.replace repo_path + 'manifests/', ''

	# Also make sure the typeahead instance is aware of the value change
	$('#manifest_search').typeahead('val', name)
	name


# Returns true if the user asked for the text editor, false otherwise
Template.manifestsBrowser.show_text_editor = ()->
	params = Router.current().params
	params.hash? and params.hash is 'plist'


# Inject the typeahead functionality and change the `display` property
# of the resulting surrounding span from 'inline-block' to 'table-cell'
# so it flexes with the page and keeps the autocomplete menu positioned
# correctly.
Template.manifestsBrowser.rendered = ->
	Mandrill.util.activateTypeahead('#manifest_search')



Template.manifestsBrowser.can_create_manifest = ()->
	btn = $('#create_manifest_btn')
	manifest_name = $('#manifest_search').val()
	repo_path = MandrillSettings.get 'munkiRepoPath'
	if not repo_path?
		btn.addClass 'disabled'
	else
		manifest_path = repo_path + 'manifests/' + manifest_name
		cursor = MunkiManifests.find {path: manifest_path}, {limit: 1}
		if manifest_name isnt '' and cursor.count() is 0
			btn.removeClass 'disabled'
		else
			btn.addClass 'disabled'



Template.manifestsBrowser.ac_manifests_selected = (event, datum)->
	repoPath = MandrillSettings.get 'munkiRepoPath'
	Template.manifestsBrowser.can_create_manifest()
	if repoPath?
		manifest_path = repoPath + 'manifests/' + $(event.target).val()
		active_manifest = MunkiManifests.findOne({path: manifest_path})
		Router.go('manifestsBrowser', active_manifest)


Template.manifestsBrowser.ac_manifests = (query, cb)->
	settings = MandrillSettings.findOne()
	if not settings?
		return []

	prefix = settings.munkiRepoPath + 'manifests/'
	search = new RegExp(prefix + '.*' + query + '.*', 'i')
	cb(
		MunkiManifests.find(
			{path: search},
			{fields: {path: true}, limit: 5}
		).fetch().map (it)->
			{value: it.path.replace(prefix, '')}
	)



Template.manifestsBrowser.events {
	# Reload the active_manifest's contents from the database
	'click #discard_changes': (event)->
		manifest = Session.get 'active_manifest'
		if manifest? and manifest._id?
			Session.set 'active_manifest', MunkiManifests.findOne({_id: manifest._id})


	# toggles the autocomplete/typeahead behavior to invlude versions, or not.
	'click #search_ignores_versions_btn': (event)->
		$(event.target).blur()
		if Session.equals('search_ignores_versions', true) is true
			Session.set 'search_ignores_versions', false
		else
			Session.set 'search_ignores_versions', true

	'click #save_manifest_btn': (event)->
		$(event.target).blur()
		manifest = Session.get 'active_manifest'
		router = Router.current()
		if manifest? and router?
			if router.params? and router.params.hash? and router.params.hash is 'plist'
				Meteor.call 'filePutContents', manifest.path, manifest.raw
			else
				Meteor.call 'filePutContentsUsingObject', manifest.path, manifest.dom


	# enable or disable #create_manifest_btn as the user types
	"keyup #manifest_search": (event)->
		Template.manifestsBrowser.can_create_manifest()


	# Allow the user to actually create an empty manifest
	"click #create_manifest_btn": (event)->
		if $(event.target).hasClass('disabled') is true
			return
		else
			repoPath = MandrillSettings.get 'munkiRepoPath'
			if repoPath?
				manifest_path = repoPath + 'manifests/' + $('#manifest_search').val()
				Meteor.call(
					'createManifest'
					manifest_path
					(err, data)->
						if err?
							Mandrill.show.error err
				)
			else
				Mandrill.show.error(new Meteor.Error(500,
					'Path to munki_repo has not been set.'))

	'click #switch_to_manifest_form': (event)->
		href = window.location.href.split('#')[0]
		Router.go href

	'click #switch_to_manifest_plist': (event)->
		Router.go window.location.href + '#plist'
}