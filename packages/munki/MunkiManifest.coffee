###
    Class to aid in the manipulation of manifests.
###


class MunkiManifest

    constructor: (@manifestObject)->
        if not @manifestObject
            throw new Meteor.Error(
                500
                'MunkiManifest requires a manifest record in its constructor.'
            )


    changeInstallType: (name, oldType, newType, conditions=[])->
        if @removeItem(name, oldType, conditions)
            @insertItem(name, newType, conditions)

    changeConditions: (name, installType, oldConditions=[], newConditions=[])->
        if @removeItem(name, installType, oldConditions)
            @insertItem(name, installType, newConditions)


    insertItem: (name, installType, conditions=[])->
        dom = @manifestObject

        if conditions.length > 0
            for condition in conditions

                # Create the conditional_items array here if needed
                dom.conditional_items ?= []

                # find the condition within the conditional_items array
                conditionFound = false
                for key,cond of dom.conditional_items
                    # if we have a match, update `dom` to this location in the
                    # hierarchy
                    if cond.condition is condition
                        conditionFound = true
                        dom = cond
                        break

                # If we couldn't find `condition`, add it
                if conditionFound is false
                    ephemeralCond = {condition: condition}
                    dom.conditional_items.push ephemeralCond
                    dom = ephemeralCond

        dom[installType] ?= []
        dom[installType].push(name)
        true


    removeItem: (name, installType, conditions=[])->
        dom = @manifestObject

        if conditions.length > 0
            for condition in conditions

                # find the condition within the conditional_items array
                conditionFound = false
                for key,cond of dom.conditional_items
                    # if we have a match, update `dom` to this location in the
                    # hierarchy
                    if cond.condition is condition
                        conditionFound = true
                        dom = cond
                        break

                # If we couldn't find `condition`, we're kinda done.
                # Sure, it's an error. Psh.
                if conditionFound is false
                    return false

        for i in [0..dom[installType].length-1]
            if dom[installType][i] is name
                dom[installType].splice(i, 1)
                return true
        false
