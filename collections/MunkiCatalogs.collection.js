MunkiCatalogs = new Meteor.Collection('munki_catalogs');


MunkiCatalogs.allow({
	'insert': function() {return false;},
	'update': function() {return false;},
	'remove': function() {return false;}
});