Meteor.startup ->
    UI.registerHelper 'mandrillConditionsByName', (condition)->
        cond = Mandrill.munki.conditions.byCondition condition
        if cond?.name?
            cond.name
        else if cond?.condition?
            cond.condition
        else
            condition
