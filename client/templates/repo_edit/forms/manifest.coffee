Template.repo_edit_form_manifest.managedInstalls = ->
    data = Router.current().data()
    managedInstalls = []
    flatten = (dom)->
        condition = dom.condition
        for key,val of dom.managed_installs
            managedInstalls.push {pkg: val, condition: condition}

        if dom.conditional_items?
            for item in dom.conditional_items
                flatten item

    flatten data.dom

    managedInstalls.sort (a,b)->
        a.pkg.localeCompare(b.pkg)
