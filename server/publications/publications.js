//// publish functions ////

Meteor.publish('PaginatedQueryStats', function() {
	return PaginatedQueryStats.find();
});


Meteor.publish('OtherTools', function() {
	if (Mandrill.user.isValid(this.userId)) {
		return OtherTools.find();
	}
	return [];
});


Meteor.publish('Paths', function() {
	if (Mandrill.user.isValid(this.userId)) {
		return Paths.find();
	}
	return [];
});


Meteor.publish('MandrillSettings', function() {
	if (Mandrill.user.isValid(this.userId)) {
		return MandrillSettings.find();
	}
	return [];
});


Meteor.publish('MunkiManifests', function(query, opts, tryRegexp) {
	var queryObj,
		filter;
	if (query && tryRegexp === true) {
		try {
			queryObj = new RegExp(query, 'i');
		}
		catch(e) {
			queryObj = query;
		}
		query = {'$or': [
			{raw: queryObj},
			{urlName: queryObj}
		]};
	}
	
	filter = Mandrill.user.accessPatternsFilter(this.userId, query);
	PaginatedQueryStats.upsert({}, {
		total: MunkiManifests.find(filter, opts).count()
	});
	return MunkiManifests.find(filter, opts);
});


Meteor.publish('MunkiPkgsinfo', function(query, opts, tryRegexp) {
	var queryObj,
		filter;
	
	if (query && tryRegexp === true) {
		try {
			queryObj = new RegExp(query, 'i');
		}
		catch(e) {
			queryObj = query;
		}
		query = {'$or': [
			{raw: queryObj},
			{urlName: queryObj}
		]};
	}

	filter = Mandrill.user.accessPatternsFilter(this.userId, query);
	PaginatedQueryStats.upsert({}, {
		total: MunkiPkgsinfo.find(filter, opts).count()
	});
	return MunkiPkgsinfo.find(filter, opts);
});


Meteor.publish('MunkiCatalogs', function() {
	var filter = Mandrill.user.accessPatternsFilter(this.userId);
	return MunkiCatalogs.find(filter);
});


Meteor.publish('ServerStats', function() {
	return ServerStats.find({}, {sort: {collectedDate: -1}});
});


// If the user is an admin, they should have access to all the users
Meteor.publish('MandrillAccounts', function() {
	var query = {},
		fields = {
			'username': 1,
			'mandrill': 1,
			'emails': 1
		};
	if (Mandrill.user.isAdmin(this.userId) === true) {
		fields.services = 1;
		fields.profile = 1;
	}
	else {
		query._id = this.userId;
	}
	
	return Meteor.users.find(query, {fields: fields});
});