manifest_flatten = (obj, result=[], conditions=[])->
    keysWeCareAbout = [
        'managed_installs'
        'managed_uninstalls'
        'managed_updates'
        'optional_installs'
    ]

    for key,val of obj # top-level keys; managed_installs, etc.

        if key in keysWeCareAbout

            for item in val # installer items
                result.push {
                    pkg: item
                    installType: key
                    conditions: conditions
                }

        else if key is 'conditional_items'

            for cond_item in val

                if conditions.length > 0
                    # array.slize(0) clones the array; no passing pointers!!
                    tmp_cond = conditions.slice(0)
                    tmp_cond.push cond_item.condition

                else
                    tmp_cond = [cond_item.condition]

                manifest_flatten cond_item, result, tmp_cond
    result



class MandrillConditions

    ###
        Extracts conditions from the repo and adds them to the database so they
        can be named and queried more efficiently.
    ###
    @scanRepoForConditions: ->
        for item in MunkiRepo.find().fetch()
            if item.isManifest()
                flat = manifest_flatten(item.dom)
                for row in flat
                    if row.conditions?.length > 0
                        for cond in row.conditions
                            if @byCondition(cond) is false
                                @add(cond, cond)
        undefined



    ###
        Adds a default set of rules to the database to help get things started
        for the admin.
    ###
    @addDefaultConditionNamePairs: ->
        @add 'machine_type == "laptop"', "it's a laptop"
        @add 'machine_type == "desktop"', "it's a desktop"
        @add 'machine_model BEGINSWITH "Macmini"', "it's an '06 or later Mac mini"
        @add 'machine_model BEGINSWITH "iMac"', "it's an iMac"
        @add 'machine_model BEGINSWITH "MacBookPro"', "it's a MacBook Pro"
        @add 'machine_model BEGINSWITH "MacPro"', "it's a Mac Pro"
        @add 'machine_model BEGINSWITH "MacBookAir"', "it's a MacBook Air"
        @add 'arch != "powerpc"', "the CPU isn't PPC"
        @add 'date > CAST("2015-01-02T00:00:00Z", "NSDate")', "2014 is history"
        @add 'os_vers_minor == 9', "it's running Mavericks (10.9.x)"
        @add 'os_vers_minor == 10', "it's running Yosemite (10.10.x)"


    ###
        Returns an array of objects containing all of the known conditions and
        their names.
    ###
    @all: ->
        c = MandrillSettings.get('munkiConditions')
        c || []


    @add: (condition, name)->
        c = @all()
        found = false
        for cond in c
            if cond.condition is condition
                found = true
                cond.name = name
                break

        if not found
            c.push({condition: condition, name: name})

        c.sort (a,b)->
            a.name.localeCompare b.name

        MandrillSettings.set('munkiConditions', c)


    @byCondition: (condition)->
        for c in @all()
            if c.condition is condition
                return c
        false


    @byName: (name)->
        for c in @all()
            if c.name is name
                return c
        false


    @removeByCondition: (condition)->
        c = @all()
        for key,obj of c
            if obj.condition is condition
                c.splice(key, 1)
                MandrillSettings.set 'munkiConditions', c
                return
