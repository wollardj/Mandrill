Template.ac_pkgsinfo.icon_url = ->
	SoftwareRepoURL = MandrillSettings.get 'SoftwareRepoURL'
	icon = MunkiIcons.findOne {name: this.name}
	if SoftwareRepoURL? and icon?
		SoftwareRepoURL + 'icons/' + icon.file
	else
		'/pkg.png'


# Returns true if pkg searches ignore version information, false otherwise
Template.ac_pkgsinfo.search_ignores_versions = ()->
	Session.get 'search_ignores_versions'