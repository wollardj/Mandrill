@Mandrill = {

	version: '0.8.0'

	# a namespace for client-side subscriptions
	subs: {}


	# methods for handling strings as paths
	path: {
		components: (a_string)->
			a_string
				.replace(/^\/*/, '') # remove leading '/'
				.replace(/\/*$/, '') # remove trailing '/'
				.split('/')

		# takes one or more strings as arguments and creates a single
		# absolute (starts with '/') path.
		concat: ()->
			# clean up any trailing/leading separators
			strings = []
			for str in arguments
				if str? and str.replace?
					strings.push str.replace(/^\/*/, '').replace(/\/*$/,'')

			path = ''
			for item in strings
				path = path + '/' + item
			path

		# same as Mandrill.path.append, but doesn't prepend a '/' to the result.
		concat_relative: ()->
			Mandrill.path.concat.apply(null, arguments).replace(/^\/*/, '')
	}


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

			dom = $('<div id="' + id + '" class="mandrill-dialog alert ' +
					'alert-danger alert-dismissable elastic elastic-in">' +
					'<button type="button" class="close" ' +
						'data-dismiss="alert" aria-hidden="true">&times;' +
					'</button>' +
					'<h4>Application Error ' + code + ':</h4>' +
					'<p>' + reason + '</p>' +
					'</div>'
			)

			$('body').append dom

			# auto-dismiss after 10 seconds
			window.setTimeout ->
				$('#' + id).removeClass('elastic-in').addClass('elastic-out')
				window.setTimeout ->
					$('#' + id).alert 'close'
				, 250
			, 10000


		success: (title, message)->
			d = new Date()
			id = 'mandrill-success_' + d.getTime()
			realTitle = '&nbsp;'
			if title? and title isnt ''
				realTitle = title

			$('body').append('<div id="' + id +
				'" class="mandrill-dialog alert alert-success ' +
					'alert-dismissable elastic elastic-in">' +
				'<button type="button" class="close" ' +
					'data-dismiss="alert" aria-hidden="true">' +
					'&times;' +
				'</button>' +
				'<h4>' + realTitle + '</h4>' +
				'<p>' + message + '</p>' +
				'</div>'
			)

			# auto-dismiss after 10 seconds
			window.setTimeout ->
				$('#' + id).removeClass('elastic-in').addClass('elastic-out')
				window.setTimeout ->
					$('#' + id).alert 'close'
				, 250
			, 10000
	}




	util: {

		# Activates the typeahead plugin for the given selector and
		# converts the wrapping span's `display` to 'block' from
		# the default of 'inline-block'. The default `display` value causes
		# weird layout and width-flexing bugs with bootstrap3
		activateTypeahead: (selector)->
			if not selector?
				selector = '.typeahead'
			Meteor.typeahead.inject(selector)
			$(selector)
				.parents "span.twitter-typeahead"
				.css 'position', 'relative'
				.css 'display', 'flex'


		# Compares two version strings and returns values appropriate for
		# sorting; -1, 0, 1
		versionCompare: (v1, v2, options)->
			lexicographical = false
			zeroExtend = true
			v1parts = v1.split('.')
			v2parts = v2.split('.')

			if options?
				if options.lexicographical?
					lexicographical = true
				if options.zeroExtend?
					zeroExtend = true

			isValidPart = (x)->
				if lexicographical is true
					/^\d+[A-Za-z]*$/.test(x)
				else
					/^\d+$/.test(x)

			if not v1parts.every(isValidPart) or not v2parts.every(isValidPart)
				return NaN

			if zeroExtend is true
				while v1parts.length < v2parts.length
					v1parts.push("0")
				while v2parts.length < v1parts.length
					v2parts.push("0")

			if lexicographical is false
				v1parts = v1parts.map(Number)
				v2parts = v2parts.map(Number)

			for obj,i in v1parts
				if v2parts.length is i
					return 1

				if v1parts[i] is v2parts[i]
					continue
				else if v1parts[i] > v2parts[i]
					return 1
				else
					return -1

			if v1parts.length != v2parts.length
				return -1
			return 0



		#/*
		#	Thank you, php.js:
		#	http://phpjs.org/functions/escapeshellarg/
		# */
		escapeShellArg: (arg)->
			ret = ''

			# make sure arg is a string
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
			# From: http://phpjs.org/functions

			optTemp = 0
			noquotes = false
			quoteStyle = quoteStyle or 2

			# Put this first to avoid double-encoding
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

			# Allow for a single target or an array of target flags
			if typeof quoteStyle isnt 'number'
				quoteStyle = [].concat quoteStyle
				for own key, value of quoteStyle
					# Resolve target input to bitwise e.g. 'ENT_IGNORE'
					# becomes 4
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
			# From: http://phpjs.org/functions
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

			# Allow for a single string or an array of string flags
			if typeof quoteStyle isnt 'number'
				quoteStyle = [].concat quoteStyle
				for own key, value of quoteStyle
					# Resolve string input to bitwise e.g.
					# 'PATHINFO_EXTENSION' becomes 4
					if OPTS[value] is 0
						noquotes = true
					else if OPTS[value]
						optTemp = optTemp | OPTS[value]
				quoteStyle = optTemp

			if quoteStyle & OPTS.ENT_HTML_QUOTE_SINGLE
				# PHP doesn't currently escape if more than one 0,
				# but it should
				string = string.replace /&#0*39;/g, '\''

			if not noquotes
				string = string.replace /&quot;/g, '"'

			# Put this in last place to avoid escape being double-decoded
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
					# This is kind of hacky - gets the editor to keep
					# the selected text selected after mutation
					editor.find decoded


				htmlEncode: (editor)->
					range = editor.getSelectionRange()
					encoded = Mandrill.util.htmlSpecialChars(
						editor.session.getTextRange( range )
					)
					editor.getSession().getDocument()
						.replace(range, encoded)
					# This is kind of hacky - gets the editor to keep
					# the selected text selected after mutation
					editor.find(encoded)
			}



			###
				Attempts to detect and set the appropriate mode in ace given a
				file path.
			###
			detect_mode: (path, editor)->
				extension = _.last _.last(path.split('/')).split('.')
				for mode,extensions of Mandrill.util.ace.modes
					patt = new RegExp('^\\\.(' + extensions[1] + ')$')
					if patt.test('.' + extension)
						editor.session.setMode('ace/mode/' + mode)
						return

				editor.session.setMode('ace/mode/xml')



			###
				A list of modes and file extensions supported by ace.
			###
			modes: {
				abap:       ["ABAP"         , "abap"]
				asciidoc:   ["AsciiDoc"     , "asciidoc"]
				c9search:   ["C9Search"     , "c9search_results"]
				coffee:     ["CoffeeScript" , "Cakefile|coffee|cf|cson"]
				coldfusion: ["ColdFusion"   , "cfm"]
				csharp:     ["C#"           , "cs"]
				css:        ["CSS"          , "css"]
				curly:      ["Curly"        , "curly"]
				dart:       ["Dart"         , "dart"]
				diff:       ["Diff"         , "diff|patch"]
				dot:        ["Dot"          , "dot"]
				ftl:        ["FreeMarker"   , "ftl"]
				glsl:       ["Glsl"         , "glsl|frag|vert"]
				golang:     ["Go"           , "go"]
				groovy:     ["Groovy"       , "groovy"]
				haxe:       ["haXe"         , "hx"]
				haml:       ["HAML"         , "haml"]
				html:       ["HTML"         , "htm|html|xhtml"]
				c_cpp:      ["C/C++"        , "c|cc|cpp|cxx|h|hh|hpp"]
				clojure:    ["Clojure"      , "clj"]
				jade:       ["Jade"         , "jade"]
				java:       ["Java"         , "java"]
				jsp:        ["JSP"          , "jsp"]
				javascript: ["JavaScript"   , "js"]
				json:       ["JSON"         , "json"]
				jsx:        ["JSX"          , "jsx"]
				latex:      ["LaTeX"        , "latex|tex|ltx|bib"]
				less:       ["LESS"         , "less"]
				lisp:       ["Lisp"         , "lisp"]
				scheme:     ["Scheme"       , "scm|rkt"]
				liquid:     ["Liquid"       , "liquid"]
				livescript: ["LiveScript"   , "ls"]
				logiql:     ["LogiQL"       , "logic|lql"]
				lua:        ["Lua"          , "lua"]
				luapage:    ["LuaPage"      , "lp"]
				lucene:     ["Lucene"       , "lucene"]
				lsl:        ["LSL"          , "lsl"]
				makefile:   ["Makefile"     , "GNUmakefile|makefile|Makefile|OCamlMakefile|make"]
				markdown:   ["Markdown"     , "md|markdown"]
				mushcode:   ["TinyMUSH"     , "mc|mush"]
				objectivec: ["Objective-C"  , "m"]
				ocaml:      ["OCaml"        , "ml|mli"]
				pascal:     ["Pascal"       , "pas|p"]
				perl:       ["Perl"         , "pl|pm"]
				pgsql:      ["pgSQL"        , "pgsql"]
				php:        ["PHP"          , "php|phtml"]
				powershell: ["Powershell"   , "ps1"]
				python:     ["Python"       , "py"]
				r:          ["R"            , "r"]
				rdoc:       ["RDoc"         , "Rd"]
				rhtml:      ["RHTML"        , "Rhtml"]
				ruby:       ["Ruby"         , "ru|gemspec|rake|rb"]
				scad:       ["OpenSCAD"     , "scad"]
				scala:      ["Scala"        , "scala"]
				scss:       ["SCSS"         , "scss"]
				sass:       ["SASS"         , "sass"]
				sh:         ["SH"           , "sh|bash|bat"]
				sql:        ["SQL"          , "sql"]
				stylus:     ["Stylus"       , "styl|stylus"]
				svg:        ["SVG"          , "svg"]
				tcl:        ["Tcl"          , "tcl"]
				tex:        ["Tex"          , "tex"]
				text:       ["Text"         , "txt"]
				textile:    ["Textile"      , "textile"]
				tmsnippet:  ["tmSnippet"    , "tmSnippet"]
				toml:       ["toml"         , "toml"]
				typescript: ["Typescript"   , "typescript|ts|str"]
				vbscript:   ["VBScript"     , "vbs"]
				xml:        ["XML"          , "xml|rdf|rss|wsdl|xslt|atom|mathml|mml|xul|xbl|plist"]
				xquery:     ["XQuery"       , "xq"]
				yaml:       ["YAML"         , "yaml"]
			}
		}
	},



	user: {

		# Returns the user-specific preferences dictionary for the current user
		prefs: ->
			user = Meteor.user()
			if user? and user.mandrill? and user.mandrill.prefs?
				user.mandrill.prefs
			else
				{}


		# Returns the value for a pref key for the current user
		pref: (key)->
			prefs = Mandrill.user.prefs()
			if prefs[key]?
				prefs[key]
			else
				undefined


		# Sets a given pref key's value for the current user
		setPref: (key, val)->
			user = Meteor.user()
			if user? and user._id?
				doc = {}
				doc['mandrill.prefs.'+key] = val
				Meteor.users.update({_id: user._id}, {$set: doc})
			else
				console.warn 'Not updating preferences; no one is logged in.'



		# If the user is banned, this method will log that user out and
		# return true. If not, it will simply return false, as in
		# 'not banned'
		isBanned: (userObject)->
			if userObject? and userObject.mandrill? and userObject.mandrill.isBanned is true
				Meteor.users.update(
					{_id: userObject._id},
					{'$set': {'services.resume.loginTokens':[]}}
				);
				true
			else
				false



		# makes sure the logged in user is an admin, _and_ that the
		# admin isn't banned.
		isAdmin: (userId)->
			if userId?
				user = Meteor.users.findOne(userId)
				admin = user? and user.mandrill? and user.mandrill.isAdmin is true
				admin and Mandrill.user.isBanned(user) is false
			else
				false


		# makes sure there is a logged in user, _and_ that the user
		# isn't banned.
		isValid: (userId)->
			if userId?
				user = Meteor.users.findOne(userId)
				user and Mandrill.user.isBanned(user) is false
			else
				false


		# evaluates the accessPatterns for a given user and returns a
		# mongo filter. This uses the 'path' attribute for the filter
		# field. If query is passed, it is expected to be a normal
		# mongo query which will be applied to, and returned with, the
		# filter query from this function
		accessPatternsFilter: (userId, query)->
			user = Meteor.users.findOne userId, {fields: {
					'mandrill.isAdmin': 1,
					'mandrill.accessPatterns': 1
				}}
			repoPath = MandrillSettings.get 'munkiRepoPath', '/'

			filter = {'$or':[]}

			if not user or not userId
				return {'path': false}

			patterns = user.mandrill.accessPatterns or []

			if Mandrill.user.isAdmin(userId) is true
				# admin means all access
				if query?
					return query
				else
					return {}

			if patterns.length is 0
				# no patterns means no access
				return {'path': false}

			for patt in patterns
				filter.$or.push {
					path: new RegExp('^' + repoPath + patt.pattern)
				}

			if query?
				return {'$and':[filter, query]}

			filter


		canModifyPath: (userId, aPath, throwError)->
			user = Meteor.users.findOne userId, {fields: {
				'mandrill.isAdmin': 1,
				'mandrill.accessPatterns': 1
			}}
			repoPath = MandrillSettings.get 'munkiRepoPath', '/'

			# No user = no access
			if not user? or not userId?
				if throwError is true
					throw new Meteor.Error 403,
						'You can\'t do that without logging in.'
				else
					return false

			# admin = all access
			if Mandrill.user.isAdmin(userId) is true
				return true

			# we've got a non-admin user, so we'll need to look at their
			# access patterns.
			patterns = []
			if user? and user.mandrill? and user.mandrill.accessPatterns?
				patterns = user.mandrill.accessPatterns

			for patt in patterns
				expr = '^' + repoPath + patt.pattern
				if (patt.readonly? is false or patt.readonly isnt true) and RegExp(expr).test(aPath) is true
					return true

			if throwError is true
				throw new Meteor.Error 403,
					'Sorry, that path is read-only for your account.'
			return false
	}
}
