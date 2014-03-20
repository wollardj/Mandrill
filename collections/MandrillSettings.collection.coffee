@MandrillSettings = new Meteor.Collection 'mandrill-settings'


MandrillSettings.allow {
	'insert': (userId) ->
		Mandrill.user.isAdmin userId
	'update': (userId)->
		Mandrill.user.isAdmin userId
	'remove': (userId)->
		Mandrill.user.isAdmin userId
}