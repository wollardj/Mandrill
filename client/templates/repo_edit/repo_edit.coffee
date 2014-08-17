Session.setDefault 'ace_is_ready', false
Session.setDefault 'tab_git-logs', false



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
	if record? and record.stat? and record.stat.size?
		record.stat.size
	else
		0


Template.repo_edit.ace = ->
	try
		editor = ace.edit('aceEditor')
		if Session.equals('ace_is_ready', false)
			Session.set 'ace_is_ready', true
	catch e
		Session.set 'ace_is_ready', false
		# let this fail silently since it will almost certainly
		# fail to find #aceEditor until everything is rendered.

	editor


Template.repo_edit.update_ace = ->
	editor = Template.repo_edit.ace()
	record = Router.current().data()
	content = if record? and record.raw? then record.raw else ''
	setTimeout ->
		editor = Template.repo_edit.ace()
		Mandrill.util.ace.detect_mode record.path, editor
		editor.setTheme 'ace/theme/tomorrow_night'
		editor.getSession().setUseWrapMode true
	, 50
	if editor? and content?
		console.log 'updating ace'
		editor.setValue(content, -1)
	else if content?
		content
	else
		''

Template.repo_edit.breadcrumb = ->
    Template.repo.breadcrumb()



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
