Template.manifest_editor.active_manifest = ()->
	manifest = Session.get 'active_manifest'
	if manifest?
		try
			editor = ace.edit('manifest_editor')
			if editor?
				val = editor.getValue()
				if val isnt manifest.raw
					cursor_position = editor.getCursorPosition()
					editor.setValue manifest.raw
					editor.clearSelection()
					editor.moveCursorTo(cursor_position.row, cursor_position.column)
					editor.centerSelection()
		catch e

	manifest


Template.manifest_editor.rendered = ()->
	editor = ace.edit('manifest_editor')
	if editor?
		editor.setTheme 'ace/theme/twilight'
		editor.getSession().setMode 'ace/mode/xml'
		editor.getSession().setUseWrapMode true
		editor.setOption "scrollPastEnd", 0.7
		editor.on 'change', (event)->
			val = ace.edit('manifest_editor').getValue()
			manifest = Session.get 'active_manifest'
			manifest.raw = val
			Session.set 'active_manifest', manifest