Template.manifestEditor.backLinkTarget = ->
	return Router.url 'manifests'

Template.manifestEditor.saveHook = (docText, callback)->
	router = Router.current()
	data = if router? then router.data()
	if data? and docText?
		Meteor.call(
			'filePutContents',
			data.path,
			docText,
			callback
		);
	else
		callback()


Template.manifestEditor.deleteHook = (_id, docText)->
	router = Router.current()
	if router?
		data = router.data()
		Meteor.call 'unlinkManifest', data.path, (err, data)->
			if err?
				Mandrill.show.error err


Template.manifestEditor.documentWatcher = ->

	doc = {path:'', body: ''}

	if this.path? and this.raw
		doc.path = this.path
		doc.body = this.raw
	
	Template.MandrillEditor.setDocument doc