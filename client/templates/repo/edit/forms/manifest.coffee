repo_edit_form_manifest_flatten = (dom, domKey, result=[])->
    condition = dom.condition

    for key,val of dom[domKey]
        result.push {pkg: val, condition: condition}

    if dom.conditional_items?
        for item in dom.conditional_items
            repo_edit_form_manifest_flatten item, domKey, result
    result.sort (a,b)->
        a.pkg.localeCompare(b.pkg)


repo_edit_form_manifest_columnize = (theArray, cols=3)->
    result = []
    colArray = []
    for item in theArray
        if colArray.length < cols
            colArray.push item
        else
            result.push colArray
            colArray = [item]
    if colArray.length > 0 and colArray.length < cols
        while colArray.length < cols
            colArray.push {}
        result.push colArray
    result


Template.repo_edit_form_manifest.helpers {
    managedInstalls: ->
        data = Router.current().data()
        result = repo_edit_form_manifest_flatten data.dom, 'managed_installs'
        repo_edit_form_manifest_columnize result
}


Template.repo_edit_form_manifest.events {
    'click .media-heading': (event)->
        console.log this
}
