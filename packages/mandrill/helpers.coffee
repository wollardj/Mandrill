Meteor.startup ->
    UI.registerHelper 'mandrillConditionsByName', (condition)->
        cond = Mandrill.conditions.byCondition condition
        if cond?.name?
            cond.name
        else if cond?
            cond.condition
        else
            ''
