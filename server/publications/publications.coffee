Meteor.publish 'MandrillSettings', ->
	if Mandrill.user.isValid(this.userId) is true
		MandrillSettings.find()
	else
		[]


Meteor.publish 'MunkiRepo', (query, opts)->
	filter = Mandrill.user.accessPatternsFilter this.userId, query
	opts = if not opts then {} else opts
	if not opts.fields
		# omit the raw text of the file by default since that can grow to be
		# rather large.
		opts.fields = {
			raw: false
		}
	MunkiRepo.find filter, opts

Meteor.publish 'ServerStats', ->
	ServerStats.find {}, {sort: {collectedDate: -1}}


# If the user is an admin, they should have access to all the users
Meteor.publish 'MandrillAccounts', ->
	query = {}
	fields = {
		'username': 1
		'mandrill': 1
		'emails': 1
	}

	if Mandrill.user.isAdmin(this.userId) is true
		fields.services = 1
		fields.profile = 1

	else
		query._id = this.userId

	Meteor.users.find query, {fields: fields}







# Each of the methods defined in this file return a count for
# the respective collection.

Meteor.publish 'MandrillStats', ->

	self = this
	collection = 'mandrill_stats'
	fields = {fields: {_id: 1}}
	filter = Mandrill.user.accessPatternsFilter self.userId
	munki_repo_count = 0
	initializing = true
	handles = []


	# MunkiRepo
	handles[0] = MunkiRepo.find(filter, fields).observeChanges {
		added: ->
			munki_repo_count++
			if initializing is false
				self.changed collection, 'munki_repo', {count: munki_repo_count}

		removed: ->
			munki_repo_count--
			self.changed collection, 'munki_repo', {count: munki_repo_count}
	}


	initializing = false
	self.added collection, 'munki_repo', {count: munki_repo_count}
	self.ready()

	self.onStop ->
		for handle in handles
			if handle? and handle.stop?
				handle.stop()
