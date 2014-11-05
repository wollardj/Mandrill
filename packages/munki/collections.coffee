MunkiSettings = new Mongo.Collection 'munki_settings'
MunkiLogs = new Mongo.Collection 'munki_logs'

MunkiLogs.allow {
    'insert': -> false
    'update': -> false
    'remove': -> false
}


###
    The MunkiRepo collection doesn't define any access or publication rules.
    That's left up to the implementing application.
###
MunkiRepo = new Mongo.Collection 'munki_repo', {transform: (doc)->

    doc.isIcon = ->
        this.icon_name?

    doc.isCatalog = ->
        /^\/*catalogs\//.test(this.path) is true and this.dom?[0]?.name?

    doc.isPkginfo = ->
        d = this.dom
        not this.isCatalog() and d?.name?

    doc.isManifest = ->
        d = this.dom
        d? and (d.managed_installs? or d.managed_uninstalls? or d.managed_updates? or d.optional_installs? or d.conditional_items? or d.included_manifests?)

    doc.isBinary = ->
        not this.dom? and not this.raw? and this.stats?.size > 0


    doc.relativePath = ->
        repoPath = Munki.repoPath()
        this.path.replace(repoPath, '').replace(/^\/*/, '')

    doc.url = ->
        Munki.repoUrl().replace(/\/*$/, '') + '/' + this.relativePath()

    doc
}
