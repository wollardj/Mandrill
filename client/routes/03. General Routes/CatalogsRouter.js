CatalogsRouter = AppRouter.extend({
	template: 'catalogs',

	before: function() {
		var catalog;
		this.subscribe('MunkiCatalogs').wait();
		SelectedCatalogItems.remove({});
		if (this.params.urlName) {
			catalog = MunkiCatalogs.findOne({urlName: this.params.urlName});
			if (catalog && catalog.dom) {
				for(var i = 0; i < catalog.dom.length; i++) {
					SelectedCatalogItems.insert({
						name: catalog.dom[i].name,
						display_name: catalog.dom[i].display_name,
						version: catalog.dom[i].version
					});
				}
			}
		}
	},
	
	data: function () {
		// If an ID was passed, the data passed to the template will consist
		// of the single matching record. If not, the template will get
		// all records.
		if (this.params.urlName) {
			return {
				urlName: this.params.urlName,
				items: SelectedCatalogItems.find({}, {
					sort: {
						name: 1,
						display_name: 1,
						version: 1
					}
				}).fetch()
			};
		}
		else {
			return {catalogs: MunkiCatalogs.find({}, {
				sort: {
					err: -1,
					urlName: 1
				}
			}).fetch()};
		}
	},


	unload: function() {
		SelectedCatalogItems.remove({});
	}
});