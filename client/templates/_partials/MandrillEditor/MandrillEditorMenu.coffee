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