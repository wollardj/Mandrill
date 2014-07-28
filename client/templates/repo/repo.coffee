Session.setDefault 'repo_filter', ''
Session.setDefault 'repo_edit_mode', false
Session.setDefault 'results_length', 0



###
    Produces an array of strings used to generate the breadcrumb navigation.
###
Template.repo.breadcrumb = ()->
    params_c = Router.current().params.c
    crumbs = [{name: 'Munki', url: "?", is_active: false}]
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


###
    Returns the url appropriate for navigating up to the parent (..) directory.
###
Template.repo.dot_dot_url = ()->
    crumbs = Template.repo.breadcrumb()
    parent_crumb = crumbs[crumbs.length - 2]
    if parent_crumb? and parent_crumb.url?
        parent_crumb.url
    else
        # bail out of edit mode when we're at the root of the repo
        Session.set 'repo_edit_mode', false
        null


###
    If the given record is_leaf and it happens to be a pkgsinfo item, we'll look
    for its icon.
###
Template.repo.pkgsinfo_icon = ()->
    repo_url = MandrillSettings.get('SoftwareRepoURL')
    if this._id? and this.icon_name?
        Mandrill.path.concat_relative repo_url, 'icons', this.icon_file

    else if this._id? and this.dom? and this.dom.name?
        icon = MunkiRepo.findOne {icon_name: this.dom.name}
        if icon?
            Mandrill.path.concat_relative repo_url, 'icons', icon.icon_file


Template.repo.file_size = ()->
    suffix = ['B', 'KB', 'MB', 'GB', 'TB']
    if this.stat? and this.stat.size?
        i = 0
        size = this.stat.size
        while size > 1024
            size /= 1024
            i++
        Math.round(size) + suffix[i]
    else
        '??'


###
    If there is a README.md file in the current directory, we'll fetch its
    raw contents.
###
Template.repo.readme = ()->
    # don't show the readme when there's an active search
    if Session.get('repo_filter') isnt ''
        return

    repo = MandrillSettings.get 'munkiRepoPath'
    url = Router.current().params.c
    path = Mandrill.path.concat(repo, url, 'README.md')
    readme = MunkiRepo.findOne({path: path})
    if readme? and readme.raw?
        readme.raw



###
    Returns the number to be used in the first column's colspan attribute
    based on the type of record and with the assumption that it's a 3 column
    table
        manifests = 2
        pkgsinfo = 1
        everything else = 3
###
Template.repo.colspan = ()->
    repo = MandrillSettings.get 'munkiRepoPath'
    c = Router.current().params.c

    # If this item isn't a leaf node, then we know it's not going to have any
    # content to display in other columns
    if not this.is_leaf
        return 3

    if c? then path = Mandrill.path.concat(repo, c, this.name)
    else path = Mandrill.path.concat(repo, this.name)

    m_path = new RegExp '^' + Mandrill.path.concat(repo, 'manifests/')
    p_path = new RegExp '^' + Mandrill.path.concat(repo, 'pkgsinfo/')

    # manifests
    if m_path.test path then 2
    # pkgsinfo
    else if p_path.test path then 0
    # everything else
    else 3


Template.repo.record_is_type = (a_type)->
    colspan = Template.repo.colspan.apply this

    switch a_type
        when 'manifests' then ret = colspan is 2
        when 'pkgsinfo' then ret = colspan is 0
        else ret = false
    ret


###
    Determines if the given item is a protected directory. A protected directory
    is one expected by Munki; catalogs, manifests, pkgs, pkgsinfo, icons
###
Template.repo.is_protected = ()->
    protected_dirs = ['catalogs', 'manifests', 'pkgs', 'pkgsinfo', 'icons']
    if not url = Router.current().params.c?
        protected_dirs.indexOf(this.name) isnt -1
    else
        false





###
    Here's the magic.
