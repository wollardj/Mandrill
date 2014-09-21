Meteor.startup ->
    UI.registerHelper 'munki_pkg_icon_url', (pkg)->
        icon = MunkiRepo.findOne {icon_name: pkg}
        if icon?
            icon.url()
        else
            Meteor.absoluteUrl 'packages/munki/images/pkg.png'

    UI.registerHelper 'munkiItemRelativePath', (item)->
        item?.relativePath()
    UI.registerHelper 'munkiItemUrl', (item)->
        item?.url()

    UI.registerHelper 'munkiRepoPath', ->
        Munki.repoPath()
    UI.registerHelper 'munkiRepoUrl', ->
        Munki.repoUrl()
