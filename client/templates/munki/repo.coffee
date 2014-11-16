Session.setDefault 'repo_filter', ''
Session.setDefault 'repo_edit_mode', false
Session.setDefault 'repoSearchLimit', 50

# This can be false, true, or a string. False = no readme. True = loading.
# String = the README.md contents
Session.setDefault 'repo_readme', false


Template.repo.rendered = ->
    Session.set 'repoSearchLimit', 50
    Template.repo.currentDirListing = []


Template.repo.helpers {
    ###
        Takes a guess at whether or not there might be more results to show.
    ###
    moreResultsPossible: ->
        Session.get('results_length') == Session.get('repoSearchLimit')

    ###
        If the given record is_leaf and it happens to be a pkgsinfo item, we'll
        look for its icon.
    ###
    hasIcon: ->
        this.icon_name? or this.isPkginfo()

    pkgsinfo_icon: ->
        Router.path 'munki.iconUrl', {name: this.dom.name}


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
            #limit: Session.get 'repoSearchLimit'
            fields: {
                path: true
                'stat.mtime': true
                'icon_name': true
                'icon_file': true
                'dom.name': true
                'dom.version': true
                # items to satisfy the isManifest() method of the MunkiRepo
                # records.
                'dom.managed_installs': true
                'dom.managed_uninstalls': true
                'dom.managed_updates': true
                'dom.optional_installs': true
                'dom.included_manifests': true
                'dom.catalogs': true
                'dom.conditional_items': true
            }
        }



        # If the user is also searching for something, we need to build that
        # into the search_obj
        if repo_filter
            search_obj = {'$and':[search_obj]}
            filter_regexp = new RegExp(repo_filter, 'i')
            search_obj['$and'].push {
                '$or': [
                    {path: new RegExp('/^' + repo + '.*' + filter_regexp)}
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
        reduce = (prevRet, it, index, origArray)->
            if not prevRet.push?
                prevRet = [prevRet]

            localRepo = Mandrill.path.concat(
                repo
                Router.current().params.query.c
            ) + '/'

            prefix = it.path.match(new RegExp('^' + localRepo + '[^\/]*'))[0]

            if prefix is it.path
                prefixReg = new RegExp('^' + prefix + '$')
            else
                prefixReg = new RegExp('^' + prefix + '\/')

            found = false
            for record in prevRet
                if record.path.match(prefixReg)
                    found = true
                    break

            if not found
                prevRet.push(it)
            prevRet




        map = (it)->
            record = it

            # If there's a filter (search) we'll want the relative path of each
            # result so the user knows where each file lives.
            record.name = it.path.replace search_path, ''
            if not repo_filter
                path = Mandrill.path.concat(
                    repo
                    Router.current().params.query.c
                ) + '/'

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
                full_component_path = Mandrill.path.concat(
                    repo
                    url
                    record.name
                )

                record.is_leaf = it.path is full_component_path.replace(
                    /\/*$/
                    ''
                )

                if record.is_leaf is true
                    record._id = it._id

            if record.is_leaf is true
                record.repoUrl = it.url()

                if it.isManifest()
                    record.editUrl = Router.path 'munkiEditManifest', {}, {
                        query: 'c=' + it.path.replace(repo, '')
                    }
                else
                    record.editUrl = Router.path 'repo_edit', {}, {
                        query: 'c=' + it.path.replace(repo, '')
                    }
            else
                record.editUrl = Router.path 'repo', {}, {
                    query: 'c=' + Mandrill.path.concat(url, record.name)
                }
            record


        results = MunkiRepo.find(search_obj, search_opts).fetch()
        results = results.reduce reduce, []

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

        target = $(event.target)

        # If this record represents a directory, we'll need to delete each
        # file container within it - client-side code isn't allowed to
        # delete files without specifying the _id.
        name = _.last this.path.split('/')
        _id = this._id

        if name? and _id?
            originalContent = target.html()
            target.addClass 'text-center'
                .html '<i class="fa fa-cog fa-spin"></i>'
            Meteor.call 'unlink', this.path, (err)->
                if err?
                    target.removeClass 'text-center'
                        .html originalContent
                    Mandrill.show.error(err)
                else
                    MunkiRepo.remove {_id: _id}
                    Mandrill.show.success 'File Deleted', name + ' is no more.'
        else
            Mandrill.show.error(new Meteor.Error('', 'Some information was missing. Nothing was deleted.'))


    ###
        The user opted to increase the search limit by 25
    ###
    'click [data-load="more"]': (event)->
        event.preventDefault()
        #event.stopPropagation()
        Session.set 'repoSearchLimit', Session.get('repoSearchLimit') + 25
}
