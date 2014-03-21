Meteor.methods {
	'manifestCountForCatalog': (catalog) ->
		MunkiManifests.find(
			{'raw': new RegExp('>' + catalog + '<', 'i')}
			{fields: {_id: 1}}
		).count()


	'listCatalogs': ->
		catalogs = []

		filter = Mandrill.user.accessPatternsFilter(this.userId);

		pkgs = MunkiPkgsinfo.find(
			filter, {'fields':{'dom.catalogs': 1}}
		).fetch()

		for pkg in pkgs
			if pkg.dom? and pkg.dom.catalogs?
				for catalog in pkg.dom.catalogs
					if catalogs.indexOf(catalog) is -1
						catalogs.push catalog

		catalogs.sort()
}