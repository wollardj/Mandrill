Template.MandrillEditorMenu.menuItems = ->
	Session.get 'aceIsReady'
	editor = Template.MandrillEditor.ace()
	if editor?
		MandrillEditorMenu.prepareMap(editor)
		MandrillEditorMenu._map
	else
		[]




Template.MandrillEditorMenu.cmdKeyBinding = ->
	if this.command? and this.command.bindKey?
		new Handlebars.SafeString(
			MandrillEditorMenu._htmlKeyBinding(this.command)
		)
	else
		''


Template.MandrillEditorMenu.isReadOnly = ->
	doc = Session.get 'activeDocument'
	uid = Meteor.userId()

	if uid? and doc? and doc.path?	
		not Mandrill.user.canModifyPath(uid, doc.path, false)
	else
		true


Template.MandrillEditorMenu.hideWhenReadOnly = ->
	doc = Session.get 'activeDocument'
	uid = Meteor.userId()
	readOnly = true

	if uid? and doc? and doc.path?
		readOnly = not Mandrill.user.canModifyPath(uid, doc.path, false)


	if readOnly is true and this.hideWhenReadOnly is true
		true
	else
		false


Template.MandrillEditorMenu.disabledWhenReadOnly = ->
	doc = Session.get 'activeDocument'
	uid = Meteor.userId()
	readOnly = true


	if uid? and doc? and doc.path?
		readOnly = not Mandrill.user.canModifyPath(uid, doc.path, false)


	if readOnly is true and this.command.disabledWhenReadOnly is true
		'disabled'
	else
		''




###
	Builds the menu structure for our Ace Editor implementation.
	Proper usage is basically:

	var editor = ace.edit( "aceEditor" );
	MandrillEditorMenu.prepareMap( editor );
	console.log( MandrillEditorMenu.menu() );
 ###


