Meteor.startup ->

    setupSortableGroupItems = (tpl)->

        # Put this in a try/catch just in case this gets called before the DOM
        # is ready.
        try
            container = $(tpl.find('.sortable'))
        catch error
            return null

        data = tpl.data
        displayKey = data?.displayKey
        titleKey = data?.titleKey

        # Remove all list item divs if there are any
        container.find('div.list-group-item').remove()

        # Add the new items in the order specified in the data.args array
        for item in data.args
            if displayKey?
                display = item[displayKey]
            else
                display = item

            if titleKey?
                title = item[titleKey]
            else
                title = ''

            div = $('<div>')
                .addClass 'list-group-item'
                .data 'sortable-value', item
                .text display

            if title?
                div.attr 'title', title

            container.append div


        # Setup the `stop` event handler to make sure we get our custom event
        # sent out to any observers.
        Meteor.setTimeout ->

            # Init the sortable functionality on the list.
            container.sortable {
                placeholder: 'list-group-item ' +
                    'list-group-item-info ' +
                    'sortable-list-group-item'

                # Allow the catalogs to be re-ordered
                stop: (event, ui)->
                    obj = tpl.data
                    obj.args = tpl.findAll 'div.list-group-item'
                        .map (it)->
                            $(it).data 'sortable-value'

                    # Create the custom 'groupSorted' event
                    sortedEvent = new CustomEvent 'groupSorted', {
                        'detail': obj
                    }

                    # dispatch the 'groupSorted' event to any observers.
                    event.target.dispatchEvent sortedEvent
            }
        , 50

        # return null since we're doing dom manipulation and event handling,
        # not calculations.
        null


    Template.sortableListGroup.rendered = ->
        @autorun ->
            pleaseMakeThisShitReactiveThanks = Template.parentData()
            setupSortableGroupItems Template.instance()
