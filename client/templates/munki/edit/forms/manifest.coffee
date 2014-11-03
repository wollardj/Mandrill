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
                    # array.slize(0) clones the array; no passing pointers!!
                    tmp_cond = conditions.slice(0)
                    tmp_cond.push cond_item.condition

                else
                    tmp_cond = [cond_item.condition]

                manifest_flatten cond_item, result, tmp_cond
    result


Template.repo_edit_form_manifest.rendered = ->
    data = Router.current().data()
    MunkiRepo.update {_id: data._id}, {
        '$set': {
            draft: {
                author: Meteor.user()._id,
                dom: data.dom
            }
        }
    }


Template.repo_edit_form_manifest.helpers {

    flatManifest: ->
        data = MunkiRepo.findOne {_id: Router.current().data()._id}
        if data?.draft?.dom?
            ret = manifest_flatten data.draft.dom
            ret.sort (a,b)->
                a.pkg.localeCompare(b.pkg)
        else
            []


    typeMnemonic: (type)->
        type.replace('_', ' ').replace('managed', 'always').replace(/s$/, '').replace('optional', 'user may')


    isManagedInstall: ->
        if this.installType is 'managed_installs' then 'selected'


    isManagedUpdate: ->
        if this.installType is 'managed_updates' then 'selected'


    isManagedUninstall: ->
        if this.installType is 'managed_uninstalls' then 'selected'


    isOptionalInstall: ->
        if this.installType is 'optional_installs' then 'selected'
}


Template.repo_edit_form_manifest.events {
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
}
