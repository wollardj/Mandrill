Template.othertools.rendered = ->
	Mandrill.tpl.activateTooltips()




Template.othertools.events {
	'submit form': (event)->
		event.stopPropagation()
		event.preventDefault()
		
		$displayTextField = $('#displayText')
		$linkUrlField = $('#linkUrl')
		displayText = $displayTextField.val()
		linkUrl = $linkUrlField.val()
		obj = {displayText: displayText, linkUrl: linkUrl}

		if displayText is '' or linkUrl is ''
			return

		if this._id?
			OtherTools.update {_id: this._id}, {$set: obj}
		else
			OtherTools.insert obj

			#// Let's go ahead and reset the fields.
			$displayTextField.val ''
			$linkUrlField.val ''
			$displayTextField.focus()


	'click button.delete-link': (event)->
		event.stopPropagation()
		event.preventDefault()

		if this._id?
			OtherTools.remove this._id
		else
			alert 'I can\'t delete that.'


	'click td.edit-display-text, click td.edit-link-url': (event)->
		event.stopPropagation()
		event.preventDefault()

		target = $(event.target).closest('td')

		target.find('span').addClass 'hidden'
		target.find('input').removeClass 'hidden'
		target.find('input').focus()


	'blur input.edit-display-text-field, blur input.edit-link-url-field': (event)->
		event.stopPropagation()
		event.preventDefault()

		target = $(event.target)
		linkOrText = if target.hasClass 'edit-display-text-field' then 'text' else 'link'
		target = target.closest('td')

		target.find('span').removeClass 'hidden'
		target.find('input').addClass 'hidden'

		if linkOrText is 'text'
			OtherTools.update this._id, {'$set': {
				displayText: target.find('input').val()}
			}
		else
			OtherTools.update this._id, {'$set': {
				linkUrl: target.find('input').val()}
			}
}