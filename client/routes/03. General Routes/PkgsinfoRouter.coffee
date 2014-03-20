@PkgsinfoRouter = AppRouter.extend {
	template: 'pkgsinfo',

	onBeforeAction: ->
		query = {}
		perPage = 25
		useRegex = this.params.urlName?
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

		else if this.params.p?
			query = this.params.q
			opts.skip = this.params.p * perPage

		
		this.subscribe 'MunkiPkgsinfo', query, opts, useRegex
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