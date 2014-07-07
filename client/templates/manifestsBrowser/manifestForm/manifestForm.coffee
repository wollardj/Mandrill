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
	generic function to be used when a single item needs to be added
	to the an array, which is defined by a key and then sorted.
###
add_to_active_manifest_sorted = (key, value)->
	prepend_to_active_manifest(key, value)

	manifest = Session.get 'active_manifest'
	if not manifest?
		return

	manifest.dom[key] = manifest.dom[key].sort (a, b)->
		pkg_a = MunkiPkgsinfo.findOne({'dom.name': a.split('-')[0]})
		pkg_b = MunkiPkgsinfo.findOne({'dom.name': b.split('-')[0]})

		if pkg_a? and pkg_a.dom? and pkg_a.dom.display_name?
			a = pkg_a.dom.display_name
		if pkg_b? and pkg_b.dom? and pkg_b.dom.display_name?
			b = pkg_b.dom.display_name

		a.localeCompare(b)
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
	Returns the array of objects for all of the pkginfo searches.
	At most, this will return 10 suggestions, but probably less when
	Session.get('search_ignores_versions') is true (default).
###
Template.manifestForm.ac_pkgs = (query, callback)->
	repo_path = MandrillSettings.get 'munkiRepoPath'
	if repo_path?
		search = new RegExp('.*' + query + '.*', 'i')
		pkgs = MunkiPkgsinfo.find {
				'$and':[
					{'dom.update_for': {'$exists': false}}
					{
						'$or':[
							{'dom.name': search}
							{'dom.display_name': search}
						]
					}
				]
			}, 
			{
				fields: {
					'dom.name': true,
					'dom.display_name': true,
					'dom.version':true
				}
				sort: {'dom.name': 1, 'dom.version': -1}
				# There probably isn't a great case for having more than 50
				# versions of a pkg in your repo other than 'why not', so
				# 'why not' limit to 50 to keep loop cycles down
				limit: 50
			}
		.fetch().map (it)->
			{
				value: it.dom.name + '-' + it.dom.version
				name: it.dom.name
				display_name: it.dom.display_name
				version: it.dom.version
			}

		# We'll flip a and b to make the newest versions first
		pkgs = pkgs.sort (b,a)->
			name_order = a.name.localeCompare(b.name)
			if name_order is 0
				Mandrill.util.versionCompare a.version, b.version
			else
				name_order

		# If we're to ignore versions (a.k.a. use the latest), we need to further
		# reduce and mutate the results
		if Session.equals('search_ignores_versions', true) is true
			filtered_pkgs = []

			for obj, i in pkgs
				found = false
				for fobj,j in filtered_pkgs
					if fobj.name is obj.name
						found = true
						break
				if not found
					filtered_pkgs.push {
						value: obj.name
						name: obj.name
						display_name: obj.display_name
						version: obj.version
					}
			callback _.first(filtered_pkgs, 10)
		else
			callback _.first(pkgs, 10)




Template.manifestForm.pkg_name_is_valid = ->
	MunkiPkgsinfo.findOne({'dom.name': this.toString()})?



Template.manifestForm.icon_url = ->
	SoftwareRepoURL = MandrillSettings.get 'SoftwareRepoURL'
	icon = MunkiIcons.findOne {name: this.toString().split('-')[0]}
	if SoftwareRepoURL? and icon?
		SoftwareRepoURL + 'icons/' + icon.file
	else
		'/pkg.png'

Template.manifestForm.pkg_display_name = ->
	pkg = MunkiPkgsinfo.findOne({'dom.name': this.toString().split('-')[0]})
	if pkg? and pkg.dom? and pkg.dom.display_name?
		pkg.dom.display_name




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