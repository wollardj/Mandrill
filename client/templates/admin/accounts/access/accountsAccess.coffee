Template.accountsAccess.helpers {
	rendered: ->
		Mandrill.tpl.activateTooltips()


	munkiRepoPath: ->
		Munki.repoPath()


	readOnlyIsChecked: ->
		if this.readonly is true
			'checked'
}



Template.accountsAccess.events {

	# Add a new pattern, as long as it's not empty
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

		# reset the form
		$pattField.val('');
		$pattField.focus();
		$roField.attr('checked', false);


	'change input[data-toggle-readonly]': (event)->
		$tgt = $(event.target)
		val = $tgt.is(':checked')
		user = Router.current().data().user
		existingPatterns = []
		if user? and user.mandrill? and user.mandrill.accessPatterns?
			existingPatterns = user.mandrill.accessPatterns

		for own key, doc of existingPatterns
			if doc.pattern is this.pattern
				existingPatterns[key].readonly = val

		Meteor.users.update user._id, {'$set':
			{'mandrill.accessPatterns': existingPatterns}
		}



	'change input[data-access-pattern]': (event)->
		input = $(event.target)
		pattNew = input.val()
		user = Router.current().data().user
		existingPatterns = []
		if user? and user.mandrill? and user.mandrill.accessPatterns?
			existingPatterns = user.mandrill.accessPatterns

		while pattNew.indexOf('/') is 0 and pattNew.length > 0
			pattNew = pattNew.substring 1

		input.val pattNew

		for own key, doc of existingPatterns
			if doc.pattern is this.pattern
				existingPatterns[key].pattern = pattNew

		Meteor.users.update user._id, {'$set':
			{'mandrill.accessPatterns': existingPatterns}
		}



	'click button[data-remove-pattern]': (event)->
		event.stopPropagation()
		event.preventDefault()

		user = Router.current().data().user

		Meteor.users.update user._id, {
			'$pull': {
				'mandrill.accessPatterns': {
					pattern: this.pattern,
					readonly: this.readonly
				}
			}
		}
}
