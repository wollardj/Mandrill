MunkiRepo.allow {
    'insert': -> false
    'update': -> false
    'remove': (userId, doc)->
        Mandrill.user.canModifyPath userId, doc.path, true
}




MunkiSettings.allow {
    'insert': (userId)-> Mandrill.user.isAdmin userId
    'update': (userId)-> Mandrill.user.isAdmin userId
    'remove': -> false
}
