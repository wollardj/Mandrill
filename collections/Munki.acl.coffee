MunkiRepo.allow {
    'insert': -> false

    # only allow updates to the 'draft' field from the client.
    'update': (userId, doc, fieldNames, modifier)->
        fieldNames.length is 1 and fieldNames[0] is 'draft'

    'remove': (userId, doc)->
        Mandrill.user.canModifyPath userId, doc.path, true
}




MunkiSettings.allow {
    'insert': (userId)-> Mandrill.user.isAdmin userId
    'update': (userId)-> Mandrill.user.isAdmin userId
    'remove': -> false
}
