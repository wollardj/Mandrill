Session.setDefault('aceIsReady', false);

// Set this session variable to true when the work is being done on the
// document for which the user should wait.
Session.setDefault('workingOnDocument', false);


/* --- Methods that should be overridden --- */


// Override to set the target url when the File -> Close menu
// is clicked.
Template.MandrillEditor.backLinkTarget = function() {
	return Router.url('home');
};


// Don't override this. Set the 'workingOnDocument' session variable instead.
// This triggers the bubble loader to display when things are happening to the
// document, such as a 'save' action.
Template.MandrillEditor.workingOnDocument = function() {
	return Session.get('workingOnDocument');
};


// Override to set the title of the document being edited.
Template.MandrillEditor.documentTitle = function() {
	return '??';
};

// Override to set the full path to the document being edited.
// This is only used to display git commit logs.
Template.MandrillEditor.documentPath = function() {
	return '';
};

// Override to set the document body.
Template.MandrillEditor.documentBody = function() {
	return '';
};

// Override to handle File->Save. One parameter, 'doc_text' is passed to
// this function and is the document as it currently exists in the
// ACE editor
Template.MandrillEditor.saveHook = function() {
	alert('Template.MandrillEditor.saveHook() needs to be overridden. ' +
		'Nothing has been saved.');
};

// Override to handle "File->Delete...". The editor will prompt the user
// for confirmation of the delete before firing this hook. Arguments
// to this function are `_id` and `docText`
Template.MandrillEditor.deleteHook = function() {
	alert('Template.MandrillEditor.deleteHook() needs to be overridden.');
};


/* --- / methods to override --- */


/* --- 'public' stuff, if needed --- */


Template.MandrillEditor.ace = function() {
	var editor;
	try {
		editor = ace.edit('aceEditor');
		if (Session.equals('aceIsReady', false)) {
			Session.set('aceIsReady', true);
		}
	}
	catch(e) {
		Session.set('aceIsReady', false);
		// let this fail silently since it will almost certainly
		// fail to find #aceEditor until everything is rendered.
	}
	return editor;
};




Template.MandrillEditor.setDocumentBody = function(someText) {
	var editor = Template.MandrillEditor.ace(),
		currentValue = editor ? editor.session.getValue() : '',
		UndoManager = require('ace/undomanager').UndoManager;

	someText += ''; // make sure this is a string.

	// Ignore update requests during a save.
	if (Session.equals('workingOnDocument', true) === true) {
		return;
	}

	// If the user has made no changes, let the update happen.
	if (editor && editor.session.getUndoManager().dirtyCounter === 0) {
		editor.session.setValue(someText);
	}
	else if (editor && someText) {

		if (currentValue !== someText &&
			confirm('A newer version of this document is available. ' +
				'Load it now?') === true) {
			
			console.log('The user opted to accept the update');
			editor.session.setValue(someText);
			editor.session.setUndoManager( new UndoManager() );
		}
	}
};


/* --- / 'public' --- */





