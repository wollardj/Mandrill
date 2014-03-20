@Mandrill = {

	version: '0.6.3'

	tpl: {
		activateTooltips: ->
			items = $('[data-toggle]')
			for item in items
				element = $(item)
				if element.data('toggle') is 'tooltip'
					element.tooltip {
						html: true,
						delay:{show: 500, hide: 250}
					}
	}

	show: {
		error: (e)->
			code = e.error
			reason = e.reason
			d = new Date()
			id = 'mandrill-error_' + d.getTime()

			dom = $('<div id="' + id + '" class="mandrill-error alert ' +
					'alert-danger alert-dismissable fade in">' +
					'<button type="button" class="close" ' +
						'data-dismiss="alert" aria-hidden="true">&times;' +
					'</button>' +
					'<h4>Application Error ' + code + ':</h4>' +
					'<p>' + reason + '</p>' +
					'</div>'
			)

			$('body').append dom

			#// auto-dismiss after 10 seconds
			window.setTimeout ->
				$('#' + id).alert 'close'
			, 10000


		success: (title, message)->
			d = new Date()
			id = 'mandrill-success_' + d.getTime()

			$('body').append('<div id="' + id +
				'" class="mandrill-error alert alert-success ' +
					'alert-dismissable fade in">' +
				'<button type="button" class="close" ' +
					'data-dismiss="alert" aria-hidden="true">' +
					'&times;' +
				'</button>' +
				(if title isnt '' then '<h4>' + title + '</h4>') +
				'<p>' + message + '</p>' +
				'</div>'
			)

			#// auto-dismiss after 10 seconds
			window.setTimeout ->
				$('#' + id).alert 'close'
			, 10000
	}




	util: {

		#/*
		#	Thank you, php.js:
		#	http://phpjs.org/functions/escapeshellarg/
		# */
		escapeShellArg: (arg)->
			ret = ''

			#// make sure arg is a string
			arg += ''
			ret = arg.replace(/[^\\]"/g, (m)->
				m.slice(0, 1) + '\\"'
			)
			'"' + ret + '"'

		generateRandomString: (length)->
			chars = '0123456789abcdefghijklmnopqrstuvwxyz' +
					'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
					'?:"{}!@#$%^&*()_+=-'
			result = ''

			for i in [length..1]
				result += chars[Math.round(
					Math.random() * (chars.length - 1))
				]
			result


		htmlSpecialChars: (target, quoteStyle, charset, doubleEncode)->
			#// From: http://phpjs.org/functions

			optTemp = 0
			noquotes = false
			quoteStyle = quoteStyle or 2

			#// Put this first to avoid double-encoding
			if doubleEncode isnt false
				target = target.toString().replace /&/g, '&amp;'

			target = target.toString()
				.replace /</g, '&lt;'
				.replace />/g, '&gt;'

			OPTS = {
				'ENT_NOQUOTES': 0,
				'ENT_HTML_QUOTE_SINGLE': 1,
				'ENT_HTML_QUOTE_DOUBLE': 2,
				'ENT_COMPAT': 2,
				'ENT_QUOTES': 3,
				'ENT_IGNORE': 4
			}
			
			if quoteStyle is 0
				noquotes = true

			#// Allow for a single target or an array of target flags
			if typeof quoteStyle isnt 'number'
				quoteStyle = [].concat quoteStyle
				for own key, value of quoteStyle
					#// Resolve target input to bitwise e.g. 'ENT_IGNORE'
					#// becomes 4
					if OPTS[value] is 0
						noquotes = true
					else if OPTS[value]?
						optTemp = optTemp | OPTS[value]
				quoteStyle = optTemp

			if quoteStyle & OPTS.ENT_HTML_QUOTE_SINGLE
				target = target.replace(/'/g, '&#039;')
			if not noquotes
				target = target.replace(/"/g, '&quot;')

			target



		htmlSpecialCharsDecode: (string, quoteStyle)->
			#// From: http://phpjs.org/functions
			optTemp = 0
			i = 0
			noquotes = false
			quoteStyle = quoteStyle or 2
			string = string.toString()
				.replace /&lt;/g, '<'
				.replace /&gt;/g, '>'

			OPTS = {
				'ENT_NOQUOTES': 0,
				'ENT_HTML_QUOTE_SINGLE': 1,
				'ENT_HTML_QUOTE_DOUBLE': 2,
				'ENT_COMPAT': 2,
				'ENT_QUOTES': 3,
				'ENT_IGNORE': 4
			}

			if quoteStyle is 0
				noquotes = true

			#// Allow for a single string or an array of string flags
			if typeof quoteStyle isnt 'number'
				quoteStyle = [].concat quoteStyle
				for own key, value of quoteStyle
					#// Resolve string input to bitwise e.g.
					#// 'PATHINFO_EXTENSION' becomes 4
					if OPTS[value] is 0
						noquotes = true
					else if OPTS[value]
						optTemp = optTemp | OPTS[value]
				quoteStyle = optTemp

			if quoteStyle & OPTS.ENT_HTML_QUOTE_SINGLE
				#// PHP doesn't currently escape if more than one 0,
				#// but it should
				string = string.replace /&#0*39;/g, '\''

			if not noquotes
				string = string.replace /&quot;/g, '"'

			#// Put this in last place to avoid escape being double-decoded
			string.replace /&amp;/g, '&'


		ace: {
			selection: {
				htmlDecode: (editor)->
					range = editor.getSelectionRange()
					decoded = Mandrill.util.htmlSpecialCharsDecode(
						editor.session.getTextRange( range )
					)
					editor.getSession().getDocument()
						.replace(range, decoded)
					#// This is kind of hacky - gets the editor to keep
					#// the selected text selected after mutation
					editor.find decoded


				htmlEncode: (editor)->
					range = editor.getSelectionRange()
					encoded = Mandrill.util.htmlSpecialChars(
						editor.session.getTextRange( range )
					)
					editor.getSession().getDocument()
						.replace(range, encoded)
					#// This is kind of hacky - gets the editor to keep
					#// the selected text selected after mutation
					editor.find(encoded)
			}
		}
	},



	user: {

		#// If the user is banned, this method will log that user out and
		#// return true. If not, it will simply return false, as in
		#// 'not banned'
		isBanned: (userObject)->
			if userObject? and userObject.mandrill? and userObject.mandrill.isBanned is true
				Meteor.users.update(
					{_id: userObject._id},
					{'$set': {'services.resume.loginTokens':[]}}
				);
				true
			else
				false



		#// makes sure the logged in user is an admin, _and_ that the
		#// admin isn't banned.
		isAdmin: (userId)->
			if userId?
				user = Meteor.users.findOne(userId)
				admin = user? and user.mandrill? and user.mandrill.isAdmin is true
				admin and Mandrill.user.isBanned(user) is false
			else
				false


		#// makes sure there is a logged in user, _and_ that the user
		#// isn't banned.
		isValid: (userId)->
			if userId?
				user = Meteor.users.findOne(userId)
				user and Mandrill.user.isBanned(user) is false
			else
				false


		#// evaluates the accessPatterns for a given user and returns a
		#// mongo filter. This uses the 'path' attribute for the filter
		#// field. If query is passed, it is expected to be a normal
		#// mongo query which will be applied to, and returned with, the
		#// filter query from this function
		accessPatternsFilter: (userId, query)->
			user = Meteor.users.findOne userId, {fields: {
					'mandrill.isAdmin': 1,
					'mandrill.accessPatterns': 1
				}}
			settings = MandrillSettings.findOne()
			filter = {'$or':[]}

			if not user or not userId
				return {'path': false}

			repoPath = "/"
			if settings? and settings.munkiRepoPath?
				repoPath = settings.munkiRepoPath
			patterns = user.mandrill.accessPatterns or []
			
			if user.mandrill.isAdmin is true
				#// admin means all access
				if query?
					return query
				else
					return {}

			if patterns.length is 0
				#// no patterns means no access
				return {'path': false}

			for patt in patterns
				filter.$or.push {
					path: new RegExp('^' + repoPath + patt.pattern)
				}
			
			if query?
				return {'$and':[filter, query]}
			
			filter


		canModifyPath: (userId, aPath, throwError)->
			user = Meteor.users.findOne(userId, {fields: {
				'mandrill.isAdmin': 1,
				'mandrill.accessPatterns': 1
			}})
			settings = MandrillSettings.findOne()
			repoPath = if settings? then settings.munkiRepoPath else '/'

			#// No user = no access
			if not user or not userId
				if throwError is true
					throw new Meteor.Error(403, 'You can\'t do that without logging in.')
				else
					return false

			#// admin = all access
			if user.mandrill.isAdmin is true
				return true

			#// we've got a non-admin user, so we'll need to look at their
			#// access patterns.
			patterns = user.mandrill.accessPatterns or []
			repoPath = if repoPath? then repoPath else '/'

			for patt in patterns
				expr = '^' + repoPath + patt.pattern
				if (patt.readonly? is false or patt.readonly isnt true) and RegExp(expr).test(aPath) is true
					return true

			if throwError is true
				throw new Meteor.Error(403, 'Sorry, that path is read-only for your account.')
			return false
	}
}