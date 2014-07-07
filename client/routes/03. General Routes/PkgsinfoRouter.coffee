@PkgsinfoRouter = AppRouter.extend {
	template: 'pkgsinfo',

	onBeforeAction: ->
		query = {}
		userQuery = {}
		perPage = 25
		selectedCatalogs = Session.get 'listOfSelectedCatalogs'
		catalogs = Session.get 'listOfCatalogs'
		opts = {
			'sort': {
				'err': -1,
				'dom.name': 1,
				'dom.version': 1,
				'path': 1
			},
			'limit': perPage,
			'fields': {
				'path': 1,
				'err': 1,
				'urlName': 1,
				'dom.name': 1,
				'dom.version': 1,
				'dom.display_name': 1,
				'dom.catalogs': 1
			}
		}
		

		if this.params.urlName?
			query = {urlName: this.params.urlName}
			opts.limit = 1
			opts.fields.raw = 1	
			#// Change the template to render if it looks like the user
			#// is trying to edit a specific pkgsinfo item.
			this.template = 'pkgsinfoEditor'

		else
			if this.params.p?
				opts.skip = this.params.p * perPage

			if this.params.q?
				userQuery.$or = []
				try
					new RegExp(this.params.q)
					re = {'$regex': this.params.q, '$options': 'i'}
					userQuery.$or.push {raw: re}
					userQuery.$or.push {urlName: re}
				catch e
					userQuery.$or.push {raw: this.params.q}
					userQuery.$or.push {urlName: this.params.q}

			if selectedCatalogs? and catalogs? and selectedCatalogs.length isnt catalogs.length
				query.$and = if not query.$and then [] else query.$and
				query.$and.push {'dom.catalogs': {'$in': selectedCatalogs}}

			if userQuery.$or?
				query.$and = if not query.$and then [] else query.$and
				query.$and.push userQuery

		
		this.subscribe 'MunkiPkgsInfo', query, opts
				.wait()

		if not this.params.urlName?
			this.subscribe 'PaginatedQueryStats'
				.wait()


	data: ->

		if this.params.urlName?
			MunkiPkgsinfo.findOne {urlName: this.params.urlName}
		else
			stats = PaginatedQueryStats.findOne()
			{
				pkgsinfo: MunkiPkgsinfo.find {}, {
						'sort': {
							'err': -1,
							'dom.name': 1,
							'dom.version': 1,
							'path': 1
						}
					}
					.fetch(),
				unlimitedTotal: if stats? and stats.total then stats.total else 0
			}
}