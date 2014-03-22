Meteor.publish 'PaginatedQueryStats', ->
	PaginatedQueryStats.find()


Meteor.publish 'OtherTools', ->
	if Mandrill.user.isValid(this.userId)
		OtherTools.find()
	else
		[]


Meteor.publish 'Paths', ->
	if Mandrill.user.isValid(this.userId)
		Paths.find()
	else
		[]


Meteor.publish 'MandrillSettings', ->
	if Mandrill.user.isValid(this.userId)
		MandrillSettings.find()
	else
		[]


Meteor.publish 'MunkiManifests', (query, opts, tryRegexp)->

	if query? amd tryRegexp is true
		try
			queryObj = new RegExp query, 'i'
		catch e
			queryObj = query

		query = {'$or': [
			{raw: queryObj},
			{urlName: queryObj}
		]}
	
	filter = Mandrill.user.accessPatternsFilter this.userId, query
	PaginatedQueryStats.upsert {}, {
		total: MunkiManifests.find(filter, opts).count()
	}
	
	MunkiManifests.find filter, opts



Meteor.publish 'MunkiPkgsinfo', (query, opts)->

	filter = Mandrill.user.accessPatternsFilter this.userId, query
	PaginatedQueryStats.upsert {}, {
		total: MunkiPkgsinfo.find(filter, opts).count()
	}
	MunkiPkgsinfo.find filter, opts


Meteor.publish 'MunkiCatalogs', ->
	filter = Mandrill.user.accessPatternsFilter this.userId
	MunkiCatalogs.find filter


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