Template.catalogs.itemCount = function() {
	if (!this.err && this.dom) {
		return this.dom.length;
	}
	return '??';
};



Template.catalogs.referringManifestsCount = function() {
	var urlName = this.urlName,
		record = ManifestsUsingCatalogs.findOne({catalog: urlName}),
		sessKey = 'fetchingManifestCountFor' + urlName;
	Session.setDefault(sessKey, false);
	if (!record) {
		Session.set('fetchingManifestCountFor' + urlName, true);
		Meteor.call(
			'manifestCountForCatalog',
			urlName,
			function(err, data) {
				Session.set('fetchingManifestCountFor' + urlName, false);
				ManifestsUsingCatalogs.upsert({catalog: urlName},
					{catalog: urlName, count: data}
				);
			}
		);
	}
	return record ? record.count : 0;
};



Template.catalogs.manifestsSearchLink = function() {
	return Router.path('manifests', null, {query:
		{q: '>' + this.urlName + '<'}
	});
};


Template.catalogs.fetchingManifestCount = function() {
	return Session.get('fetchingManifestCountFor' + this.urlName);
};




Template.catalogs.events({
	'click tr.catalogItemRow': function() {
		Meteor.call('urlNameForPkginfo', this.name, this.version,
			function(err, urlName) {
				if (err) {
					Mandrill.show.error(err);
				}
				else {
					Router.go('pkgsinfo', {urlName: urlName});
				}
			}
		);
	}
});