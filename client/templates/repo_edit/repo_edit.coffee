Session.setDefault 'ace_is_ready', false



Template.repo_edit.is_image = ->
	crumb = Router.current().params.c
	if crumb?
		Mandrill.path.is_image crumb


Template.repo_edit.image_url = ->
	url = MandrillSettings.get 'SoftwareRepoURL'
	crumb = Mandrill.path.concat_relative Router.current().params.c
	url + '/' + crumb


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
	crumb = Router.current().params.c
	patt = new RegExp crumb + '$'
	record = MunkiRepo.findOne {path: patt}
	content = if record? and record.raw? then record.raw else ''
	editor = Template.repo_edit.ace()
	setTimeout ->
		editor = Template.repo_edit.ace()
		Mandrill.util.ace.detect_mode crumb, editor
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
    # params = Router.current().params
    # Mandrill.path.concat_relative(params.c).split '/'
    Template.repo.breadcrumb()



###
    Override to set the document body.
###
###
Template.repo_edit.document_body = ->
    patt = new RegExp(Router.current().params.c + '$')
    doc = MunkiRepo.findOne {path: patt}
    editor = Template.repo_edit.ace()
    if editor?
        hasLocalChanges = editor.session.getUndoManager().dirtyCounter > 0
    else
        hasLocalChanges = false
	currentBody = if editor? then editor.session.getValue() else ''
	readOnly = true

	if doc? and doc.path?
		readOnly = not Mandrill.user.canModifyPath(Meteor.userId(), doc.path, false)

	if editor?
		editor.setReadOnly readOnly

	if editor? and doc? and doc.raw?
		if hasLocalChanges is false
			editor.setValue doc.raw
		else if currentBody isnt doc.raw
			answer = confirm 'This document has changed. Do you want to load the changes now?'
			if answer is yes
				editor.setValue doc.raw
		else
			editor.setValue doc.raw

	else if doc? and doc.raw?
		doc.raw
	else
		''
###
