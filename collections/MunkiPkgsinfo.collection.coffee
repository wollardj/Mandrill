@MunkiPkgsinfo = new Meteor.Collection 'munki_pkgsinfo'

#// disallow all interaction from the client. We want the client to use a
#// Meteor method to interact with these records so we can deal with the
#// filesytem and the database at the same time.

MunkiPkgsinfo.allow {
	'insert': ->
		false
	'update': ->
		false
	'remove': ->
		false
}