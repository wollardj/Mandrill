Package.describe({
  summary: "Logic and templates for Munki repos",
  version: "0.0.1"
});

Npm.depends({
    'shelljs': '0.3.0',
    'plist-native': '0.3.1'
})

Package.onUse(function(api) {
    api.versionsFrom('METEOR@0.9.2.2');
    api.use('coffeescript');
    api.use('meteorhacks:npm');
    api.use('standard-app-packages');
    api.addFiles([
            'helpers.coffee',
            'pkg_icons.html',
            'pkg_icons.coffee',
            'images/pkg.png'
        ], 'client');
    api.addFiles([
            'munki.coffee',
            'collections.coffee'
        ], ['client', 'server']);

    api.export('Munki')
    api.export('MunkiRepo')
    api.export('MunkiSettings')
    api.export('MunkiLogs')
});
