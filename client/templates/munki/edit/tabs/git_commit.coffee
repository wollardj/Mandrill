Session.setDefault 'save_in_progress', false


Template.repo_edit_tabs_git_commit.helpers {
    hasChanges: ->
        MandrillAce.getInstance().hasChanges()


    item_filename: ->
        crumb = Router.current().params.query.c
        _.last crumb.split('/')
}


Template.repo_edit_tabs_git_commit.events {
    "click #commit-changes, form submit": (event)->
        event.preventDefault()
        event.stopPropagation()
        subjectField = $("#git-subject")
        bodyField = $("#git-body")

        record = Router.current().data()
        documentText = MandrillAce.getInstance().value()
        subject = subjectField.attr("placeholder")
        body = bodyField.val()

        if subjectField.val() isnt ''
            subject = subjectField.val()

        Session.set 'save_in_progress', true
        Meteor.call 'filePutContents',
            record.path,
            documentText,
            subject,
            body,
            (err, data) ->
                Session.set 'save_in_progress', false
                if err?
                    Mandrill.show.error(err)
                else
                    subjectField.val('')
                    bodyField.val('')
                    MandrillAce.getInstance().setValue(documentText, -1)
}