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

		value = $('#gitIsEnabled').is ':checked'
		MandrillSettings.set 'gitIsEnabled', value

		if value is true
			#// initialize the repo if needed.
			Meteor.call 'git-init'


	'change #gitBinaryPath': (event)->
		event.stopPropagation()
		event.preventDefault()

		MandrillSettings.set 'gitBinaryPath', $('#gitBinaryPath').val()


	'change #makeCatalogsIsEnabled': (event)->
		event.stopPropagation()
		event.preventDefault()

		value = $('#makeCatalogsIsEnabled').is ':checked'
		MandrillSettings.set 'makeCatalogsIsEnabled', value

		if value is true
			#// initialize the repo if needed.
			Meteor.call 'git-init'


	'change #makeCatalogsSanityIsDisabled': (event)->
		event.stopPropagation()
		event.preventDefault()

		value = $('#makeCatalogsSanityIsDisabled').is ':checked'
		MandrillSettings.set 'makeCatalogsSanityIsDisabled', value

		if value is true
			#// initialize the repo if needed.
			Meteor.call 'git-init'


	'change #munkiRepoPath': (event)->
		event.stopPropagation()
		event.preventDefault()

		value = $('#munkiRepoPath').val()

		#// Make sure the path has a trailing '/'
		if /\/$/.test(value) is false
			value += '/'
			$('#munkiRepoPath').val value

		MandrillSettings.set 'munkiRepoPath', value

		Meteor.call 'updateWatchr'

		# https://github.com/wollardj/Mandrill/issues/7
		if MandrillSettings.get('gitIsEnabled') is true
			Meteor.call 'git-init'


	'click #makecatalogs': (event)->
		event.stopPropagation()
		event.preventDefault()
		Session.set 'runningMakeCatalogs', true
		Meteor.call 'runMakeCatalogs', (err, data)->
			Session.set 'runningMakeCatalogs', false
			if err?
				Mandrill.show.error err
			else
				Mandrill.show.success 'Processed ' + data.logs.length + ' files',
					' Found ' + data.errors.length + ' warnings or errors.' +
					' Open your browser console to view the output.'
				for log in data.logs
					console.log log
				for error in data.errors
					console.warn error


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