###
Template.repo.dir_listing = ()->
    Meteor.user()
    Session.set 'repo_readme', ''
    repo = MandrillSettings.get 'munkiRepoPath'
    url = Router.current().params.c
    results_limit = Session.get 'results_limit'
    repo_filter = Session.get 'repo_filter'
    files = []
    search_path = new RegExp( '^' + Mandrill.path.concat(repo, url) + '/' )
    search_obj = {path: search_path}
    search_opts = {
        fields: {
            path: true
            'stat': true
            'icon_name': true
            'icon_file': true
            'dom.name': true
            'dom.display_name': true
            'dom.version': true
            'dom.catalogs': true
        }
    }
    search_opts = {}


    # If the user is also searching for something, we need to build that into
    # the search_obj
    if repo_filter
        search_obj = {'$and':[search_obj]}
        filter_regexp = new RegExp('.*' + repo_filter + '.*', 'i')
        search_obj['$and'].push {
            '$or': [
                {path: filter_regexp}
                {'dom.name': filter_regexp}
                {'dom.display_name': filter_regexp}
                {'dom.version': filter_regexp}
                {'dom.catalogs': filter_regexp}
                {'dom.managed_installs': filter_regexp}
                {'dom.managed_uninstalls': filter_regexp}
                {'dom.managed_updates': filter_regexp}
                {'dom.optional_installs': filter_regexp}
                {'dom.conditional_items.condition': filter_regexp}
            ]
        }

    # function used to map() the results of each query
    reduce_path_map = (it)->
        # If there's a filter (search) we'll want the relative path of each
        # result so the user knows where each file lives.
        record = { name: it.path.replace(search_path, '') }
        if not repo_filter
            # If there's no filter (search), we'll just want the relative
            # name of each item in the results
            record.name = record.name
                .replace(/^\/*/, '')
                .split('/')[0]

        # return a null value if the current path component has already
        # been returned at least once.
        if -1 isnt files.indexOf record.name
            return null
        # if we're still here, it's a unique result,
        files.push record.name

        if repo_filter
            # the user is searching for something, which means all the
            # results are files.
            record._id = it._id
            record.is_leaf = true
        else
            # The user isn't searching for anything, so we need to find out
            # if the current item is a file or a directory. This is done by
            # rebuilding the concatenating the munki repo, the url (?c) and
            # the current record.name value and then testing to see if that
            # exact string matches the current record's path (it.path).
            full_component_path = Mandrill.path.concat(repo, url, record.name)
            record.is_leaf = it.path is full_component_path.replace(/\/*$/, '')
            if record.is_leaf is true
                record._id = it._id

        if record.is_leaf is true
            if it.dom?
                record.dom = it.dom
            if it.icon_name? and it.icon_file?
                record.icon_name = it.icon_name
                record.icon_file = it.icon_file
            if it.stat?
                record.stat = it.stat
            record.url = Router.path 'repo_edit', {}, {
                query: 'c=' + it.path.replace(repo, '')
            }
        else
            record.url = Router.path 'repo', {}, {
                query: 'c=' + Mandrill.path.concat(url, record.name)
            }
        record



    # obtain all of the paths that match the current set of bread crumbs.
    # e.g. search ALL the things.
    timing = {}
    profile = (key, start)->
        timing[key] = Math.round(
            (performance.now() - start) * 100
        ) / 100 + 'ms'
    start = performance.now()
    results = MunkiRepo.find(search_obj, search_opts).fetch()
    profile 'fetch', start
    start = performance.now()
    results = results.map(reduce_path_map)
    profile 'map', start

    # filter the null values and sort the results
    start = performance.now()
    results = _.compact results
    profile 'filter', start

    start = performance.now()
    results.sort (a, b)->
        # if a and b are the same type (leaf or not leaf) then we'll compare
        # their names. Otherwise, directories should be above files.
        if (a.is_leaf and b.is_leaf) or (not a.is_leaf and not b.is_leaf)
            a.name.toLowerCase().localeCompare b.name.toLowerCase()
        else if a.is_leaf
            1
        else
            -1
    profile 'sort', start
    # return the first 'results_limit' results, unless that value is -1, in
    # which case, we'll just return everything.
    Session.set 'results_length', results.length
    console.log timing
    results


Template.repo.events {
    ###
        Toggle the display of the delete buttons for each row.
    ###
    'click #repo_edit': (event)->
        event.preventDefault()
        event.stopPropagation()
        $(event.target).blur()
        if Session.equals('repo_edit_mode', false)
            Session.set 'repo_edit_mode', true
        else
            Session.set 'repo_edit_mode', false


    ###
        Ths user wants to delete something.
    ###
    'click .mandrill-repo-delete-visible': (event)->
        event.stopPropagation()
        event.preventDefault()

        # If this record represents a directory, we'll need to delete each
        # file container within it - client-side code isn't allowed to
        # delete files without specifying the _id.
        path = MandrillSettings.get 'munkiRepoPath'
        path = Mandrill.path.concat path, this.url.replace(/^\?c=\/*/, '')
        records = MunkiRepo.find({path: new RegExp('^' + path)}).fetch()
        for it in records
            MunkiRepo.remove {_id: it._id}

        Meteor.call 'unlink', path, (err)->
            if err?
                Mandrill.show.error(err)



    ###
        When the user searches for a string more than 2 characters in length,
        we'll update the `repo_filter` session variable, which allows reactive
        magic to happen.
    ###
    'keyup .search': (event)->
        clearTimeout Template.repo.filter_timeout
        val = $(event.target).val()
        if val.length <= 2
            val = ''
        Template.repo.filter_timeout = setTimeout ()->
            Session.set 'repo_filter', val
        , 150

    ###
        When the user presses the escape key while focus is on the search field,
        we'll reset the `repo_filter` session variable to '' and blur the user's
        focus, allowing the CSS transition to shrink the search field back to
        its original size.
    ###
    'click #clear_repo_filter, keydown .search': (event)->
        # blur on esc - also cancel the current search if there is one.
        if not event.keyCode? or event.keyCode is 27
            event.preventDefault()
            event.stopPropagation()
            Session.set 'repo_filter', ''
            $(event.target).val('').blur()
}
