Session.setDefault 'runningMakeCatalogs', false

Template.mandrillSettings.munkiRepoPathClass = ->
	settings = Router.current().data().settings
	if settings.munkiRepoPathIsValid is true
		'has-success'
	else
		'has-error'


Template.mandrillSettings.makecatalogsIsChecked = ->
	if this.settings.makeCatalogsIsEnabled is true then 'checked'


Template.mandrillSettings.makecatalogsDisableSanityIsChecked = ->
	if this.settings.makeCatalogsSanityIsDisabled is true then 'checked'


Template.mandrillSettings.gitIsChecked = ->
	if this.settings.gitIsEnabled is true then 'checked'


Template.mandrillSettings.munkiRepoPathFeedbackIcon = ->
	settings = Router.current().data().settings
	if settings.munkiRepoPathIsValid is true
		'ok'
	else
		'warning-sign'


Template.mandrillSettings.runningMakeCatalogs = ->
	Session.get 'runningMakeCatalogs'


Template.mandrillSettings.events {
	'change #gitIsEnabled': (event)->
		event.stopPropagation()
		event.preventDefault()

		settings = MandrillSettings.findOne()
		value = $('#gitIsEnabled').is ':checked'

		MandrillSettings.update {_id: settings._id}, {
			'$set': {'gitIsEnabled': value}
		}

		if value is true
			#// initialize the repo if needed.
			Meteor.call 'git-init'


	'change #gitBinaryPath': (event)->
		event.stopPropagation()
		event.preventDefault()

		settings = MandrillSettings.findOne()

		MandrillSettings.update {_id: settings._id}, {
			'$set': {'gitBinaryPath': $('#gitBinaryPath').val()}
		}

	'change #makeCatalogsIsEnabled': (event)->
		event.stopPropagation()
		event.preventDefault()

		settings = MandrillSettings.findOne()
		value = $('#makeCatalogsIsEnabled').is ':checked'

		MandrillSettings.update {_id: settings._id}, {
			'$set': {'makeCatalogsIsEnabled': value}
		}

		if value is true
			#// initialize the repo if needed.
			Meteor.call 'git-init'


	'change #makeCatalogsSanityIsDisabled': (event)->
		event.stopPropagation()
		event.preventDefault()

		settings = MandrillSettings.findOne()
		value = $('#makeCatalogsSanityIsDisabled').is ':checked'

		MandrillSettings.update {_id: settings._id}, {
			'$set': {'makeCatalogsSanityIsDisabled': value}
		}

		if value is true
			#// initialize the repo if needed.
			Meteor.call 'git-init'


	'change #munkiRepoPath': (event)->
		event.stopPropagation()
		event.preventDefault()

		settings = MandrillSettings.findOne()
		value = $('#munkiRepoPath').val()

		#// Make sure the path has a trailing '/'
		if /\/$/.test(value) is false
			value += '/'
			$('#munkiRepoPath').val value

		MandrillSettings.update {_id: settings._id}, {
			'$set': {'munkiRepoPath': value}
		}

		Meteor.call 'updateWatchr'

		# https://github.com/wollardj/Mandrill/issues/7
		if settings? and settings.gitIsEnabled is true
			Meteor.call 'git-init'


	'click #makecatalogs': (event)->
		event.stopPropagation()
		event.preventDefault()
		Session.set 'runningMakeCatalogs', true
		Meteor.call 'runMakeCatalogs', (err, data)->
			Session.set 'runningMakeCatalogs', false
			if err?
				Mandrill.show.error err


	'click #rebuildCaches': (event)->
		event.stopPropagation()
		event.preventDefault()
		confirmMsg = 'During this process, all users will see zero ' +
			'manifests, pkgsinfo, and catalogs. Are you sure you want to do ' +
			'this right now?';
		if confirm(confirmMsg) is true
			Meteor.call 'updateWatchr', (err, data)->
				if err?
					Mandrill.show.error err
		$(event.target).blur()
}