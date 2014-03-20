Template.pkgsinfo.rendered = ->
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
	if $('#pkgsinfo-search').val() is '' and Router.current().params.q?
		$('#pkgsinfo-search').val Router.current().params.q



Template.pkgsinfo.relativePath = ->
	settings = MandrillSettings.findOne()
	if not settings.munkiRepoPath and this.path?
		this.path
	
	else if this.path?
		this.path.replace settings.munkiRepoPath + 'pkgsinfo/', ''
	else
		'??'



Template.pkgsinfo.basePath = ->
	settings = MandrillSettings.findOne()
	if settings? and settings.munkiRepoPath?
		settings.munkiRepoPath
	else
		'/'




Template.pkgsinfo.catalogLabels = ->
	catalogs = this.dom.catalogs or []
	labels = ''

	for catalog in catalogs
		labels += '<span class="label '
		if /^prod/.test(catalog) is true
			labels += 'label-success'
		else if /^(dev|test)/.test(catalog) is true
			labels += 'label-warning'
		else if /^(problem|broke|issue)/.test(catalog) is true
			labels += 'label-danger'
		else
			labels += 'label-info'
		labels += '">' + catalog + '</span> '
	
	new Handlebars.SafeString labels



Template.pkgsinfo.events {
	'submit form': (event)->
		event.stopPropagation()
		event.preventDefault()


	'keyup #pkgsinfo-search': ()->
		oldQuery = Router.current().params.q or ''
		query = $('#pkgsinfo-search').val()

		#// A little clearTimeout/setTimeout magic to only submit
		#// the search after the user has stopped typing for 250ms.
		window.clearTimeout window.pkgsinfoSearchTimer
		window.pkgsinfoSearchTimer = window.setTimeout ->
			if oldQuery isnt query and query isnt ''
				Router.go 'pkgsinfo', {}, {'query': {'q': query}}
			else if oldQuery isnt query
				Router.go 'pkgsinfo'
		250


	'change #catalogFilter': (event)->
		query = Router.current().params.q or ''
		params = {}
		catalog = $(event.target).val()

		if query isnt ''
			params.q = query

		if catalog isnt 'all'
			params.c = catalog

		Router.go 'pkgsinfo', {}, {'query': params}


	'click tr.pkgsinfo-item-row': ->
		if this.urlName?
			Router.go 'pkgsinfo', {urlName: this.urlName}
		else
			Mandrill.show.error(new Meteor.Error('-1',
				'Couldn\'t figure out which pkginfo file represents "' +
				this.dom.name + '"'))


	#// Add a new pkginfo file.
	'submit #pkginfoNameForm': (event)->
		event.stopPropagation()
		event.preventDefault()

		settings = MandrillSettings.findOne()
		
		if settings? and settings.munkiRepoPath?
			Meteor.call(
				'createPkginfo',
				settings.munkiRepoPath + 'pkgsinfo/' +
					$('#pkginfoName').val(),
				(err, data)->
					if err?
						Mandrill.show.error err
					else
						Router.go(
							'pkgsinfo',
							{},
							{query: {q: data.urlName}}
						)
			)
		else
			Mandrill.show.error(new Meteor.Error(500,
				'Path to munki_repo has not been set.'))


	#// Display the new pkginfo form
	'click #newPkginfo': (event)->
		event.preventDefault()
		event.stopPropagation()
		$('#newPkginfoForm').toggleClass 'newPkginfoFormClosed'
		if $('#newPkginfoForm').hasClass 'newPkginfoFormClosed'
			$('#pkginfoName').blur()
		else
			$('#pkginfoName').focus()


	#// Hide the new pkginfo form if the user presses the esc key
	'keyup #pkginfoName': (event)->
		if event.which is 27
			$('#newPkginfoForm').addClass 'newPkginfoFormClosed'
			$('#pkginfoName').blur()
}