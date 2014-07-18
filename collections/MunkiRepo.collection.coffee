@MunkiRepo = new Meteor.Collection 'munki_repo'

MunkiRepo.allow {
    'insert': ->
        false
    'update': ->
        false
    'remove': (userId, doc)->
        Mandrill.user.canModifyPath userId, doc.path, true
}
