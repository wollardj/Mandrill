@ManifestsRouter = AppRouter.extend {

	template: 'manifests',

	onBeforeAction: ->
		query = {}
		perPage = 25
		useRegexp = true
		opts = {
			sort: {
				err: -1
				path: 1
			}
			limit: perPage
			fields: {
				path: 1
				err: 1
				urlName: 1
			}
		}


		if this.params.urlName?
			query = {urlName: this.params.urlName}

			#// also change the template since we're supposed to be editing
			#// a single manifest in this case.
			opts.limit = 1
			opts.fields.raw = 1
			useRegexp = false
			this.template = 'manifestEditor'
		else

			if this.params.p?
				opts.skip = this.params.p * perPage

			if this.params.q?
				query.$or = []
				try
					new RegExp(this.params.q)
					re = {'$regex': this.params.q, '$options': 'i'}
					query.$or.push {raw: re}
					query.$or.push {urlName: re}
				catch e
					query.$or.push {raw: this.params.q}
					query.$or.push {urlName: this.params.q}



		this.subscribe 'MunkiManifests', query, opts
			.wait()

		if not this.params.urlName?
			this.subscribe 'PaginatedQueryStats'
				.wait()

	data: ->
		if this.params.urlName?
			MunkiManifests.findOne({urlName: this.params.urlName})

		else
			stats = PaginatedQueryStats.findOne()
			total = if stats? and stats.total? then stats.total else 0

			{
				manifests: MunkiManifests.find {}, {
						sort: {err: -1, urlName: 1}
					}
					.fetch(),
				unlimitedTotal: total
			}
}