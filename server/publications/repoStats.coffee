# Each of the methods defined in this file return a count for
# the respective collection.

Meteor.publish 'repoStats', ->

	self = this
	collection = 'repoStats'
	fields = {fields: {_id: 1}}
	filter = Mandrill.user.accessPatternsFilter self.userId
	errFilter = Mandrill.user.accessPatternsFilter(
		self.userId
		{'err': {'$exists': true}}
	)
	mCount = 0
	meCount = 0
	cCount = 0
	ceCount = 0
	pCount = 0
	peCount = 0
	initializing = true
	handles = []


	# Manifests
	handles[0] = MunkiManifests.find(filter, fields).observeChanges {
		added: ->
			mCount++
			if initializing is false
				self.changed collection, 'manifests', {count: mCount}

		removed: ->
			mCount--
			self.changed collection, 'manifests', {count: mCount}
	}


	# Manifest errors
	handles[1] = MunkiManifests.find(errFilter, fields).observeChanges {
		added: ->
			meCount++
			if initializing is false
				self.changed collection, 'manifestErrors', {count: meCount}

		removed: ->
			meCount--
			self.changed collection, 'manifestErrors', {count: meCount}
	}


	# Pkgsinfo
	handles[2] = MunkiPkgsinfo.find(filter, fields).observeChanges {
		added: ->
			pCount++
			if initializing is false
				self.changed collection, 'pkgsinfo', {count: pCount}

		removed: ->
			pCount--
			self.changed collection, 'pkgsinfo', {count: pCount}
	}


	# Pkgsinfo Errors
	handles[3] = MunkiPkgsinfo.find(errFilter, fields).observeChanges {
		added: ->
			peCount++
			if initializing is false
				self.changed collection, 'pkgsinfoErrors', {count: peCount}

		removed: ->
			peCount--
			self.changed collection, 'pkgsinfoErrors', {count: peCount}
	}


	# Catalogs
	handles[4] = MunkiCatalogs.find(filter, fields).observeChanges {
		added: ->
			cCount++
			if initializing is false
				self.changed collection, 'catalogs', {count: cCount}

		removed: ->
			cCount--
			self.changed collection, 'catalogs', {count: cCount}
	}


	# Catalog Errors
	handles[5] = MunkiCatalogs.find(errFilter, fields).observeChanges {
		added: ->
			ceCount++
			if initializing is false
				self.changed collection, 'catalogErrors', {count: ceCount}

		removed: ->
			ceCount--
			self.changed collection, 'catalogErrors', {count: ceCount}
	}

	initializing = false
	self.added collection, 'manifests', {count: mCount}
	self.added collection, 'manifestErrors', {count: meCount}
	self.added collection, 'catalogs', {count: cCount}
	self.added collection, 'catalogErrors', {count: ceCount}
	self.added collection, 'pkgsinfo', {count: pCount}
	self.added collection, 'pkgsinfoErrors', {count: peCount}
	self.ready()

	self.onStop ->
		for handle in handles
			if handle? and handle.stop?
				handle.stop()