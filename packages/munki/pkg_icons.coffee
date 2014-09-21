Template.munki_pkg_icon.sizeToPx = (size)->
    switch size
        when "xs" then 20
        when "sm" then 27
        when "md" then 64
        when "lg" then 128
        when "xl" then 256
        else 64
