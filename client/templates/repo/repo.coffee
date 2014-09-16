Session.setDefault 'repo_filter', ''
Session.setDefault 'repo_edit_mode', false

# This can be false, true, or a string. False = no readme. True = loading.
# String = the README.md contents
Session.setDefault 'repo_readme', false



###
    Produces an array of strings used to generate the breadcrumb navigation.
###
Template.repo.breadcrumb = ()->
    params_c = Router.current().params.c
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



###
    If there is a README.md file in the current directory, we'll fetch its
    raw contents.
###
Template.repo.detect_readme = ()->
    # don't show the readme when there's an active search
    Session.set 'repo_readme', false
    if Session.get('repo_filter') isnt ''
        return

    repo = MandrillSettings.get 'munkiRepoPath'
    url = Router.current().params.c
    path = Mandrill.path.concat(repo, url, 'README.md')
    readme = MunkiRepo.findOne({path: path})
    if readme?
        Session.set 'repo_readme', true
        Meteor.call 'getRawRepoItemContent', readme._id, (err, data)->
            Session.set 'repo_readme', data
            if err?
                Mandrill.show.error err

    ''




Template.repo.record_is_type = (a_type)->
    colspan = Template.repo.colspan.apply this

    switch a_type
        when 'manifests' then ret = colspan is 2
        when 'pkgsinfo' then ret = colspan is 0
        else ret = false
    ret


###
    Determines if the given item is a protected directory. A protected
    directory is one expected by Munki; catalogs, manifests, pkgs, pkgsinfo,
    icons.
###
Template.repo.is_protected = ()->
    protected_dirs = ['catalogs', 'manifests', 'pkgs', 'pkgsinfo', 'icons']
    if not Router.current().params.c?
        protected_dirs.indexOf(this.name) isnt -1
    else
        false










Template.repo.dir_listing = ()->
    repo = MandrillSettings.get 'munkiRepoPath'
    url = Router.current().params.c
    search_path = new RegExp '^' + Mandrill.path.concat(repo, url, '/')
    repo_filter = Session.get 'repo_filter'
    files = []
    search_obj = {path: search_path}
    search_opts = {
        fields: {
            path: true
            'stat': true
            'icon_name': true
            'icon_file': true
            'dom.version': true
            'dom.catalogs': true
        }
    }



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


    # function used to reduce() the results of each query
    reduce = (file_list, it)->
        # If there's a filter (search) we'll want the relative path of each
        # result so the user knows where each file lives.
        name = it.path.replace search_path, ''
        if not repo_filter
            name = name.replace(/^\/*/, '').split('/')[0]
        if not file_list[name]?
            file_list[name] = it._id
        file_list


    map = (it)->
        record = {}

        # If there's a filter (search) we'll want the relative path of each
        # result so the user knows where each file lives.
        record.name = it.path.replace search_path, ''
        if not repo_filter
            record.name = record.name.replace(/^\/*/, '').split('/')[0]

        if repo_filter
            # the user is searching for something, which means all the
            # results are files.
            record._id = it._id
            record.is_leaf = true
        else
            # The user isn't searching for anything, so we need to find out
            # if the current item is a file or a directory. This is done by
            # concatenating the repo path, cookie crumb url (if any), and the
            # current record.name value and then testing to see if the result
            # matches it.path
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




    # First, we'll just fetch the matching records' path attributes and
    # reduce them into an object {filename: _id}. Only returning the path
    # attribute for the reduce is _much_ faster than asking for the entire
    # record when there are a lot of matches.
    prefetch = MunkiRepo.find(search_obj, {fields:{path: true}}).fetch()
        .reduce reduce, {}

    search_opts.limit = 0
    search_obj = {'$or':[]}
    for key,val of prefetch
        search_opts.limit++
        search_obj['$or'].push {'_id': val}

    if search_obj['$or']? and search_obj['$or'].length
        results = MunkiRepo.find(search_obj, search_opts).fetch()
    else
        results = []

    results = results.map map
    results.sort (a, b)->
        # if a and b are the same type (leaf or not leaf) then we'll compare
        # their names. Otherwise, directories should be above files.
        if (a.is_leaf and b.is_leaf) or (not a.is_leaf and not b.is_leaf)
            a.name.toLowerCase().localeCompare b.name.toLowerCase()
        else if a.is_leaf
            1
        else
            -1
    Session.set 'results_length', results.length
    results






Template.repo.events {
    ###
        Ths user wants to delete something.
    ###
    'click .mandrill-repo-delete-visible': (event)->
        event.stopPropagation()
        event.preventDefault()

        $(event.target).addClass('hidden')

        # If this record represents a directory, we'll need to delete each
        # file container within it - client-side code isn't allowed to
        # delete files without specifying the _id.
        crumb = Router.current().params.c
        name = $(event.target).data('repo-item-name')
        path = MandrillSettings.get 'munkiRepoPath'
        path = Mandrill.path.concat path, crumb, name
        records = MunkiRepo.find({path: new RegExp('^' + path)}).fetch()
        for it in records
            MunkiRepo.remove {_id: it._id}

        Meteor.call 'unlink', path, (err)->
            if err?
                $(event.target).removeClass('hidden')
                Mandrill.show.error(err)
            else
                Mandrill.show.success 'File Deleted', name + ' is no more.'
}
