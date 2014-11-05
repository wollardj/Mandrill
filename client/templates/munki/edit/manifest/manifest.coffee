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
    $('.sortable').sortable {
        placeholder: 'list-group-item list-group-item-info'
    }
    $('.sortable').disableSelection()


Template.munkiEditManifest.helpers {

    ###
        Produces an array of strings used to generate the breadcrumb navigation.
    ###
    breadcrumb: ()->
        params_c = Router.current().params.query.c
        crumbs = [{name: 'Munki', url: Router.path 'repo', is_active: false}]
        if params_c?
            url = []
            crumbs.push part for part in Mandrill.path.components(params_c).map (it)->
                url.push it
                {
                    name: it
                    url: Router.path 'repo', {}, {query: "c=" + url.join('/')}
                    is_active: false
                }

            # make the last item in the array the 'active' breadcrumb
            crumbs[crumbs.length - 1].is_active = true
        else if Session.equals('repo_filter', '')
            # since there is no 'c' parameter, we'll make our faux root item
            # the 'active' breadcrumb
            crumbs[0].is_active = true

        crumbs

    flatManifest: ->
        data = MunkiRepo.findOne {_id: Router.current().data()._id}
        items = []
        if data?.draft?.dom?
            items = manifest_flatten data.draft.dom
            items.sort (a,b)->
                a.pkg.localeCompare(b.pkg)
        items


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
}
