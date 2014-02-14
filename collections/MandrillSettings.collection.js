MandrillSettings = new Meteor.Collection('mandrill-settings');


MandrillSettings.allow({
	'insert': function(userId) {return Mandrill.user.isAdmin(userId);},
	'update': function(userId) {return Mandrill.user.isAdmin(userId);},
	'remove': function(userId) {return Mandrill.user.isAdmin(userId);}
})