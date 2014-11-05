Session.setDefault 'mandrillConditionsButtonEditModeActive', false
Session.setDefault 'mandrillConditionsButtonViewMode', 'all'


Template.mandrillConditionsButton.rendered = ->
    $('#mcbTabDefault').tab('show')


Template.mandrillConditionsButton.helpers {
    conditions: ->
        conditions = MandrillConditions.all()
        ret = []
        switch Session.get 'mandrillConditionsButtonViewMode'
            when 'named'
                for cond in conditions
                    if cond.name != cond.condition
                        ret.push cond
            when 'unnamed'
                for cond in conditions
                    if cond.name == cond.condition
                        ret.push cond
            else
                ret = conditions
        ret


    editModeActive: ->
        Session.get 'mandrillConditionsButtonEditModeActive'

    viewModeAll: ->
        Session.equals 'mandrillConditionsButtonViewMode', 'all'

    viewModeNamed: ->
        Session.equals 'mandrillConditionsButtonViewMode', 'named'

    viewModeUnnamed: ->
        Session.equals 'mandrillConditionsButtonViewMode', 'unnamed'

    name: ->
        if this.name == this.condition
            ''
        else
            this.name
}



Template.mandrillConditionsButton.events {

    # reset everything to the default values when the modal is to be shown
    'show.bs.modal #mandrillConditionsButtonModal': (event)->
        Session.set 'mandrillConditionsButtonEditModeActive', false
        Session.set 'mandrillConditionsButtonViewMode', 'all'
        $('#mcbTabControls a[href="#mcbTabDefault"]').tab('show')


    # toggle edit mode
    'click [data-mcbBtn="edit"]': (event)->
        current = Session.get 'mandrillConditionsButtonEditModeActive'
        Session.set 'mandrillConditionsButtonEditModeActive', not current

        if current # if we're not in edit mode
            switch Session.get 'mandrillConditionsButtonViewMode'
                when 'named'
                    $('#mcbTabControls a[href="#mcbTabNamed"]').tab('show')
                when 'unnamed'
                    $('#mcbTabControls a[href="#mcbTabUnnamed"]').tab('show')
                else
                    $('#mcbTabControls a[href="#mcbTabDefault"]').tab('show')
        else
            $('#mcbTabControls a[href="#mcbTabEditMode"]').tab('show')


    # switch to 'all' view mode
    'click [data-mcbView="all"]': (event)->
        Session.set 'mandrillConditionsButtonViewMode', 'all'
        if not Session.get 'mandrillConditionsButtonEditModeActive'
            $('#mcbTabControls a[href="#mcbTabDefault"]').tab('show')


    # switch to 'named' view mode
    'click [data-mcbView="named"]': (event)->
        Session.set 'mandrillConditionsButtonViewMode', 'named'
        if not Session.get 'mandrillConditionsButtonEditModeActive'
            $('#mcbTabControls a[href="#mcbTabNamed"]').tab('show')


    # switch to 'unnamed' view mode
    'click [data-mcbView="unnamed"]': (event)->
        Session.set 'mandrillConditionsButtonViewMode', 'unnamed'
        if not Session.get 'mandrillConditionsButtonEditModeActive'
            $('#mcbTabControls a[href="#mcbTabUnnamed"]').tab('show')


    # scan the repo for additional conditions that might be missing from
    # the list.
    'click [data-mcbBtn="scanForConditions"]': (event)->
        MandrillConditions.scanRepoForConditions()


    # The user apparently doesn't have any conditions and wants some examples
    'click [data-mcbBtn="addExamples"]': (event)->
        event.preventDefault()
        MandrillConditions.addDefaultConditionNamePairs()


    # The user want's to add a new custom record
    'click [data-mcbBtn="new"]': (event)->
        name = $('#mcbNewName').val()
        condition = $('#mcbNewCondition').val()

        existingCond = MandrillConditions.byName(name)

        if not condition
            alert "I'll make you a deal. If you _define_ your condition, I won't force you to name it."
            $('#mcbNewCondition').focus()

        else if existingCond and existingCond.condition isnt condition
            alert('You already have another condition with that name.')
            $('#mcbNewName').focus()

        else if MandrillConditions.byCondition(condition)
            existingCond = MandrillConditions.byCondition(condition)
            alert('You\'ve already defined that condition and called it "' +
                existingCond.name + '"')
            $('#mcbNewCondition').focus()

        else
            MandrillConditions.add condition, name
            $('#mcbNewName').val('')
            $('#mcbNewCondition').val('')


    # the user wants to delete a record
    'click [data-mcbBtn="delete"]': (event)->
        MandrillConditions.removeByCondition this.condition


    # The user modified the name of a condition
    'change input[type="text"]': (event)->
        if not this.condition
            return
        newName = $(event.target).val().trim()
        if not newName or newName is ''
            newName = this.condition

        existingCondition = MandrillConditions.byName(newName)

        if existingCondition and existingCondition.condition isnt this.condition
            alert('You already have a condition with the same.')

        else
            $(event.target).blur().val('')
            MandrillConditions.add this.condition, newName
            if Session.equals 'mandrillConditionsButtonViewMode', 'unnamed'
                $('#mandrillConditionsButtonModal input[type="text"]:first').focus()


    # The user modified the condition of a...condition
    'change textarea': (event)->
        if not this.condition
            return
        cond = $(event.target).val()
        name = this.name
        $(event.target).blur().val('')

        if this.name == this.condition
            name = cond

        if cond != this.condition
            MandrillConditions.add cond, name
            MandrillConditions.removeByCondition this.condition
}
