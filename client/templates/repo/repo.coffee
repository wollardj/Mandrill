Template.repo.breadcrumb = ()->
  base_breadcrumb = {name: 'Munki', url: "?", is_active: false}
  r = Router.current()
  if r.params.c?
    url = []
    crumbs = Mandrill.path.components(r.params.c).map (it)->
      url.push it
      {name: it, url: "?c=" + url.join('/'), is_active: false}
    crumbs.splice 0, 0, base_breadcrumb
    crumbs[crumbs.length - 1].is_active = true
    crumbs
  else
    base_breadcrumb.is_active = true
    [base_breadcrumb]


Template.repo.dot_dot_url = ()->
  crumbs = Template.repo.breadcrumb()
  parent_crumb = crumbs[crumbs.length - 2]
  if parent_crumb? and parent_crumb.url?
    parent_crumb.url
  else
    null



Template.repo.dir_listing = ()->
  repo = MandrillSettings.get 'munkiRepoPath'
  url = Router.current().params.c
  files = []
  search_path = new RegExp( '^' + Mandrill.path.concat(repo, url) + '/' )
  search_obj = {path: search_path}
  search_opts = {fields: {path: true}, sort:{path:1}}



  # function used to map() the results of each query
  reduce_path_map = (it)->
    record = {}
    record.name = it.path
      .replace(search_path, '')
      .replace(/^\/*/, '')
      .split('/')[0]

    # return a null value if the current path component has already
    # been returned at least once.
    if -1 isnt files.indexOf record.name
      return null
    else
      files.push record.name

    # let's find out if this component is the last one in the path
    # for the current record
    full_component_path = Mandrill.path.concat(repo, url, record.name)
    record.is_leaf = it.path is full_component_path.replace(/\/*$/, '')
    record.url = '?c=' + Mandrill.path.concat(url, record.name)
    record



  # obtain all of the paths that match the current set of bread crumbs.
  results = MunkiManifests.find(search_obj, search_opts).fetch().map reduce_path_map
    .concat MunkiCatalogs.find(search_obj, search_opts).fetch().map reduce_path_map
    .concat MunkiPkgsinfo.find(search_obj, search_opts).fetch().map reduce_path_map

  # filter out the null values.
  while results.indexOf(null) isnt -1
    results.splice results.indexOf(null), 1

  # return the results
  results.sort (a, b)->
    if (a.is_leaf and b.is_leaf) or (not a.is_leaf and not b.is_leaf)
      a.name.toLowerCase().localeCompare b.name.toLowerCase()
    else if a.is_leaf
      1
    else
      -1
