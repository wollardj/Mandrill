Session.setDefault 'repo_filter', ''
Session.setDefault 'repo_edit_mode', false

# This can be false, true, or a string. False = no readme. True = loading.
# String = the README.md contents
Session.setDefault 'repo_readme', false


Template.repo.helpers {

    ###
        If the given record is_leaf and it happens to be a pkgsinfo item, we'll
        look for its icon.
    ###
    pkgsinfo_icon: ->
        if this.icon_file?
            icon = MunkiRepo.findOne {_id: this._id}
        else if this.dom?.name?
            icon = MunkiRepo.findOne {icon_name: this.dom.name}
        icon?.url()



    ###
        If there is a README.md file in the current directory, we'll fetch its
        raw contents.
    ###
    detect_readme: ->
        # don't show the readme when there's an active search
        Session.set 'repo_readme', false
        if Session.get('repo_filter') isnt ''
            return

        repo = Munki.repoPath()
        url = Router.current().params.query.c
        path = Mandrill.path.concat(repo, url, 'README.md')
        readme = MunkiRepo.findOne({path: path})
        if readme?
            Session.set 'repo_readme', true
            Meteor.call 'getRawRepoItemContent', readme._id, (err, data)->
                Session.set 'repo_readme', data
                if err?
                    Mandrill.show.error err

        ''




    ###
        Determines if the given item is a protected directory. A protected
        directory is one expected by Munki; catalogs, manifests, pkgs, pkgsinfo,
        icons.
    ###
    is_protected: ->
        protected_dirs = ['catalogs', 'manifests', 'pkgs', 'pkgsinfo', 'icons']
        if not Router.current().params.query.c?
            protected_dirs.indexOf(this.name) isnt -1
        else
            false




    dir_listing: ->
        repo = Munki.repoPath()
        url = Router.current().params.query.c
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
                'dom': true
            }
        }



        # If the user is also searching for something, we need to build that
        # into the search_obj
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
                # concatenating the repo path, cookie crumb url (if any), and
                # the current record.name value and then testing to see if the
                # result matches it.path
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
                record.repoUrl = it.url()

                if it.isManifest()
                    record.url = Router.path 'munkiEditManifest', {}, {
                        query: 'c=' + it.path.replace(repo, '')
                    }
                else
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
}






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
        crumb = Router.current().params.query.c
        name = $(event.target).data('repo-item-name')
        path = Mandrill.path.concat Munki.repoPath(), crumb, name
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
