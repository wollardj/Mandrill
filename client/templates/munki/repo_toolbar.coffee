REPO_TPL_MANIFEST = {
    catalogs: []
    included_manifests: []
    managed_installs: []
    managed_uninstalls: []
    managed_updates: []
    optional_installs: []
}

REPO_TPL_PKGINFO = {
    _metadata: {
        created_by: Meteor.user.username
        creation_date: new Date()
        mandrill_version: Mandrill.version
        user_agent: window.navigator.userAgent
    }
    catalogs: ['dev']
    name: ''
    display_name: ''
    version: ''
    installer_type: 'nopkg'
    installcheck_script: "#!/bin/bash\n\necho 'Do good things here.'"
    notes: ''
    unattended_install: true
}


Session.setDefault 'creating_new_repo_item', false


Template.repo_toolbar.events {
    ###
        Toggle the display of the delete buttons for each row.
    ###
    'click #repo_edit': (event)->
        $(event.target).blur()
        if Session.equals('repo_edit_mode', false)
            Session.set 'repo_edit_mode', true
        else
            Session.set 'repo_edit_mode', false


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
            Session.set 'repoSearchLimit', 50
        , 400

    ###
        When the user presses the escape key while focus is on the search field,
        we'll reset the `repo_filter` session variable to '' and blur the user's
        focus, allowing the CSS transition to shrink the search field back to
        its original size.
    ###
    'keydown .search': (event)->
        # blur on esc - also cancel the current search if there is one.
        if not event.keyCode? or event.keyCode is 27
            event.preventDefault()
            event.stopPropagation()
            Session.set 'repo_filter', ''
            $(event.target).val('').blur()



    # the modal which displays the new repo item form has appeared.
    'shown.bs.modal .modal' : (event)->
        crumb = Router.current().params.query.c
        $(event.target).find('input').focus()
        if /^\/*manifests/.test(crumb)
            $('[data-tpl="manifest"]').click()
        else if /^\/*pkgsinfo/.test(crumb)
            $('[data-tpl="pkginfo"]').click()
        else
            $('[data-tpl="text"]').click()


    # The user is selecting a template
    'click #newRepoItemTpl > button': (event)->
        event.preventDefault()
        event.stopPropagation()
        $(event.target).addClass('active').siblings().removeClass('active')


    # The user clicked the create button on the new repo item form
    'click #newRepoItemCreate': (event)->
        tpl = $('#newRepoItemModal button.active').data('tpl')
        path = $('#newRepoItemPath').val()
        data = if tpl is 'manifest' then REPO_TPL_MANIFEST else if tpl is 'pkginfo' then REPO_TPL_PKGINFO else ''
        remoteCall = if data is '' then 'filePutContents' else 'filePutContentsUsingObject'

        fullPath = Mandrill.path.concat(
            Munki.repoPath()
            path
        )

        # if the path specified already exists, let's just redirect the user
        # to that record instead of potentially destroying data.
        existingItem = MunkiRepo.findOne({path: fullPath})
        if existingItem?
            $('#newRepoItemModal').modal('hide')
            Meteor.setTimeout ->
                Router.go('repo_edit', null, {query:'c=' + path})
            , 500
        else
            Session.set 'creating_new_repo_item', true
            Meteor.call remoteCall, fullPath, data, 'Created ' + _.last(Mandrill.path.components(fullPath)), (err, data)->
                Session.set 'creating_new_repo_item', false
                $('#newRepoItemModal').modal('hide')
                if err?
                    Mandrill.show.error(err)
                else
                    Meteor.setTimeout ->
                        Router.go('repo_edit', null, {query:'c=' + path})
                    , 500

}
