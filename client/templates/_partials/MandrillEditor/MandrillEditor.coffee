Session.setDefault 'aceIsReady', false
Session.setDefault 'activeDocument', null

#// Set this session variable to true when the work is being done on the
#// document for which the user should wait.
Session.setDefault 'workingOnDocument', false


callOnCurrentTpl = ->

	args = Array.prototype.slice.call(arguments)
	method = args.slice(0, 1)[0]
	args = args.slice(1)
	router = Router.current()
	tpl = if router? and router.template? then router.template else null
	func = if tpl? and Template[tpl][method]? then Template[tpl][method] else null

	if not func?
		console.error 'Template.' + tpl + '.' + method + '() is not defined!'
	else
		func.apply(null, args)
		


#/* --- Methods that should be overridden --- */


#// Override to set the target url when the File -> Close menu
#// is clicked.
Template.MandrillEditor.backLinkTarget = ->
	callOnCurrentTpl('backLinkTarget')


#// Don't override this. Set the 'workingOnDocument' session variable instead.
#// This triggers the bubble loader to display when things are happening to the
#// document, such as a 'save' action.
Template.MandrillEditor.workingOnDocument = ->
	Session.get 'workingOnDocument'


Template.MandrillEditor.setDocument = (doc) ->
	if doc? and doc.path? and doc.body?
		Session.set 'activeDocument', doc
	else
		Session.set 'activeDocument', null
		console.error('documents must have a `path` and `body` property')


#// Override to set the title of the document being edited.
Template.MandrillEditor.documentTitle = ->
	doc = Session.get 'activeDocument'
	settings = MandrillSettings.findOne()
	if settings? and settings.munkiRepoPath? and doc? and doc.path
		doc.path.replace(settings.munkiRepoPath, '')
	else
		'??'



#// Override to set the full path to the document being edited.
#// This is only used to display git commit logs.
Template.MandrillEditor.documentPath = ->
	doc = Session.get 'activeDocument'
	if doc? and doc.path?
		doc.path
	else
		''


#// Override to set the document body.
Template.MandrillEditor.documentBody = ->
	doc = Session.get 'activeDocument'
	editor = Template.MandrillEditor.ace()
	hasLocalChanges = if editor? then editor.session.getUndoManager().dirtyCounter > 0 else false
	currentBody = if editor? then editor.session.getValue() else ''
	readOnly = true

	if doc? and doc.path?
		readOnly = not Mandrill.user.canModifyPath(Meteor.userId(), doc.path, false)

	if editor?
		editor.setReadOnly readOnly

	if editor? and doc? and doc.body?
		if hasLocalChanges is false
			editor.session.setValue doc.body
		else if currentBody isnt doc.body
			answer = confirm 'This document has changed. Do you want to load the changes now?'
			if answer is yes
				editor.session.setValue doc.body
		else
			editor.session.setValue doc.body

	else if doc? and doc.body?
		doc.body
	else
		''


#// Override to handle File->Save. One parameter, 'doc_text' is passed to
#// this function and is the document as it currently exists in the
#// ACE editor
Template.MandrillEditor.saveHook = ->
	editor = Template.MandrillEditor.ace()
	body = if editor? then editor.session.getValue() else ''

	callOnCurrentTpl 'saveHook', body, (err, doc) ->
		Session.set 'workingOnDocument', false
		if err?
			console.error err
			Mandrill.show.error err



#// Override to handle "File->Delete...". The editor will prompt the user
#// for confirmation of the delete before firing this hook. The target
#// template is expected to know which document it provided to
#// Template.MandrillEditor.setDocument()
Template.MandrillEditor.deleteHook = ->
	callOnCurrentTpl 'deleteHook'




#/* --- 'public' stuff, if needed --- */


Template.MandrillEditor.ace = ->
	try
		editor = ace.edit('aceEditor')
		if Session.equals('aceIsReady', false) is true
			Session.set 'aceIsReady', true
	catch e
		Session.set 'aceIsReady', false
		#// let this fail silently since it will almost certainly
		#// fail to find #aceEditor until everything is rendered.

	editor



#/* --- / 'public' --- */





#/* --- guts - don't override! --- */
Template.MandrillEditor.rendered = ->
	editor = Template.MandrillEditor.ace()

	if editor?
		editor.setTheme 'ace/theme/xcode'
		editor.getSession().setMode 'ace/mode/xml'
		editor.getSession().setUseWrapMode true

	Template.MandrillEditor.resize()


Template.MandrillEditor.created = ->
	#// Make sure the height of the editor always matches the available
	#// height when the window is resized.
	$(window).on 'resize', Template.MandrillEditor.resize




#// Make sure the height of the sidebar matches the available height
#// within the window.
Template.MandrillEditor.resize = ->
	editor = Template.MandrillEditor.ace()
	$editor = $('#aceEditor')
	top = if $editor.length isnt 0 then $editor.offset().top else 0
	height = if $editor.length isnt 0 then $editor.height() else 0
	winHeight = $(window).height() - top

	#// avoid triggering a re-draw if the height of the window isn't
	#// changing.
	if height isnt winHeight and winHeight > 150
		$editor.height winHeight

	if editor?
		editor.resize()
		editor.focus()



Template.MandrillEditor.events {
	'click .MandrillEditor-menu-command': (event)->
		event.preventDefault()
		event.stopPropagation()

		command = $(event.target).data('menu-command')
		editor = Template.MandrillEditor.ace()

		#// Close any open menus. Bootstrap would to this on its own if we let
		#// it, but it mucks with focus in the process which makes menu items
		#// that launch modal dialogs immediately trigger the dialog to close.
		$('.open').removeClass 'open'

		if editor? and command?
			try
				editor.execCommand command

			catch e
				console.error 'Failed command "' + command + '"'
				console.error e

			#// Since the menu was clicked, we need to give focus back to
			#// the editor, unless it's a 'find' or 'replace' command, in
			#// which case we'll let the focus go where it should.
			if command isnt 'find' and command isnt 'replace' and command isnt 'gitCommitLogs'
				editor.focus()


	'click .MandrillEditor-menu': (event)->
		event.preventDefault()


	#// If there's an open menu when the user hovers over another top-level
	#// menu, make sure the open menu follows the mouse.
	'mouseover .dropdown-toggle': (event)->
		openMenus = $('.open')
		target = $(event.target).closest('li')

		if openMenus.length > 0
			openMenus.removeClass 'open'
			openMenus.find('a').blur()


			target.addClass 'open'
			target.find('a.dropdown-toggle').focus()
}