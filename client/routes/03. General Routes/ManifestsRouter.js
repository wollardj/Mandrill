/*
	Handles the "/manifests" routes
 */
ManifestsRouter = AppRouter.extend({

	template: 'manifests',

	before: function() {
		var query = {},
			perPage = 25,
			useRegexp = true,
			opts = {
				sort: {err: -1, path: 1},
				limit: perPage,
				fields: {path: 1, err: 1, urlName: 1}
			};
		if (this.params.urlName) {
			query = {urlName: this.params.urlName};

			// also change the template since we're supposed to be editing
			// a single manifest in this case.
			opts.limit = 1;
			opts.fields.raw = 1;
			useRegexp = false;
			this.template = 'manifestEditor';
		}
		else {
			query = this.params.q;
		}
		
		if (this.params.p) {
			opts.skip = this.params.p * perPage;
		}

		if (this.params.urlName) {
			this.subscribe('MunkiManifests', query, opts, useRegexp).wait();
		}
		else {
			this.subscribe('MunkiManifests', query, opts, useRegexp);
			this.subscribe('PaginatedQueryStats').wait();
		}
	},

	data: function() {
		var total;
		if (this.params.urlName) {
			return MunkiManifests.findOne();
		}
		total = PaginatedQueryStats.findOne().total || 0;
		return {
			manifests: MunkiManifests.find({}, {
				sort: {err: -1, urlName: 1}
			}).fetch(),
			unlimitedTotal: total
		};
	}
});