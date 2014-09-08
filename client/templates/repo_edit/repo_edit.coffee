Session.setDefault 'tab_git-logs', false
Session.setDefault 'repo_item_loading_raw', false



Template.repo_edit.rendered = ->
	editor = MandrillAce.getInstance()
	editor.setTheme 'ace/theme/tomorrow_night'
	editor.ace.getSession().setUseWrapMode true


Template.repo_edit.update_ace = ->
	editor = MandrillAce.getInstance()
	record = Router.current().data()

	if record?._id?
		Session.set 'repo_item_loading_raw', true
		Meteor.call 'getRawRepoItemContent', record._id, (err, data)->
			editor.detectMode record.path
			Session.set 'repo_item_loading_raw', false
			if data isnt false
				editor.setReadOnly false
				editor.setValue(data, -1)

			else if err? or data is false
				editor.setReadOnly true
				Mandrill.show.error(err)

			else
				editor.setReadOnly true
				editor.setValue("Editing files of this type in the browser isn't currently supported.", -1)

	# always return null so we don't start spitting things out to the browser
	null



Template.repo_edit.is_image = ->
	crumb = Router.current().params.c
	if crumb?
		Mandrill.path.is_image crumb



Template.repo_edit.item_url = ->
	url = MandrillSettings.get 'SoftwareRepoURL'
	crumb = Router.current().params.c
	if url? and crumb?
		Mandrill.path.concat_relative url, crumb
	else
		''

Template.repo_edit.item_filename = ->
	crumb = Router.current().params.c
	_.last crumb.split('/')


Template.repo_edit.file_size = ->
	record = Router.current().data()
	if record?.stat?.size?
		record.stat.size
	else
		0



Template.repo_edit.breadcrumb = ->
    Template.repo.breadcrumb()


Template.repo_edit.waiting_on_server_response = ->
	loading = Session.get 'repo_item_loading_raw'
	saving = Session.get 'save_in_progress'
	saving is true or loading is true



Template.repo_edit.events {

	#
	# Return the user to the parent directory when the cancel button is
	# clicked.
	#
	'click #git-cancel': (event)->
		event.preventDefault()
		event.stopPropagation()

		parent_path = _.initial Router.current().params.c.split('/')
		url = Router.path 'repo', {}, {query: 'c=' + parent_path.join('/')}
		Router.go url


	###
		Tab click events
	###
	'shown.bs.tab a[data-toggle="tab"]': (event)->
		tab = $(event.target).attr('href').replace(/^#/, '')
		Session.set 'tab_git-logs', false
		if tab is 'git-logs'
			crumb = Router.current().params.c
			path = MandrillSettings.get 'munkiRepoPath'
			path = Mandrill.path.concat path, crumb
			Meteor.call 'git-log', path, (error, result)->
				Session.set 'tab_git-logs', {
					error: error
					logs: result
				}
}
