Template.repo_edit_tabs_git_commit.hasChanges = ->
    ace = Template.repo_edit.ace()
    if ace?
        ace.hasChanges()
