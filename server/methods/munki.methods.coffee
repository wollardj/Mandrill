Meteor.methods {
	'getRawRepoItemContent': (_id)->
		patterns = Mandrill.user.accessPatternsFilter this.userId, {_id: _id}
		item = MunkiRepo.findOne patterns
		if item?.raw? and item?.stat.size > 0
			item.raw
		else if item?.stat.size is 0
			''
		else
			false


	'runMakeCatalogs': ->
		insane = MandrillSettings.get 'makeCatalogsSanityIsDisabled', false
		partyMode = MandrillSettings.get 'makeCatalogsIsEnabled', false
		isAdmin = Mandrill.user.isAdmin this.userId
		canMakecatalogs = isAdmin is true or partyMode is true


		if canMakecatalogs is false
			throw new Meteor.Error 403, 'You do not have permission to run makecatalogs'

		Munki.makeCatalogs(insane)
}
