ServerStats = new Meteor.Collection('serverstats');

// This data is populated by the server. There's no reason for the client to
// do anything with it other than read it.

ServerStats.allow({
	'insert': function() {return false;},
	'update': function() {return false;},
	'remove': function() {return false;}
});