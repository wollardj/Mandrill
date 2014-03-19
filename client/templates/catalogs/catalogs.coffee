Template.catalogs.itemCount = ->
	if not this.err and this.dom
		this.dom.length
	else
		'??'



Template.catalogs.referringManifestsCount = ->
	urlName = this.urlName
	record = ManifestsUsingCatalogs.findOne {catalog: urlName}
	sessKey = 'fetchingManifestCountFor' + urlName
	Session.setDefault sessKey, false
	
	if not record
		Session.set 'fetchingManifestCountFor' + urlName, true
		Meteor.call(
			'manifestCountForCatalog',
			urlName,
			(err, data)->
				Session.set 'fetchingManifestCountFor' + urlName, false
				ManifestsUsingCatalogs.upsert({catalog: urlName},
					{catalog: urlName, count: data}
				)
		)
	if record then record.count else 0



Template.catalogs.manifestsSearchLink = ->
	Router.path('manifests', null, {query:
		{q: '>' + this.urlName + '<'}
	})


Template.catalogs.fetchingManifestCount = ->
	Session.get 'fetchingManifestCountFor' + this.urlName


Template.catalogs.events {
	'click tr.catalogItemRow': ->
		Meteor.call('urlNameForPkginfo', this.name, this.version,
			(err, urlName)->
				if err?
					Mandrill.show.errorerr
				else
					Router.go 'pkgsinfo', {urlName: urlName}
		)
}