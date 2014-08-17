class @RepoRouter extends AppRouter
  template: 'repo'


class @RepoEditRouter extends AppRouter
  template: 'repo_edit'
  data: ->
      path = MandrillSettings.get 'munkiRepoPath'
      path = Mandrill.path.concat path, this.params.c
      MunkiRepo.findOne {path: path}
