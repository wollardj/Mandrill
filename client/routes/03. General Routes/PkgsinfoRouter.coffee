@PkgsinfoRouter = AppRouter.extend {
	template: 'pkgsinfo',

	onBeforeAction: ->
		query = {}
		perPage = 25
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
			query = this.params.q

		if this.params.p?
			opts.skip = this.params.p * perPage

		if this.params.urlName?
			this.subscribe 'MunkiPkgsinfo', query, opts, false
				.wait()
		else
			this.subscribe 'MunkiPkgsinfo', query, opts, true
			this.subscribe 'PaginatedQueryStats'
				.wait()


	data: ->

		if this.params.urlName?
			MunkiPkgsinfo.findOne()
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