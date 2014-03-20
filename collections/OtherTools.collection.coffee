@OtherTools = new Meteor.Collection 'othertools'

OtherTools.allow {
	'insert': (userId)->
		Mandrill.user.isAdmin userId

	'update': (userId)->
		Mandrill.user.isAdmin userId

	'remove': (userId)->
		Mandrill.user.isAdmin userId
}