@MandrillSettings = new Meteor.Collection 'mandrill-settings'


@MandrillSettings.allow {
	'insert': (userId) ->
		Mandrill.user.isAdmin userId
	'update': (userId)->
		Mandrill.user.isAdmin userId
	'remove': (userId)->
		Mandrill.user.isAdmin userId
}




@MandrillSettings.keys = ->
	settings = @findOne()
	keys = []
	ignoreKeys = ['_id', 'keys', 'get', 'set']
	for own key, val of settings
		if ignoreKeys.indexOf(key) is -1
			keys.push key
	keys

@MandrillSettings.get = (key, orDefault)->
	settings = @findOne()
	if settings? and settings[key]?
		settings[key]
	else
		orDefault


@MandrillSettings.set = (key, val)->
	settings = @findOne()
	if settings? and settings._id?
		upd = {'$set': {}}
		upd.$set[key] = val
		@update settings._id, upd
	else
		ins = {}
		ins[key] = val
		@insert ins
