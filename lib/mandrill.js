Mandrill = {
	version: '0.6.1',

	// Template rendering helpers
	tpl: {
		activateTooltips: function() {
			$('[data-toggle]').each(function () {
				var element = $(this);
				if (element.data('toggle') === 'tooltip') {
					element.tooltip({
						html: true,
						delay:{show: 500, hide: 250},
						//placement: 'auto'
					});
				}
			});
		}
	},



	// display messages to the user on the client
	show: {
		error: function(e) {
			var code = e.error,
				reason = e.reason,
				dom,
				d = new Date(),
				id = 'mandrill-error_' + d.getTime();

			dom = $('<div id="' + id + '" class="mandrill-error alert ' +
					'alert-danger alert-dismissable fade in">' +
					'<button type="button" class="close" ' +
						'data-dismiss="alert" aria-hidden="true">&times;' +
					'</button>' +
					'<h4>Application Error ' + code + ':</h4>' +
					'<p>' + reason + '</p>' +
					'</div>'
				);

			$('body').append(dom);

			// auto-dismiss after 10 seconds
			window.setTimeout(function() {
				$('#' + id).alert('close');
			}, 10000);
		},


		success: function(title, message) {
			var d = new Date(),
				id = 'mandrill-success_' + d.getTime();

			$('body').append('<div id="' + id +
				'" class="mandrill-error alert alert-success ' +
					'alert-dismissable fade in">' +
				'<button type="button" class="close" ' +
					'data-dismiss="alert" aria-hidden="true">' +
					'&times;' +
				'</button>' +
				(title !== '' ? '<h4>' + title + '</h4>' : '') +
				'<p>' + message + '</p>' +
				'</div>'
			);

			// auto-dismiss after 10 seconds
			window.setTimeout(function() {
				$('#' + id).alert('close');
			}, 10000);
		}
	},




	util: {

		/*
			Thank you, php.js:
			http://phpjs.org/functions/escapeshellarg/
		 */
		escapeShellArg: function(arg) {
			var ret = '';

			// make sure arg is a string
			arg += '';
			ret = arg.replace(/[^\\]"/g, function(m) {
				return m.slice(0, 1) + '\\"';
			});
			return '"' + ret + '"';
		},

		generateRandomString: function(length) {
			var chars = '0123456789abcdefghijklmnopqrstuvwxyz' +
					'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
					'?:"{}!@#$%^&*()_+=-',
				result = '';
			for (var i = length; i > 0; --i) {
				result += chars[Math.round(
					Math.random() * (chars.length - 1))
				];
			}
			return result;
		},


		htmlSpecialChars: function(	target,
									quoteStyle,
									charset,
									doubleEncode) {
			// From: http://phpjs.org/functions

			var optTemp = 0,
				noquotes = false;

			quoteStyle = quoteStyle || 2;

			// Put this first to avoid double-encoding
			if (doubleEncode !== false) {
				target = target.toString().replace(/&/g, '&amp;');
			}
			target = target.toString()
				.replace(/</g, '&lt;')
				.replace(/>/g, '&gt;');

			var OPTS = {
				'ENT_NOQUOTES': 0,
				'ENT_HTML_QUOTE_SINGLE': 1,
				'ENT_HTML_QUOTE_DOUBLE': 2,
				'ENT_COMPAT': 2,
				'ENT_QUOTES': 3,
				'ENT_IGNORE': 4
			};
			if (quoteStyle === 0) {
				noquotes = true;
			}

			// Allow for a single target or an array of target flags
			if (typeof quoteStyle !== 'number') {
				quoteStyle = [].concat(quoteStyle);
				for (var i = 0; i < quoteStyle.length; i++) {
					// Resolve target input to bitwise e.g. 'ENT_IGNORE'
					// becomes 4
					if (OPTS[quoteStyle[i]] === 0) {
						noquotes = true;
					}
					else if (OPTS[quoteStyle[i]]) {
						optTemp = optTemp | OPTS[quoteStyle[i]];
					}
				}
				quoteStyle = optTemp;
			}
			if (quoteStyle & OPTS.ENT_HTML_QUOTE_SINGLE) {
				target = target.replace(/'/g, '&#039;');
			}
			if (!noquotes) {
				target = target.replace(/"/g, '&quot;');
			}

			return target;
		},



		htmlSpecialCharsDecode: function (string, quoteStyle) {
			// From: http://phpjs.org/functions
			var optTemp = 0,
				i = 0,
				noquotes = false;
			quoteStyle = quoteStyle || 2;
			string = string.toString()
				.replace(/&lt;/g, '<')
				.replace(/&gt;/g, '>');

			var OPTS = {
				'ENT_NOQUOTES': 0,
				'ENT_HTML_QUOTE_SINGLE': 1,
				'ENT_HTML_QUOTE_DOUBLE': 2,
				'ENT_COMPAT': 2,
				'ENT_QUOTES': 3,
				'ENT_IGNORE': 4
			};

			if (quoteStyle === 0) {
				noquotes = true;
			}

			// Allow for a single string or an array of string flags
			if (typeof quoteStyle !== 'number') {
				quoteStyle = [].concat(quoteStyle);
				for (i = 0; i < quoteStyle.length; i++) {
					// Resolve string input to bitwise e.g.
					// 'PATHINFO_EXTENSION' becomes 4
					if (OPTS[quoteStyle[i]] === 0) {
						noquotes = true;
					} else if (OPTS[quoteStyle[i]]) {
						optTemp = optTemp | OPTS[quoteStyle[i]];
					}
				}
				quoteStyle = optTemp;
			}

			if (quoteStyle & OPTS.ENT_HTML_QUOTE_SINGLE) {
				// PHP doesn't currently escape if more than one 0,
				// but it should
				string = string.replace(/&#0*39;/g, '\'');
			}

			if (!noquotes) {
				string = string.replace(/&quot;/g, '"');
			}

			// Put this in last place to avoid escape being double-decoded
			string = string.replace(/&amp;/g, '&');

			return string;
		},


		ace: {
			selection: {
				htmlDecode: function(editor) {
					var range = editor.getSelectionRange(),
						decoded = Mandrill.util.htmlSpecialCharsDecode(
							editor.session.getTextRange( range )
						);
					editor.getSession().getDocument()
						.replace(range, decoded);
					// This is kind of hacky - gets the editor to keep
					// the selected text selected after mutation
					editor.find(decoded);
				},


				htmlEncode: function(editor) {
					var range = editor.getSelectionRange(),
						encoded = Mandrill.util.htmlSpecialChars(
							editor.session.getTextRange( range )
						);
					editor.getSession().getDocument()
						.replace(range, encoded);
					// This is kind of hacky - gets the editor to keep
					// the selected text selected after mutation
					editor.find(encoded);
				}
			}
		}
	},



	// helper functions.
	user: {

		// If the user is banned, this method will log that user out and
		// return true. If not, it will simply return false, as in
		// 'not banned'
		isBanned: function(userObject) {
			if (userObject &&
				userObject.mandrill &&
				userObject.mandrill.isBanned === true) {
				
				Meteor.users.update(
					{_id: userObject._id},
					{'$set': {'services.resume.loginTokens':[]}}
				);
				return true;
			}
			return false;
		},



		// makes sure the logged in user is an admin, _and_ that the
		// admin isn't banned.
		isAdmin: function(userId) {
			if (!userId) {
				return false;
			}
			var user = Meteor.users.findOne(userId),
				admin = user && user.mandrill && user.mandrill.isAdmin;
			return admin && !Mandrill.user.isBanned(user);
		},


		// makes sure there is a logged in user, _and_ that the user
		// isn't banned.
		isValid: function(userId) {
			if (!userId) {
				return false;
			}
			var user = Meteor.users.findOne(userId);
			return user && !Mandrill.user.isBanned(user);
		},


		// evaluates the accessPatterns for a given user and returns a
		// mongo filter. This uses the 'path' attribute for the filter
		// field. If query is passed, it is expected to be a normal
		// mongo query which will be applied to, and returned with, the
		// filter query from this function
		accessPatternsFilter: function(userId, query) {
			var user = Meteor.users.findOne(userId, {fields: {
					'mandrill.isAdmin': 1,
					'mandrill.accessPatterns': 1
				}}),
				settings = MandrillSettings.findOne(),
				patterns,
				filter = {'$or':[]};

			if (!user || !userId) {
				return {'path': false};
			}

			repoPath = settings.munkiRepoPath ? settings.munkiRepoPath : '/';
			patterns = user.mandrill.accessPatterns || [];
			
			if (user.mandrill.isAdmin === true) {
				// admin means all access
				if (query) {
					return query;
				}
				return {};
			}

			if (patterns.length === 0) {
				// no patterns means no access
				return {'path': false};
			}

			for (var i = 0; i < patterns.length; i++) {
				filter.$or.push({
					path: new RegExp('^' + repoPath + patterns[i].pattern)
				});
			}
			if (query) {
				return {'$and':[filter, query]};
			}
			return filter;
		},


		canModifyPath: function(userId, aPath, throwError) {
			var user = Meteor.users.findOne(userId, {fields: {
					'mandrill.isAdmin': 1,
					'mandrill.accessPatterns': 1
				}}),
				settings = MandrillSettings.findOne(),
				repoPath = (settings ? settings.munkiRepoPath : '/'),
				patterns,
				expr;

			// No user = no access
			if (!user || !userId) {
				if (throwError === true) {
					throw new Meteor.Error(403, 'You can\'t do that without logging in.');
				}
				return false;
			}

			// admin = all access
			if (user.mandrill.isAdmin === true) {
				return true;
			}

			// we've got a non-admin user, so we'll need to look at their
			// access patterns.
			patterns = user.mandrill.accessPatterns || [];
			repoPath = repoPath ? repoPath : '/';

			for(var i = 0; i < patterns.length; i++) {
				expr = '^' + repoPath + patterns[i].pattern;
				if ((!patterns[i].readonly ||
					patterns[i].readonly !== true) &&
					RegExp(expr).test(aPath) === true) {
					
					return true;
				}
			}

			if (throwError === true) {
				throw new Meteor.Error(403, 'Sorry, that path is read-only for your account.');
			}
			return false;
		}
	}
};