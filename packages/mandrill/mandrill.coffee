class Mandrill

    @version: '0.8.0'

    @conditions: MandrillConditions


    # methods for handling strings as paths
    @path: {
        components: (aString)->
            aString
                .replace(/^\/*/, '') # remove leading '/'
                .replace(/\/*$/, '') # remove trailing '/'
                .split('/')


        # takes one or more strings as arguments and creates a single
        # absolute (starts with '/') path.
        concat: ->
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
        concatRelative: ->
            Mandrill.path.concat.apply(null, arguments).replace(/^\/*/, '')


        # Determines if a path has an extension that is a common image type
        isImage: (path)->
            patt = new RegExp "(tif|tiff|gif|ico|jpg|jpeg|jif|jfif|" +
                "jp2|jpx|j2k|j2c|fpx|pcd|png)$", 'i'
            patt.test path
    }



    @tpl: {
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



    @show: {
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




    @util: {
        #
        #	Thank you, php.js:
        #	http://phpjs.org/functions/escapeshellarg/
        #
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
    }



    @user: {

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
            repoPath = Munki.repoPath()

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
            repoPath = Munki.repoPath()

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
