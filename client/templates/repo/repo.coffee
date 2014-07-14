Session.setDefault 'repo_filter', ''

###
    Produces an array of strings used to generate the breadcrumb navigation.
###
Template.repo.breadcrumb = ()->
    base_breadcrumb = {name: 'Munki', url: "?", is_active: false}
    r = Router.current()
    if r.params.c?
        url = []
        crumbs = Mandrill.path.components(r.params.c).map (it)->
            url.push it
            {name: it, url: "?c=" + url.join('/'), is_active: false}
        crumbs.splice 0, 0, base_breadcrumb
        crumbs[crumbs.length - 1].is_active = true
        crumbs
    else
        base_breadcrumb.is_active = true
        [base_breadcrumb]


###
    Returns the url appropriate for navigating up to the parent directory.
###
Template.repo.dot_dot_url = ()->
    crumbs = Template.repo.breadcrumb()
    parent_crumb = crumbs[crumbs.length - 2]
    if parent_crumb? and parent_crumb.url?
        parent_crumb.url
    else
        null



###
    Returns the user's `repo_filter` (a.k.a. 'search')
###
Template.repo.filter = ()->
    Session.get 'repo_filter'



###
    Here's the magic.
###
Template.repo.dir_listing = ()->
    repo = MandrillSettings.get 'munkiRepoPath'
    url = Router.current().params.c
    files = []
    search_path = new RegExp( '^' + Mandrill.path.concat(repo, url) + '/' )
    search_obj = {path: search_path}
    search_opts = {fields: {path: true}, sort:{path:1}}

    # If the user is also searching for something, we need to build that into
    # the search_obj
    repo_filter = Session.get 'repo_filter'
    if repo_filter
        search_obj = {'$and':[search_obj]}
        filter_regexp = new RegExp('.*' + repo_filter + '.*', 'i')
        search_obj['$and'].push {path: filter_regexp}

    # function used to map() the results of each query
    reduce_path_map = (it)->
        record = {}
        if repo_filter
            record.name = it.path.replace(search_path, '')
        else
            record.name = it.path
                .replace(search_path, '')
                .replace(/^\/*/, '')
                .split('/')[0]

        # return a null value if the current path component has already
        # been returned at least once.
        if -1 isnt files.indexOf record.name
            return null
        else
            files.push record.name

        # let's find out if this component is the last one in the path
        # for the current record
        if repo_filter
            record.url = '?c=' + it.path.replace(repo, '')
            record.is_leaf = true
        else
            full_component_path = Mandrill.path.concat(repo, url, record.name)
            record.url = '?c=' + Mandrill.path.concat(url, record.name)
            record.is_leaf = it.path is full_component_path.replace(/\/*$/, '')
        record


    # obtain all of the paths that match the current set of bread crumbs.
    results = MunkiManifests.find(search_obj, search_opts)
        .fetch().map(reduce_path_map)
        .concat( MunkiCatalogs.find(search_obj, search_opts)
            .fetch().map(reduce_path_map) )
        .concat( MunkiPkgsinfo.find(search_obj, search_opts)
            .fetch().map(reduce_path_map) )

    # filter out the null values.
    while results.indexOf(null) isnt -1
        results.splice results.indexOf(null), 1

    # return the results
    results.sort (a, b)->
        if (a.is_leaf and b.is_leaf) or (not a.is_leaf and not b.is_leaf)
            a.name.toLowerCase().localeCompare b.name.toLowerCase()
        else if a.is_leaf
            1
        else
            -1




Template.repo.events {

    ###
        When the user searches for a string more than 2 characters in length,
        we'll update the `repo_filter` session variable, which allows reactive
        magic to happen.
    ###
    'keyup .search': (event)->
        val = $(event.target).val()
        if val.length > 2
            Session.set 'repo_filter', val
        else
            Session.set 'repo_filter', ''

    ###
        When the user presses the escape key while focus is on the search field,
        we'll reset the `repo_filter` session variable to '' and blur the user's
        focus, allowing the CSS transition to shrink the search field back to
        its original size.
    ###
    'keydown .search': (event)->
        # blur on esc
        if event.keyCode is 27
            event.stopPropagation()
            event.preventDefault()
            Session.set 'repo_filter', ''
            $(event.target).val('').blur()
}
