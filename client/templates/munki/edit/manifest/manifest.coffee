Session.setDefault 'memViewMode', 'all'
Session.setDefault 'memEditModes', {adminNotes: false, includedManifests: false}


manifest_flatten = (obj, result=[], conditions=[])->
    keysWeCareAbout = [
        'managed_installs'
        'managed_uninstalls'
        'managed_updates'
        'optional_installs'
    ]

    for key,val of obj # top-level keys; managed_installs, etc.

        if key in keysWeCareAbout

            for item in val # installer items
                result.push {
                    pkg: item
                    installType: key
                    conditions: conditions
                }

        else if key is 'conditional_items'

            for cond_item in val

                if conditions.length > 0
                    # array.slice(0) clones the array; no passing pointers!!
                    tmp_cond = conditions.slice(0)
                    tmp_cond.push cond_item.condition

                else
                    tmp_cond = [cond_item.condition]

                manifest_flatten cond_item, result, tmp_cond
    result


Template.munkiEditManifest.rendered = ->
    data = Router.current().data()
    MunkiRepo.update {_id: data._id}, {
        '$set': {
            draft: {
                author: Meteor.user()._id,
                dom: data.dom
            }
        }
    }


Template.munkiEditManifest.helpers {


    editingAdminNotes: ->
        Session.get('memEditModes').adminNotes


    manifestCatalogs: ->
        data = Router.current().data()
        # data = MunkiRepo.findOne {_id: Router.current().data()._id}
        if data?.draft?.dom?
            manifest = new MunkiManifest data.draft.dom
            manifest.catalogs()
        else
            []

    includedManifests: ->
        data = Router.current().data()
        # data = MunkiRepo.findOne {_id: Router.current().data()._id}
        if data?.draft?.dom?.included_manifests?.push?
            data.draft.dom.included_manifests
        else
            []

    availableCatalogs: ->
        ret = []
        data = Router.current().data()
        # data = MunkiRepo.findOne {_id: Router.current().data()._id}

        if not data?.draft?.dom?
            return ret

        manifest = new MunkiManifest data.draft.dom

        for cat in MunkiManifest.availableCatalogs()
            if manifest.catalogs().indexOf(cat) < 0
                ret.push {catalog:cat, active: false}
            else
                ret.push {catalog:cat, active: true}
        ret


    manifestItems: ->
        data = Router.current().data()
        # data = MunkiRepo.findOne {_id: Router.current().data()._id}
        items = []
        if data?.draft?.dom?
            items = manifest_flatten data.draft.dom
            items.sort (a,b)->
                a.pkg.localeCompare(b.pkg)
        viewMode = Session.get 'memViewMode'
        ret = []
        if viewMode not in ['all', 'conditionals', 'unconditionals']
            for item in items
                if item.installType is viewMode
                    ret.push item
        else if viewMode is 'conditionals'
            for item in items
                if item.conditions.length > 0
                    ret.push item
        else if viewMode is 'unconditionals'
            for item in items
                if item.conditions.length == 0
                    ret.push item
        else
            ret = items

        ret


    namedConditions: ->
        conditions = []
        for condition in this.conditions
            cond = Mandrill.munki.conditions.byCondition condition
            conditions.push cond

        conditions


    viewTypeIs: (type)->
        Session.equals 'memViewMode', type

    currentViewModeName: ->
        switch Session.get 'memViewMode'
            when 'managed_installs' then 'Installs'
            when 'managed_updates' then 'Updates'
            when 'managed_uninstalls' then 'Uninstalls'
            when 'optional_installs' then 'Optionals'
            when 'conditionals' then 'Conditional Items'
            when 'unconditionals' then 'Unconditional Items'
            else
                'All'


    typeMnemonic: (type)->
        type.replace('_', ' ')
            .replace('managed', '')
            .replace(/s$/, '')
            .replace('optional', 'user may')


    isManagedInstall: ->
        if this.installType is 'managed_installs' then 'selected'


    isManagedUpdate: ->
        if this.installType is 'managed_updates' then 'selected'


    isManagedUninstall: ->
        if this.installType is 'managed_uninstalls' then 'selected'


    isOptionalInstall: ->
        if this.installType is 'optional_installs' then 'selected'
}


Template.munkiEditManifest.events {
    'click [data-manifest="install-type"] a': (event)->
        event.preventDefault()
        data = MunkiRepo.findOne({_id: Router.current().data()._id})
        manifest = new MunkiManifest(data.draft.dom)
        newInstallType = $(event.target).attr('href').replace(/^#/, '')
        manifest.changeInstallType(
            this.pkg
            this.installType
            newInstallType
            this.conditions
        )
        MunkiRepo.update {_id: data._id}, {
            '$set': {'draft.dom': manifest.manifestObject}
        }



    'click [data-memView="all"], click [data-memView="managed_installs"], click [data-memView="managed_updates"], click [data-memView="managed_uninstalls"], click [data-memView="optional_installs"], click [data-memView="conditionals"], click [data-memView="unconditionals"]': (event)->
        Session.set 'memViewMode', $(event.target).data("memview")
        # setupSortables()



    # Adds/removes catalogs from the draft manifest
    'click [data-memCatalogs="cat"]': (event)->
        event.stopPropagation()
        event.preventDefault()
        data = MunkiRepo.findOne({_id: Router.current().data()._id})
        manifest = new MunkiManifest(data.draft.dom)
        if this.active is true
            manifest.removeCatalog(this.catalog)
        else
            manifest.insertCatalogAt(this.catalog)

        MunkiRepo.update {_id: data._id}, {
            '$set': {'draft.dom': manifest.manifestObject}
        }


    # displays/hides the admin notes edit field.
    'click [data-memBtn="editAdminNotes"]': (event)->
        event.preventDefault()

        obj = Session.get 'memEditModes'
        obj.adminNotes = !obj.adminNotes
        Session.set 'memEditModes', obj
        if obj.adminNotes is true
            Meteor.setTimeout ->
                $('[data-memedit="adminNotes"]').focus()
            , 50

    # update the admin notes for the draft.
    'blur change [data-memEdit="adminNotes"], change [data-memEdit="adminNotes"]': (event)->
        MunkiRepo.update {_id: Router.current().data()._id}, {
            '$set': {'draft.dom.admin_notes': $(event.target).val()}
        }


    'groupSorted [data-sort="catalogs"]': (event)->
        data = Router.current().data()
        catalogs = event.originalEvent.detail.args.map (it)->
            it.display

        if data?.draft?.dom?
            MunkiRepo.update {_id: data._id}, {
                '$set': {'draft.dom.catalogs': catalogs}
            }

    'groupSorted [data-sort="included_manifests"]': (event)->
        data = Router.current().data()
        manifests = event.originalEvent.detail.args.map (it)->
            it.display

        if data?.draft?.dom?
            MunkiRepo.update {_id: data._id}, {
                '$set': {'draft.dom.included_manifests': manifests}
            }
}
