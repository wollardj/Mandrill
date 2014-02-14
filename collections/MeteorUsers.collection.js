/*
	There is no collection defined here because it's already been defined
	by the Meteor framework. Instead, we're just modifying the ACLs to allow
	admins to mutate everyone's records instead of just their own, which is
	the default behavior.
 */

// Allow admins to modify user records
Meteor.users.allow({
	'insert': function(userId) {
		return Mandrill.user.isAdmin(userId);
	},

	// Makes sure you don't add an email address to a record
	// where that email address already exists in another.
	'update': function(userId, doc) {
		var emails = [],
			query = {'$and': {}, '$not': {}};

		for(var i = 0; i < doc.emails.length; i++) {
			emails.push(doc.emails.address);
		}

		query.$and['email.address'] = {'$in': emails};
		query.$not = {_id: doc._id};
		
		if (Meteor.users.findOne(query)) {
			throw new Meteor.Error(403, 'One or more email addresses ' +
				'entered are already in use by another account.'
			);
		}

		return true;
	},


	'remove': function(userId) {
		return Mandrill.user.isAdmin(userId);
	}
});