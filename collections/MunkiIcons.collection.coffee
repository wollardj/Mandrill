@MunkiIcons = new Meteor.Collection 'munki_icons'


MunkiIcons.allow {
	'insert': ->
		false
	'update': ->
		false
	'remove': ->
		false
}