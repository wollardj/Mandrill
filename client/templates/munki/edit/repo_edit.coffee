Session.setDefault 'tab_git-logs', false
Session.setDefault 'repo_edit_tpl', 'ace'
Session.setDefault 'repo_item_loading_raw', false


reLoadGitLogs = ->
	crumb = Router.current().params.query.c
	path = Munki.repoPath()
	path = Mandrill.path.concat path, crumb
	Meteor.call 'git-log', path, (error, result)->
		Session.set 'tab_git-logs', {
			error: error
			logs: result
		}


Template.repo_edit.rendered = ->
	editor = MandrillAce.getInstance()
	editor.setTheme 'ace/theme/tomorrow_night'
	editor?.ace?.getSession().setUseWrapMode true
	reLoadGitLogs()


Template.repo_edit.helpers {


	formModeUrl: ->
		crumb = Router.current().params.query.c
		record = Router.current().data()
		routerName = ''
		if record?
			if record.isCatalog()
				routerName = 'catalog'
			# else if record.isIcon()
			#	routerName = 'image'
			#else if record.isPkginfo()
			#	routerName = 'pkginfo'
			else if record.isManifest()
				routerName = 'munkiEditManifest'
			#else if record.isBinary()
			#	tpl = 'binary'

			Router.path routerName, {}, {query:'c=' + crumb}


	update_ace: ->
		editor = MandrillAce.getInstance()
		editor.setTheme 'ace/theme/tomorrow_night'
		editor.ace?.getSession().setUseWrapMode true
		record = Router.current().data()


		if record?._id?
			Session.set 'repo_item_loading_raw', true
			Meteor.call 'getRawRepoItemContent', record._id, (err, data)->
				editor.detectMode record.path
				Session.set 'repo_item_loading_raw', false
				if data isnt false
					editor.setReadOnly false
					editor.setValue(data, -1)

				else if err?
					editor.setReadOnly true
					Mandrill.show.error(err)

				else
					editor.setReadOnly true
					editor.setValue("Editing files of this type in the browser isn't currently supported.", -1)

		# always return null so we don't start spitting things out to the browser
		null



	item_url: ->
		url = Munki.repoUrl()
		crumb = Router.current().params.query.c
		if url? and crumb?
			Mandrill.path.concat_relative url, crumb
		else
			''

	item_filename: ->
		crumb = Router.current().params.query.c
		_.last crumb.split('/')


	file_size: ->
		record = Router.current().data()
		if record?.stat?.size?
			record.stat.size
		else
			0


	waiting_on_server_response: ->
		loading = Session.get 'repo_item_loading_raw'
		saving = Session.get 'save_in_progress'
		saving is true or loading is true
}


Template.repo_edit.events {

	'click #switch-to-form-mode-btn': (event)->
		$(event.target).find('i').addClass('fa-spin')


	###
		Tab click events
	###
	'shown.bs.tab a[data-toggle="tab"]': (event)->
		tab = $(event.target).attr('href').replace(/^#/, '')
		Session.set 'tab_git-logs', false
		if tab is 'git-logs'
			reLoadGitLogs()
}
