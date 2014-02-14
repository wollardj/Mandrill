MunkiManifests = new Meteor.Collection('munki_manifests');

// disallow all interaction from the client. We want the client to use a
// Meteor method to interact with these records so we can deal with the
// filesytem and the database at the same time.

MunkiManifests.allow({
	'insert': function() {return false;},
	'update': function() {return false;},
	'remove': function() {return false;}
});