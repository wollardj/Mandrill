@MunkiCatalogs = new Meteor.Collection 'munki_catalogs'


MunkiCatalogs.allow {
	'insert': ->
		false
	'update': ->
		false
	'remove': ->
		false
}