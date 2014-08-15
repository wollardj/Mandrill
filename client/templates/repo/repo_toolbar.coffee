###
    Returns the url appropriate for navigating up to the parent (..) directory.
###
Template.repo_toolbar.dot_dot_url = ()->
    crumbs = Template.repo.breadcrumb()
    parent_crumb = crumbs[crumbs.length - 2]
    if parent_crumb? and parent_crumb.url?
        parent_crumb.url
    else
        # bail out of edit mode when we're at the root of the repo
        Session.set 'repo_edit_mode', false
        null





Template.repo_toolbar.events {
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
    'keydown .search': (event)->
        # blur on esc - also cancel the current search if there is one.
        if not event.keyCode? or event.keyCode is 27
            event.preventDefault()
            event.stopPropagation()
            Session.set 'repo_filter', ''
            $(event.target).val('').blur()
}
