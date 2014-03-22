class @MandrillEditorCommands


	@munkiWikiFunc: (page)->
		->
			@p = page
			window.open('https://code.google.com/p/munki/wiki/' + @p, 'munki_wiki').focus()


	@openWinFunc: (url)->
		->
			@u = url
			window.open(@u, @u).focus()

	@addToEditor: (editor)->
		for cmd in @commands
			editor.commands.addCommand cmd


	@commands: [
			{
				name: 'save'
				bindKey: {win: 'Ctrl-S', mac: 'Command-S'}
				disabledWhenReadOnly: true
				exec: (editor)->
					Template.MandrillEditor.saveHook editor.getValue()
			}
			{
				name: 'remove'
				disabledWhenReadOnly: true
				exec: (editor)->
					answer = confirm 'Really delete this file?'
					if answer is yes
						Template.MandrillEditor.deleteHook editor.getValue()
						Router.go Template.MandrillEditor.backLinkTarget()
			}
			{
				name: 'gitCommitLogs'
				bindKey: {win: 'Ctrl-I', mac: 'Command-I'}
				exec: (editor)->
					settings = MandrillSettings.findOne()
					if settings? and settings.gitIsEnabled is false
						alert 'Interaction with git is currently disabled.'
					else
						$('#gitLogsModal').modal()
							.on 'hidden.bs.modal', ->
								editor.focus()
			}
			{
				name: 'revert'
				exec: (editor)->
					editor.session.setValue(
						Template.MandrillEditor.documentBody()
					)
			}
			{
				name: 'back'
				bindKey: {win: 'Ctrl-`', mac: 'Command-`'}
				exec: (editor)->
					doc = Session.get 'activeDocument'
					original = if doc? and doc.body? then doc.body else ''
					current = editor.session.getValue()
					if original isnt current
						alert('You have unsaved changes!\n' +
							'Click File -> Revert to Saved State if you want ' +
							'to discard your changes.')
					else
						Router.go Template.MandrillEditor.backLinkTarget()
			}
			{
				name: 'htmlEncode'
				disabledWhenReadOnly: true
				bindKey: {win: 'Crtl-Shift-,', mac: 'Command-Shift-,'}
				exec: (editor)->
					Mandrill.util.ace.selection.htmlEncode editor
			}
			{
				name: 'htmlDecode'
				disabledWhenReadOnly: true
				bindKey: {win: 'Crtl-Shift-.', mac: 'Command-Shift-.'}
				exec: (editor)->
					Mandrill.util.ace.selection.htmlDecodeeditor
			}
			{
				name: 'helpManifests'
				exec: @munkiWikiFunc 'Manifests'
			}
			{
				name: 'helpOptionalInstalls'
				exec: @munkiWikiFunc 'MunkiOptionalInstalls'
			}
			{
				name: 'helpConditionalItems'
				exec: @munkiWikiFunc 'ConditionalItems'
			}
			{
				name: 'helpPkginfo'
				exec: @munkiWikiFunc 'PkginfoFiles'
			}
			{
				name: 'helpSupportedKeys'
				exec: @munkiWikiFunc 'SupportedPkginfoKeys'
			}
			{
				name: 'helpScripts'
				exec: @munkiWikiFunc 'PreAndPostinstallScripts'
			}
			{
				name: 'helpAutoremove'
				exec: @munkiWikiFunc 'MunkiAndAutoRemove'
			}
			{
				name: 'helpCopyFromDmg'
				exec: @munkiWikiFunc 'CopyFromDMG'
			}
			{
				name: 'helpBlockingApps'
				exec: @munkiWikiFunc 'BlockingApplications'
			}
			{
				name: 'helpChoiceChangesXml'
				exec: @munkiWikiFunc 'ChoiceChangesXML'
			}
			{
				name: 'helpAppleUpdates'
				exec: @munkiWikiFunc 'PkginfoForAppleSoftwareUpdates'
			}
			{
				name: 'helpMunkiLogic'
				exec: @munkiWikiFunc 'HowMunkiDecidesWhatNeedsToBeInstalled'
			}
			{
				name: 'helpMunkiDev'
				exec: @openWinFunc 'http://groups.google.com/group/munki-dev'
			}
			{
				name: 'helpMandrillDev'
				exec: @openWinFunc 'http://groups.google.com/group/mandrill-dev'
			}
		]