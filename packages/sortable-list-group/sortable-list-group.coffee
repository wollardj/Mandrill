Meteor.startup ->

    setupSortableGroupItems = (tpl)->
        Meteor.setTimeout ->
            container = $(tpl.find('.sortable'))
            container.sortable {
                placeholder: 'list-group-item ' +
                    'list-group-item-info ' +
                    'sortable-list-group-item'

                # Allow the catalogs to be re-ordered
                stop: (event, ui)->
                    obj = tpl.data

                    obj.args = container.sortable(
                            'toArray',
                            {attribute: 'data-sortable-value'}
                        ).map (it)->
                            JSON.parse(it)


                    sortedEvent = new CustomEvent 'groupSorted', {
                        'detail': obj
                    }
                    event.target.dispatchEvent sortedEvent

                    container.sortable 'cancel'
#                    Meteor.setTimeout ->

#                    , 1
            }
            $('.sortable').disableSelection()
        , 50


    Template.sortableListGroup.rendered = ->
        console.log 'rendered'
        setupSortableGroupItems(
            Template.instance()
        )

    Template.sortableListGroup.helpers {
        items: ->
            metaData = Template.instance().data
            displayKey = metaData?.displayKey
            titleKey = metaData?.titleKey
            ret = []

            for item in metaData?.args
                obj = {}

                if displayKey?
                    obj.display = item[displayKey]
                else
                    obj.display = item

                if titleKey?
                    obj.title = item[titleKey]
                else
                    obj.title = ''

                ret.push obj
            ret


        stringify: ->
            JSON.stringify this

    }