class MandrillEditorMenu

	# Returns the HTML encoded symbols that represent the keybindings for
	# a given ace command.
	@_htmlKeyBinding: (command)->
		if not @_editor? or not @_editor.commands?
			@_editor = Template.MandrillEditor.ace()

		platform = @_editor.commands.platform
		bindKey = if command? and command.bindKey? then command.bindKey

		if bindKey? and bindKey[platform]?
			keys = bindKey[platform]
		else if bindKey?
			keys = bindKey

		if keys? and keys.split?
			keys.split('|')[0]
				.replace /-/g, ''
				.replace 'Command', '&#x2318;'
				.replace 'Option', '&#x2325;'
				.replace 'Alt', '&#x2325;'
				.replace 'Ctrl', '&#x2303;'
				.replace 'Shift', '&#x21E7;'
				.replace 'Return', '&#x21A9;'
				.replace 'Delete', '&#x232B;'
				.replace 'Esc', '&#x238B;'
				.replace 'Tab', '&#x238B;'
				.replace 'Home', '&#x2196;'
				.replace 'End', '&#x2198;'
				.replace 'Left', '&#x2190;'
				.replace 'Right', '&#x2192;'
				.replace 'PageUp', '&#x21DE;'
				.replace 'PageDown', '&#x21DF;'
				.replace 'Up', '&#x2191;'
				.replace 'Down', '&#x2193;'
				.replace 'Space', '&#x2423;'
				.replace '<', '&lt;'
				.replace '>', '&gt;'
		else
			''

	

	@prepareMap: (@editor)->

		if not @editor? or not @editor.commands?
			console.error 'MandrillEditorMenu.prepareMap() expects an ' +
				'aceEditor instance as the only parameter.'
			return

		MandrillEditorCommands.addToEditor @editor
		c = @editor.commands.byName

		# NOTE: Bootstrap3 doesn't support nested submenus anymore, so this 
		# structure can only be 1 submenu deep. If deeper, the nested items
		# just simply won't be displayed (because of Bootstrap3, not
		# Mandrill)
		if not @_map?

			@._map = [
				{
					title: 'File'
					submenus: [
						{title: 'Revert to Saved State', command: c.revert}
						{title: 'Save',	command: c.save}
						{title: 'Delete...', command: c.remove}
						{}
						{title: 'Preferences', command: c.showSettingsMenu}
						{}
						{title: 'Close', command: c.back}
					]
				}
				{
					title: 'Edit'
					hideWhenReadOnly: true
					submenus: [
						{title: 'Undo', command: c.undo}
						{title: 'Redo', command: c.redo}
						{}
						{title: 'Comment', command: c.togglecomment}
						{title: 'Block Comnt', command: c.toggleBlockComment}
					]
				}
				{
					title: 'Select'
					submenus: [
						{title: 'Select All', command: c.selectall}
						{}
						{title: 'Line Start', command: c.selectlinestart}
						{title: 'Line End', command: c.selectlineend}
						{title: 'Word Left', command: c.selectwordleft}
						{title: 'Word Right', command: c.selectwordright}
						{}
						{title: 'Up', command: c.selectup}
						{title: 'Down', command: c.selectdown}
						{title: 'Left', command: c.selectleft}
						{title: 'Right', command: c.selectright}
						{}
						{title: 'Page Up', command: c.selectpageup}
						{title: 'Page Down', command: c.selectpagedown}
						{title: 'To Start', command: c.selecttostart}
						{title: 'To End', command: c.selecttoend}
					]
				}
				{
					title: 'Selection'
					hideWhenReadOnly: true
					submenus: [
						{title: 'Encode', command: c.htmlEncode}
						{title: 'Decode', command: c.htmlDecode}
						{}
						{title: 'Cursor Above', command: c.addCursorAbove}
						{title: 'Cursor Below', command: c.addCursorBelow}
						{title: 'Align Cursors', command: c.alignCursors}
						{}
						{title: 'Center', command: c.centerselection}
						{}
						{title: 'More After', command: c.selectMoreAfter}
						{title: 'More Before', command: c.selectMoreBefore}
						{title: 'Next After', command: c.selectNextAfter}
						{title: 'Next Before', command: c.selectNextBefore}
					]
				}
				{
					title: 'Find'
					submenus: [
						{title: 'Find...', command: c.find}
						{title: 'Find Next', command: c.findnext}
						{title: 'Find Prev', command: c.findprevious}
						{}
						{title: 'Replace...', command: c.replace}
					]
				}
				{
					title: 'Goto'
					submenus: [
						{title: 'Line', command: c.gotoline}
						{title: 'Line Start', command: c.gotolinestart}
						{title: 'Line End', command: c.gotolineend}
						{}
						{title: 'Start', command: c.gotostart}
						{title: 'End', command: c.gotoend}
						{title: 'Page Up', command: c.gotopageup}
						{title: 'Page Down', command: c.gotopagedown}
						{}
						{title: 'Left', command: c.gotoleft}
						{title: 'Right', command: c.gotoright}
						{title: 'Word Left', command: c.gotowordleft}
						{title: 'Word Right', command: c.gotowordright}
					]
				}
				{
					title: 'Help'
					submenus: [
						{title: 'Manifests', command: c.helpManifests}
						{
							title: 'Optional Installs'
							command: c.helpOptionalInstalls
						}
						{
							title: 'Conditional Items'
							command: c.helpConditionalItems
						}
						{}
						{title: 'Pkginfo Files', command: c.helpPkginfo}
						{
							title: 'Supported Pkginfo Keys'
							command: c.helpSupportedKeys
						}
						{
							title: 'Pre and Postflight Scripts'
							command: c.helpScripts
						}
						{
							title: 'Auto-Remove'
							command: c.helpAutoRemove
						}
						{
							title: 'Copy From DMG'
							command: c.helpCopyFromDmg
						}
						{
							title: 'Blocking Applications'
							command: c.helpBlockingApps
						}
						{
							title: 'Choice Changes XML'
							command: c.helpChoiceChangesXml
						}
						{
							title: 'Apple Software Updates'
							command: c.helpAppleUpdates
						}
						{
							title: 'How Munki decides what ' +
								'needs to be installed'
							command: c.helpMunkiLogic
						}
						{}
						{
							title: 'munki-dev Google Group'
							command: c.helpMunkiDev
						}
						{
							title: 'mandrill-dev Google Group'
							command: c.helpMandrillDev
						}
					]
				}
			]


		# If git is enabled, add the File->History menu option
		if @_map[0].submenus[0].title isnt 'Git Logs'
			settings = MandrillSettings.findOne()
			if settings? and settings.gitIsEnabled is true
				@_map[0].submenus.splice 0, 0, {}
				@_map[0].submenus.splice 0, 0, {
					title: 'Git Logs'
					command: c.gitCommitLogs
				}