class @RepoRouter extends AppRouter
  template: 'repo'


class @RepoEditRouter extends AppRouter
  template: 'repo_edit'
  data: ->
      MunkiRepo.findOne({path: new RegExp(this.params.c + '$')})
