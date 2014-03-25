Template.manifests.rendered = ->
	console.log 'manifests has been rendered'
	headerBottom = $('.mandrill-header').outerHeight()
	$('.paging-toolbar').affix {
		offset: { top: headerBottom }
	}


	if $(window).scrollTop() >= headerBottom
		#// Bring the header below the trigger point for bootstrap's affix
		window.scrollTo 0, headerBottom

		#// Wait 1ms before scrolling 1px above the affix trigger so
		#// the drop shadow will appear. 1ms because we want to give
		#// the affix plugin time to respond to the previous scroll event.
		window.setTimeout ->
			window.scrollTo 0, headerBottom + 1
		1

	#// Let's also set the initial value of the search box, _if_
	#// it doesn't already have something in it.
	if $('#manifest-search').val() is '' and Router.current().params.q?
		$('#manifest-search').val Router.current().params.q



Template.manifests.basePath = ->
	MandrillSettings.get 'munkiRepoPath', '/'



Template.manifests.relativePath = ->
	repoPath = MandrillSettings.get 'munkiRepoPath'
	if repoPath?
		this.path.replace repoPath + 'manifests/', ''
	else
		this.path



Template.manifests.events {
	'submit #searchForm': (event)->
		event.stopPropagation()
		event.preventDefault()


	'keyup #manifest-search': ->
		oldQuery = if Router.current().params.q? then Router.current().params.q else ''
		query = $('#manifest-search').val()

		#// A little clearTimeout/setTimeout magic to only submit
		#// the search after the user has stopped typing for 250ms.
		window.clearTimeout window.manifestsSearchTimer
		window.manifestsSearchTimer = window.setTimeout ->
			if oldQuery isnt query and query isnt ''
				Router.go 'manifests', {}, {'query': {'q': query}}
			else if oldQuery isnt query
				Router.go 'manifests'
		250




	'click tr.manifest-item-row': ->
		if this.urlName?
			Router.go 'manifests', {urlName: this.urlName}
		else
			Mandrill.show.error( new Meteor.Error('-1',
				'Couldn\'t figure out which manifest file represents "' +
				this.dom.name + '"'))




	'submit #manifestNameForm': (event)->
		event.stopPropagation()
		event.preventDefault()

		repoPath = MandrillSettings.get 'munkiRepoPath'
		
		if repoPath?
			Meteor.call(
				'createManifest'
				repoPath + 'manifests/' + $('#manifestName').val()
				(err, data)->
					if err?
						Mandrill.show.error err
					else
						$('#newManifestForm').addClass 'newManifestFormClosed'
						$('#manifestName').blur()
						Router.go(
							'manifests'
							{urlName: data.urlName}
							
						)
			)
		else
			Mandrill.show.error(new Meteor.Error(500,
				'Path to munki_repo has not been set.'))


	#// Display the new manifest form
	'click #newManifest': (event)->
		event.preventDefault()
		event.stopPropagation()
		$('#newManifestForm').toggleClass 'newManifestFormClosed'
		if $('#newManifestForm').hasClass 'newManifestFormClosed'
			$('#manifestName').blur()
		else
			$('#manifestName').focus()


	#// Hide the new manifest form if the user presses the esc key
	'keyup #manifestName': (event)->
		if event.which is 27
			$('#newManifestForm').addClass 'newManifestFormClosed'
			$('#manifestName').blur()
}