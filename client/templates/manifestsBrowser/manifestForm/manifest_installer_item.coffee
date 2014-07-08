Template.manifest_installer_item.datum = ->
	manifest = Session.get 'active_manifest'
	if manifest? and manifest.dom?
		manifest.dom[this.toString()]
	else
		[]

# Returns the glyphicon-{{glyph}} appropriate for the category.
Template.manifest_installer_item.glyph = ->
	glyphs = {
		'managed_installs': 'save'
		'optional_installs': 'cloud-download'
		'managed_updates': 'refresh'
		'managed_uninstalls': 'remove-circle'
	}
	glyphs[this.toString()]


# Converts the value of `this` to a title.
# example: 'managed_installs' becomes 'Managed Installs'
Template.manifest_installer_item.title = ->
	key = this.toString()
	key.replace('_', ' ')
		.split(' ')
		.map (it)->
			it[0].toUpperCase() + it.replace(/^./, '')
		.join(' ')


# Returns the custom icon for the given pkginfo item, or /pkg.png if
# there isn't one.
Template.manifest_installer_item.icon_url = ->
	SoftwareRepoURL = MandrillSettings.get 'SoftwareRepoURL'
	icon = MunkiIcons.findOne {name: this.toString().split('-')[0]}
	if SoftwareRepoURL? and icon?
		SoftwareRepoURL + 'icons/' + icon.file
	else
		'/pkg.png'


# Searches for the pkginfo item by name and returns its display_name, if there is one.
Template.manifest_installer_item.pkg_display_name = ->
	pkg = MunkiPkgsinfo.findOne({'dom.name': this.toString().split('-')[0]})
	if pkg? and pkg.dom? and pkg.dom.display_name?
		pkg.dom.display_name


# Searches for a matching pkginfo item by its name and returns `true` if found,
# `false` if not.
Template.manifest_installer_item.pkg_name_is_valid = ->
	MunkiPkgsinfo.findOne({'dom.name': this.toString()})?




###
	autocomplete/typeahead selection handler for each manifest.
	The field id must be in the form of 'select_<field-name>_field'
	where <field-name> is one of the supported top-level array fields
	in a manifest. e.g. included_manifets, catalogs, managed_installs,
	managed_updates, optional_installs, or managed_uninstalls.

###
Template.manifest_installer_item.ac_manifest_field_selected = (event, datum)->
	id = $(event.target).attr('id')
	value = datum.value
	field = id.replace(/^select_(.*)_field$/, '$1')
	if field?
		$('#' + id).typeahead('val', '')

		manifest = Session.get 'active_manifest'
		if not manifest?
			return

		dom = manifest.dom
		if dom? and dom[field]? and -1 is dom[field].indexOf value
			manifest.dom[field].unshift value
		else if not dom? or not dom[field]?
			manifest.dom[field] = [value]
		
		manifest.dom[field] = manifest.dom[field].sort (a, b)->
			pkg_a = MunkiPkgsinfo.findOne({'dom.name': a.split('-')[0]})
			pkg_b = MunkiPkgsinfo.findOne({'dom.name': b.split('-')[0]})

			if pkg_a? and pkg_a.dom? and pkg_a.dom.display_name?
				a = pkg_a.dom.display_name
			if pkg_b? and pkg_b.dom? and pkg_b.dom.display_name?
				b = pkg_b.dom.display_name
			a.localeCompare(b)

		Session.set 'active_manifest', manifest




###
	Returns the array of objects for all of the pkginfo searches.
	At most, this will return 10 suggestions, but probably less when
	Session.get('search_ignores_versions') is true (default).
###
Template.manifest_installer_item.ac_pkgs = (query, callback)->
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
		.sort (b,a)->
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