Template.accountsAccess.rendered = ->
	Mandrill.tpl.activateTooltips()


Template.accountsAccess.munkiRepoPath = ->
	settings = MandrillSettings.findOne()

	if settings? and settings.munkiRepoPath?
		settings.munkiRepoPath
	else ''


Template.accountsAccess.readOnlyIsChecked = ->
	if this.readonly is true
		'checked'



Template.accountsAccess.events {

	#// Add a new pattern, as long as it's not empty
	'submit form': (event)->
		event.stopPropagation()
		event.preventDefault()

		$pattField = $('input[data-new-access-rule]')
		$roField = $('input[data-new-access-readonly]')
		patt = $pattField.val()
		data = Router.current().data().user

		if patt is ''
			return

		Meteor.users.update(data._id, {'$addToSet':
			{
				'mandrill.accessPatterns': {
					pattern: patt,
					readonly: $roField.is(':checked')
				}
			}
		})

		#// reset the form
		$pattField.val('');
		$pattField.focus();
		$roField.attr('checked', false);


	'change input[data-toggle-readonly]': (event)->
		$tgt = $(event.target)
		val = $tgt.is(':checked')
		data = Router.current().data().user
		existingPatterns = data.mandrill.accessPatterns

		for doc, key in existingPatterns
			do (key, doc) ->
				if doc.pattern is this.pattern
					existingPatterns[key].readonly = val

		Meteor.users.update(data._id,{'$unset':
			{'mandrill.accessPatterns': ''}
		})
		Meteor.users.update(data._id, {'$set':
			{'mandrill.accessPatterns': existingPatterns}
		})



	'change input[data-access-pattern]': (event)->
		$tgt = $(event.target)
		pattNew = $tgt.val()
		data = Router.current().data().user
		existingPatterns = data.mandrill.accessPatterns

		while pattNew[0] is '/' and pattNew.length > 0
			pattNew = pattNew.substring 1

		$tgt.val pattNew

		for doc, key in existingPatterns
			do (key, doc) ->
				if doc.pattern is this.pattern
					existingPatterns[key] = pattNew

		Meteor.users.update(data._id, {'$unset':
			{'mandrill.accessPatterns': ''}
		})
		Meteor.users.update(data._id, {'$set':
			{'mandrill.accessPatterns': existingPatterns}
		})



	'click button[data-remove-pattern]': (event)->
		event.stopPropagation()
		event.preventDefault()

		data = Router.current().data().user

		Meteor.users.update data._id, {
			'$pull': {
				'mandrill.accessPatterns': {
					pattern: this.pattern,
					readonly: this.readonly
				}
			}
		}
}