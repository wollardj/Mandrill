Meteor.startup ->
    UI.registerHelper 'mandrillConditionsByName', (condition)->
        name = Mandrill.conditions.byCondition condition
        name || condition
