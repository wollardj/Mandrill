Template.pkgsinfoEditor.backLinkTarget = ->
	Router.url 'pkgsinfo'


Template.pkgsinfoEditor.saveHook = (docText, callback)->
	data = Router.current().data()
	Meteor.call(
		'filePutContents',
		data.path,
		docText,
		callback
	)



Template.pkgsinfoEditor.deleteHook = ->
	data = Router.current().data()
	#// First, we'll find out if the pkgsinfo file refers to an
	#// installer_item_location. If it does, we'll ask the user if that
	#// file should be removed as well before deleting the plist.
	Meteor.call(
		'pkginfoHasInstallerItem',
		data.urlName,
		(err, hasInstallerItem)->
			if err?
				Mandrill.show.error err
			else
				if hasInstallerItem is true
					hasInstallerItem = confirm(
						'Do you want to delete the corresponding installer ' +
						'item as well? Files in pkgs/ are not tracked, ' +
						'which means you cannot undo this action.'
					)
				
				Meteor.call(
					'unlinkPkginfo',
					data.path,
					hasInstallerItem,
					(err, data)->
						if err?
							Mandrill.show.error err
				)
	)




Template.pkgsinfoEditor.documentWatcher = ->

	doc = {path:'', body: ''}

	if this.path? and this.raw
		doc.path = this.path
		doc.body = this.raw
	
	Template.MandrillEditor.setDocument doc