/* --- guts - don't override! --- */
Template.MandrillEditor.rendered = function() {
	var editor = Template.MandrillEditor.ace(),
		commands = [];

	if (editor) {
		editor.setTheme('ace/theme/xcode');
		editor.getSession().setMode('ace/mode/xml');
		editor.getSession().setUseWrapMode(true);
		//editor.setHighlightActiveLine(true);

		// custom key bindings
		commands = [
			{
				name: 'save',
				bindKey: {win: 'Ctrl-S', mac: 'Command-S'},
				exec: function(editor) {
					Template.MandrillEditor.saveHook(editor.getValue());
					// trigger an update of the locally-cached git logs
					Template.gitLogs.created();
				}
			},
			{
				name: 'remove',
				exec: function(editor) {
					var answer = confirm('Really delete this file?');
					if (answer === true) {
						Template.MandrillEditor.deleteHook(editor.getValue());
						Router.go(Template.MandrillEditor.backLinkTarget());
					}
				}
			},
			{
				name: 'gitCommitLogs',
				bindKey: {win: 'Ctrl-I', mac: 'Command-I'},
				exec: function(editor) {
					var settings = MandrillSettings.findOne();
					if (settings && settings.gitIsEnabled === false) {
						alert('Interaction with git is currently disabled.');
						return;
					}
					$('#gitLogsModal').modal({backdrop: false})
						.on('hidden.bs.modal', function() {
							editor.focus();
						});
				}
			},
			{
				name: 'revert',
				exec: function(editor) {
					editor.session.setValue(
						Template.MandrillEditor.documentBody()
					);
				}
			},
			{
				name: 'back',
				bindKey: {win: 'Ctrl-`', mac: 'Command-`'},
				exec: function(editor) {
					var original = Template.MandrillEditor.documentBody(),
						current = editor.session.getValue();
					if (original !== current) {
						alert('You have unsaved changes!\n' +
							'Click File -> Revert to Saved State if you want ' +
							'to discard your changes.');
						return;
					}
					Router.go(Template.MandrillEditor.backLinkTarget());
				}
			},
			{
				name: 'htmlEncode',
				bindKey: {win: 'Crtl-Shift-,', mac: 'Command-Shift-,'},
				exec: function(editor) {
					Mandrill.util.ace.selection.htmlEncode(editor);
				}
			},
			{
				name: 'htmlDecode',
				bindKey: {win: 'Crtl-Shift-.', mac: 'Command-Shift-.'},
				exec: function(editor) {
					Mandrill.util.ace.selection.htmlDecode(editor);
				}
			},
			{
				name: 'helpManifests',
				exec: function() {
					window.open(
						'https://code.google.com/p/munki/wiki/Manifests',
						'munki_help');
				}
			},
			{
				name: 'helpOptionalInstalls',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/MunkiOptionalInstalls',
						'munki_help');
				}
			},
			{
				name: 'helpConditionalItems',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/ConditionalItems',
						'munki_help');
				}
			},
			{
				name: 'helpPkginfo',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/PkginfoFiles',
						'munki_help');
				}
			},
			{
				name: 'helpSupportedKeys',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/SupportedPkginfoKeys',
						'munki_help');
				}
			},
			{
				name: 'helpScripts',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/PreAndPostinstallScripts',
						'munki_help');
				}
			},
			{
				name: 'helpAutoremove',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/MunkiAndAutoRemove',
						'munki_help');
				}
			},
			{
				name: 'helpCopyFromDmg',
				exec: function() {
					window.open(
						'https://code.google.com/p/munki/wiki/CopyFromDMG',
						'munki_help');
				}
			},
			{
				name: 'helpBlockingApps',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/BlockingApplications',
						'munki_help');
				}
			},
			{
				name: 'helpChoiceChangesXml',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/ChoiceChangesXML',
						'munki_help');
				}
			},
			{
				name: 'helpAppleUpdates',
				exec: function() {
					window.open(
						'https://code.google.com/' +
							'p/munki/wiki/PkginfoForAppleSoftwareUpdates',
						'munki_help');
				}
			},
			{
				name: 'helpMunkiLogic',
				exec: function() {
					window.open(
						'https://code.google.com/p/munki/wiki/' +
							'HowMunkiDecidesWhatNeedsToBeInstalled',
						'munki_help');
				}
			},
			{
				name: 'helpMunkiDev',
				exec: function() {
					window.open(
						'http://groups.google.com/group/munki-dev',
						'munki_help');
				}
			},
			{
				name: 'helpMandrillDev',
				exec: function() {
					window.open(
						'http://groups.google.com/group/mandrill-dev',
						'munki_help');
				}
			}
		];

		for(var i = 0; i < commands.length; i++) {
			editor.commands.addCommand(commands[i]);
		}
	}
	Template.MandrillEditor.resize();
};


Template.MandrillEditor.created = function() {
	// Make sure the height of the editor always matches the available
	// height when the window is resized.
	$(window).on('resize', Template.MandrillEditor.resize);
};


// Make sure the height of the sidebar matches the available height
// within the window.
Template.MandrillEditor.resize = function () {
	var editor = Template.MandrillEditor.ace(),
		winHeight = $(window).height() - $('#aceEditor').offset().top,
		$editor = $('#aceEditor'),
		currentHeight = $editor.height();

	// avoid triggering a re-draw if the height of the window isn't
	// changing.
	if (currentHeight !== winHeight && winHeight > 150) {
		$editor.height(winHeight);
	}

	if (editor) {
		editor.resize();
		editor.focus();
	}
};



Template.MandrillEditor.events({
	'click .MandrillEditor-menu-command': function(event) {
		event.preventDefault();
		event.stopPropagation();

		var command = $(event.target).data('menu-command'),
			editor = Template.MandrillEditor.ace();

		// Close any open menus. Bootstrap would to this on its own if we let
		// it, but it mucks with focus in the process which makes menu items
		// that launch modal dialogs immediately trigger the dialog to close.
		$('.open').removeClass('open');

		if (editor && command) {
			try {
				editor.execCommand(command);
			}
			catch(e) {
				console.error('Failed command "' + command + '"');
				console.error(e);
			}
			// Since the menu was clicked, we need to give focus back to
			// the editor, unless it's a 'find' or 'replace' command, in
			// which case we'll let the focus go where it should.
			if (command !== 'find' &&
				command !== 'replace' &&
				command !== 'gitCommitLogs') {
				
				editor.focus();
			}
		}
	},


	'click .MandrillEditor-menu': function(event) {
		event.preventDefault();
	},


	// If there's an open menu when the user hovers over another top-level
	// menu, make sure the open menu follows the mouse.
	'mouseover .dropdown-toggle': function(event) {
		var openMenus = $('.open'),
			target = $(event.target);
		if (openMenus.length > 0) {
			openMenus.removeClass('open');
			openMenus.find('a').blur();

			while(target && target.prop('tagName') !== 'LI') {
				target = $($(target).parent());
			}

			target.addClass('open');
			target.find('a.dropdown-toggle').focus();
		}
	}
});



/* --- menu building functions --- */


Template.MandrillEditor.editorMenu = function() {
	if (Session.equals('aceIsReady', true)) {
		var editor = Template.MandrillEditor.ace();
		if (editor) {
			MandrillEditorMenu.prepareMap(editor);
			return new Handlebars.SafeString(
				MandrillEditorMenu.menu()
			);
		}
	}
};