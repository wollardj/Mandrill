Template.appLayout.events {
    'show.bs.modal .modal': (event)->
        $('nav.appNavbar').addClass('appNavbarHidden')


    'hidden.bs.modal .modal': (event)->
        $('nav.appNavbar').removeClass('appNavbarHidden')
}
