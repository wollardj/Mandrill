Template.pkgsinfo.created = ->
	Session.setDefault 'listOfCatalogs', []
	Session.setDefault 'listOfSelectedCatalogs', []


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
	repoPath = MandrillSettings.get 'munkiRepoPath'
	if not repoPath and this.path?
		this.path
	
	else if this.path?
		this.path.replace repoPath + 'pkgsinfo/', ''
	else
		'??'



Template.pkgsinfo.basePath = ->
	MandrillSettings.get 'munkiRepoPath', '/'



Template.pkgsinfo.isCatalogSelected = ->
	selectedCatalogs = Session.get 'listOfSelectedCatalogs'
	if selectedCatalogs.indexOf(this.toString()) > -1
		'check'
	else
		'unchecked'



Template.pkgsinfo.catalogBtnState = ->
	catalogs = Session.get 'listOfCatalogs'
	selectedCatalogs = Session.get 'listOfSelectedCatalogs'
	if catalogs.length isnt selectedCatalogs.length
		'primary'
	else
		'default'



Template.pkgsinfo.liveCatalogs = ->
	Meteor.call 'listCatalogs', (err, data) ->
		if err?
			Mandrill.show.error err
		else
			Session.set 'listOfCatalogs', data

			# pre-select all catalogs
			if Session.get('listOfSelectedCatalogs').length is 0
				Session.set 'listOfSelectedCatalogs', data
	Session.get 'listOfCatalogs'



Template.pkgsinfo.catalogLabels = (catalogs)->
	catalogs = catalogs or this.dom.catalogs or []
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

		repoPath = MandrillSettings.get 'munkiRepoPath'
		
		if repoPath?
			Meteor.call(
				'createPkginfo'
				repoPath + 'pkgsinfo/' + $('#pkginfoName').val()
				(err, data)->
					if err?
						Mandrill.show.error err
					else
						$('#newPkginfoForm').addClass 'newPkginfoFormClosed'
						$('#pkginfoName').blur()
						Router.go 'pkgsinfo', {urlName: data.urlName}
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



	'click [data-filter="catalogs"]': (event) ->
		event.stopPropagation()
		event.preventDefault()
		search = this.toString()
		catalogs = Session.get 'listOfSelectedCatalogs'

		idx = catalogs.indexOf search
		if idx is -1
			catalogs.push search
		else
			catalogs.splice idx, 1
		Session.set 'listOfSelectedCatalogs', catalogs
}