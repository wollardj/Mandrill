PaginatedQueryStats = new Meteor.Collection('paginatedQueryStats');


// This is populated automatically on the server-side. There's never a reason
// for the client to do anything with this data other than read it.

PaginatedQueryStats.allow({
	'insert': function() {return false;},
	'update': function() {return false;},
	'remove': function() {return false;}
});