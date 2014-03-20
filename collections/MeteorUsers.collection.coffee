#/*
#	There is no collection defined here because it's already been defined
#	by the Meteor framework. Instead, we're just modifying the ACLs to allow
#	admins to mutate everyone's records instead of just their own, which is
#	the default behavior.
#*/

#// Allow admins to modify user records
Meteor.users.allow {
	'insert': (userId)->
		Mandrill.user.isAdmin userId

	#// Makes sure you don't add an email address to a record
	#// where that email address already exists in another.
	'update': (userId, doc)->
		emails = []
		query = {'$and': {}, '$not': {}}

		emails.push email.address for email in doc.emails

		query.$and['email.address'] = {'$in': emails}
		query.$not = {_id: doc._id}
		
		if Meteor.users.findOnequery
			throw new Meteor.Error(403, 'One or more email addresses ' +
				'entered are already in use by another account.'
			);

		true


	'remove': (userId)->
		Mandrill.user.isAdmin userId
}