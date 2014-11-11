Template.appLayout.events {
    'show.bs.modal .modal': (event)->
        $('nav.appNavbar').addClass('appNavbarHidden')


    'hide.bs.modal .modal': (event)->
        $('nav.appNavbar').removeClass('appNavbarHidden')
}
