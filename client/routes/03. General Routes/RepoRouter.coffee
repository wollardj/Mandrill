class @RepoRouter extends AppRouter
  template: 'repo'


class @RepoEditRouter extends AppRouter
  template: 'repo_edit'
  data: ->
      path = Mandrill.path.concat Munki.repoPath(), this.params.c
      MunkiRepo.findOne {path: path}
