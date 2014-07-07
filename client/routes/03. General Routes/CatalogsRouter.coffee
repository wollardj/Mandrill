@CatalogsRouter = AppRouter.extend {
	template: 'catalogs',

	onBeforeAction: ->
		#this.subscribe 'MunkiCatalogs'
		#	.wait()
		SelectedCatalogItems.remove {}
		if this.params.urlName?
			catalog = MunkiCatalogs.findOne {urlName: this.params.urlName}
			if catalog? and catalog.dom
				for item in catalog.dom
					do (item) ->
						SelectedCatalogItems.insert {
							name: item.name,
							display_name: item.display_name,
							version: item.version
						}
	
	data: ->
		#// If an ID was passed, the data passed to the template will consist
		#// of the single matching record. If not, the template will get
		#// all records.
		if this.params.urlName?
			{
				urlName: this.params.urlName,
				items: SelectedCatalogItems.find {}, {
						sort: {
							name: 1,
							display_name: 1,
							version: 1
						}
					}
					.fetch()
			}
		else
			{
				catalogs: MunkiCatalogs.find {}, {
						sort: {
							err: -1,
							urlName: 1
						}
					}
					.fetch()
			}


	onStop: ->
		SelectedCatalogItems.remove {}
}