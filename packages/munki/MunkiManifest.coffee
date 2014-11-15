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


    @availableCatalogs: ->
        catalogs = []
        items = MunkiRepo.find(
            {'dom.catalogs':{'$exists': true}}
            {fields: {'dom.catalogs': true}}
        ).fetch()

        for item in items
            if item.dom?.catalogs?
                for catalog in item.dom.catalogs
                    if catalogs.indexOf(catalog) < 0
                        catalogs.push catalog
        catalogs.sort()


    catalogs: ->
        catalogs = @manifestObject.catalogs
        if catalogs?.push? then catalogs else []


    insertCatalogAt: (catalog, position=-1)->
        dom = @manifestObject
        dom.catalogs ?= []

        # If the catalog is already present, remove it first.
        @removeCatalog(catalog)

        # make sure the position is sane and set it to what would result in a
        # push() if it isn't.
        if position < 0 or position > dom.catalogs.length
            position = dom.catalogs.length

        dom.catalogs.splice position, 0, catalog
        dom.catalogs[position] is catalog

    removeCatalog: (catalog)->
        idx = @manifestObject.catalogs.indexOf(catalog)
        if idx >= 0
            @manifestObject.catalogs.splice(idx, 1)

        @manifestObject.catalogs.indexOf(catalog) is -1


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
