###
	generic function to be used when a single item needs to be added
	to the begining of an array defined by a key.
###
prepend_to_active_manifest = (key, value)->
	manifest = Session.get 'active_manifest'
	if not manifest?
		return

	dom = manifest.dom
	if dom? and dom[key]? and -1 is dom[key].indexOf value
		manifest.dom[key].unshift value
	else if not dom? or not dom[key]?
		manifest.dom[key] = [value]
	Session.set 'active_manifest', manifest



###
	generic function that removes an item from the active manifest as defined by its
	key. Example: to remove 'production' from 'catalogs' would be
	remove_from_active_manifest('catalogs', 'production')
###
remove_from_active_manifest = (key, value)->
	manifest = Session.get 'active_manifest'
	if manifest? and manifest.dom? and manifest.dom[key]?
		idx = manifest.dom[key].indexOf value
		if idx isnt -1
			manifest.dom[key].splice idx, 1
			Session.set 'active_manifest', manifest





Template.manifestForm.rendered = ()->
	Mandrill.util.activateTypeahead('.typeahead')
	$('#admin_notes').css('overflow', 'hidden').autogrow()



# Returns the list of available catalog names for the auto-complete menu
Template.manifestForm.ac_catalogs = (query, callback)->
	repo_path = MandrillSettings.get 'munkiRepoPath'
	if repo_path?
		pattern = '^' + repo_path + 'catalogs/.*' + query + '.*$'
		search = new RegExp(pattern, 'i')
		all_catalog = repo_path + 'catalogs/all'
		catalogs = MunkiCatalogs.find {
				$and: [
					{path: search}
					{path: {'$not': all_catalog}}
				]
			},
			{
				fields: {path:true},
				sort: {path: 1}
			}
		.fetch().map (it)->
			name = it.path.split('/').pop()
			{value: name}

		callback catalogs


# Returns the list of available manifest names for the auto-complete menu
Template.manifestForm.ac_manifests = (query, callback)->
	repo_path = MandrillSettings.get 'munkiRepoPath'
	if repo_path?
		pattern = '^' + repo_path + 'manifests/.*' + query + '.*$'
		search = new RegExp(pattern, 'i')
		manifests = MunkiManifests.find {
				'$and': [
					{path: search}
					{'dom.catalogs': []}
				]
			},
			{
				fields: {path: true}
				sort: {path: 1}
				limit: 5
			}
		.fetch().map (it)->
			if Session.get('active_manifest').path isnt it.path
				{value: it.path.replace repo_path + 'manifests/', ''}
			else
				null
		
		while manifests.indexOf(null) isnt -1
			manifests.splice(manifests.indexOf(null), 1)
		callback manifests




###
	autocomplete/typeahead selection handler for each manifest.
	The field id must be in the form of 'select_<field-name>_field'
	where <field-name> is one of the supported top-level array fields
	in a manifest. e.g. included_manifets, catalogs, managed_installs,
	managed_updates, optional_installs, or managed_uninstalls.

###
Template.manifestForm.ac_manifest_field_selected = (event, datum)->
	id = $(event.target).attr('id')
	field = id.replace(/^select_(.*)_field$/, '$1')
	if field?
		$('#' + id).typeahead('val', '')
		add_to_active_manifest_sorted field, datum.value




Template.manifestForm.events {

	# show the remove button when the mouse enters that button's parent region
	'mouseenter .has-remove-btn, mouseover .has-remove-btn': (event)->
		$(event.target).find('.remove-btn')
			.removeClass('elastic-out')
			.addClass('elastic-in')

	# hide the remove button when the mouse leaves its parent region
	'mouseleave .has-remove-btn': (event)->
		$(event.target).find('.remove-btn')
			.removeClass('elastic-in')
			.addClass('elastic-out')



	'click div.managed_installs-panel .remove-btn': (event)->
		remove_from_active_manifest 'managed_installs', this.toString()
	'click div.optional_installs-panel .remove-btn': (event)->
		remove_from_active_manifest 'optional_installs', this.toString()
	'click div.managed_updates-panel .remove-btn': (event)->
		remove_from_active_manifest 'managed_updates', this.toString()
	'click div.managed_uninstalls-panel .remove-btn': (event)->
		remove_from_active_manifest 'managed_uninstalls', this.toString()
	'click fieldset.catalogs .remove-btn': (event)->
		remove_from_active_manifest 'catalogs', this.toString()
	'click fieldset.included_manifests .remove-btn': (event)->
		remove_from_active_manifest 'included_manifests', this.toString()

	'change #admin_notes, keyup #admin_notes': (event)->
		manifest = Session.get 'active_manifest'
		if manifest?
			manifest.dom.admin_notes = $(event.target).val()
			Session.set 'active_manifest', manifest

}