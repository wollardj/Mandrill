Meteor.startup ->
    Session.setDefault '__munki__cachedPkgMetaData', {}

    UI.registerHelper 'munki_pkg_icon_url', (pkg)->
        meta = Session.get '__munki__cachedPkgMetaData'
        if not meta[pkg]?.icon_url?
            meta[pkg] ?= {}
            icon = MunkiRepo.findOne {icon_name: pkg}
            if icon?
                meta[pkg].icon_url = icon.url()
            else
                meta[pkg].icon_url = Meteor.absoluteUrl 'packages/munki/images/pkg.png'
            Session.set '__munki__cachedPkgMetaData', meta

        meta[pkg].icon_url


    UI.registerHelper 'munki_pkg_display_name', (pkg)->
        meta = Session.get '__munki__cachedPkgMetaData'
        if not meta[pkg]?.display_name?
            meta[pkg] ?= {}
            result = MunkiRepo.findOne(
                {"dom.name": pkg, path:/pkgsinfo/}
                {
                    'fields': {'dom.name': true, 'dom.display_name': true}
                    '$sort':{'dom.version': -1}
                }
            )

            if result?.dom?.display_name?
                meta[pkg].display_name = result.dom.display_name
            else
                meta[pkg].display_name = pkg
            Session.set '__munki__cachedPkgMetaData', meta
        meta[pkg].display_name


    UI.registerHelper 'munkiItemRelativePath', (item)->
        item?.relativePath()
    UI.registerHelper 'munkiItemUrl', (item)->
        item?.url()

    UI.registerHelper 'munkiRepoPath', ->
        Munki.repoPath()
    UI.registerHelper 'munkiRepoUrl', ->
        Munki.repoUrl()
