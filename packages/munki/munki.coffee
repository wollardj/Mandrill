###
    A package for dealing with Munki repos
###


# Scheduled log pruning
Meteor.startup ->
    if Meteor.isServer
        Meteor.setInterval ->
            Munki.pruneLogs()
        , 3600000 # run once per hour



class Munki
    @_setSetting: (key, val)->
        record = MunkiSettings.findOne {'key': key}
        if record?
            MunkiSettings.update {'_id':record._id}, {'$set':{'value': val}}
        else
            MunkiSettings.insert {'key':key, 'value':val}

    @_getSetting: (key)->
        setting = MunkiSettings.findOne {'key': key}
        setting?.value

    @repoPath: (newPath=null)->
        if newPath?
            Munki._setSetting 'repoPath', newPath
        else
            Munki._getSetting 'repoPath'

    @repoUrl: (newUrl=null)->
        if newUrl?
            Munki._setSetting 'repoUrl', newUrl
        else
            Munki._getSetting 'repoUrl'


    ###
        Removes the oldest logs from the database until the total number of
        entries is less than or equal to `max`. Entries are removed in groups
        identified by the `session` field.
    ###
    @pruneLogs: (max=50000)->
        while MunkiLogs.find().fetch().length > max
            lastLog = MunkiLogs.findOne({}, {'sort': {date: 1}})
            MunkiLogs.remove({session:lastLog.session})


    # Compares two version strings and returns values appropriate for
    # sorting; -1, 0, 1
    @versionCompare: (v1='', v2='', options)->
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


    @makeCatalogs: (sanityCheck=true)->
        if Meteor.isClient is true
            throw new Meteor.Error 403, 'Munki.makeCatalogs() may only be called by server code.'

        shell = Meteor.npmRequire 'shelljs'
        plist = Meteor.npmRequire 'plist-native'

        repoPath = Munki.repoPath()
        catalogPath = repoPath + 'catalogs/'
        logId = new Date().getTime()
        catalogs = {all:[]}

        if not repoPath
            throw new Meteor.Error 500, 'Unable to determine the full path to your repo!'


        for pkginfo in MunkiRepo.find({'err': {'$exists': false}}).fetch()
            # skip non-pkginfo files, obviously
            if not pkginfo.isPkginfo()
                continue

            # don't copy admin notes
            if pkginfo.dom.notes?
                delete pkginfo.dom.notes
            # strip out any keys that start with "_"
            # (example: pkginfo _metadata)
            for own key, val of pkginfo.dom
                if key.indexOf('_') is 0
                    delete pkginfo.dom[key]

            # simple sanity checking
            doPkgCheck = true
            if pkginfo.dom.installer_type in ['nopkg', 'apple_update_metadata']
                doPkgCheck = false
            if pkginfo.dom.PackageCompleteURL?
                doPkgCheck = false
            if pkginfo.dom.PackageURL?
                doPkgCheck = false

            if doPkgCheck is true
                if not pkginfo.dom.installer_item_location?
                    MunkiLogs.insert {
                        session: logId
                        date: new Date()
                        type: 'warning'
                        msg: 'file ' + pkginfo.path + ' is missing installer_item_location'
                    }
                    # Skip this pkginfo unless we're running with the force flag
                    if not sanityCheck
                        continue

                # form a path for the installer item location
                installerItemPath = repoPath + 'pkgs/' + pkginfo.dom.installer_item_location

                # Check if the installer item actually exists
                if not shell.test('-f', installerItemPath)
                    MunkiLogs.insert {
                        session: logId
                        date: new Date()
                        type: 'warning'
                        msg: 'Info file ' + pkginfo.path + ' refers to missing installer item ' + pkginfo.dom.installer_item_location
                    }

                    # Skip this pkginfo unless we're running with force flag
                    if not sanityCheck
                        continue

            catalogs.all.push pkginfo.dom
            for catalogName in pkginfo.dom.catalogs
                if not catalogName? or catalogName is ''
                    MunkiLogs.insert {
                        session: logId
                        date: new Date()
                        type: 'warning'
                        msg: 'Info file ' + pkginfo.path + ' has an empty catalog name!'
                    }
                    continue

                if not catalogs[catalogName]?
                    catalogs[catalogName] = []
                catalogs[catalogName].push pkginfo.dom
                MunkiLogs.insert {
                    session: logId
                    date: new Date()
                    type: 'info'
                    msg: 'Adding ' + pkginfo.path + ' to ' + catalogName + '...'
                }

        # clear out old catalogs
        catalogPath = repoPath + 'catalogs/'
        if not shell.test('-d', catalogPath)
            shell.mkdir '-p', catalogPath
        shell.rm '-f', catalogPath + '*'

        # write the new catalogs
        for own key, catalog of catalogs
            catalogPath = repoPath + 'catalogs/' + key
            if shell.test('-f', catalogPath) is true
                MunkiLogs.insert {
                    session: logId
                    date: new Date()
                    type: 'warning'
                    msg: 'catalog ' + key + ' already exists at ' +
                        catalogPath + '. Perhaps this is a non-case sensitive ' +
                        'filesystem and you have catalogs with names differing ' +
                        'only in case?'
                }
            else if catalog.length > 0
                plist.buildString(catalog).to(catalogPath)
                MunkiLogs.insert {
                    session: logId
                    date: new Date()
                    type: 'info'
                    msg: 'Created catalog ' + key + '...'
                }
            else
                MunkiLog.insert {
                    session: logId
                    date: new Date()
                    type: 'warning'
                    msg: 'Did not create catalog ' + key + ' because it is empty'
                }
        logId
