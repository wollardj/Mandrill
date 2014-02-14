Meteor.methods({
	'manifestCountForCatalog': function(catalog) {
		return MunkiManifests.find(
			{'raw': new RegExp('>' + catalog + '<', 'i')},
			{fields: {_id: 1}}
		).count();
	}
});