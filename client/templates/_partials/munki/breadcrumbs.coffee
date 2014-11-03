Template.munkiBreadcrumbs.helpers {
    ###
        Produces an array of strings used to generate the breadcrumb navigation.
    ###
    breadcrumb: ()->
        params_c = Router.current().params.query.c
        crumbs = [{name: 'Munki', url: Router.path 'repo', is_active: false}]
        if params_c?
            url = []
            crumbs.push part for part in Mandrill.path.components(params_c).map (it)->
                url.push it
                {
                    name: it
                    url: Router.path 'repo', {}, {query: "c=" + url.join('/')}
                    is_active: false
                }

            # make the last item in the array the 'active' breadcrumb
            crumbs[crumbs.length - 1].is_active = true
        else if Session.equals('repo_filter', '')
            # since there is no 'c' parameter, we'll make our faux root item
            # the 'active' breadcrumb
            crumbs[0].is_active = true

        crumbs
}
