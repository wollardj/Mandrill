Package.describe({
    name: 'mandrill',
    summary: "Logic and templates for Mandrill",
    version: "0.8.0"
});

Package.onUse(function(api) {
    api.versionsFrom('1.0');
    api.use('coffeescript');
    api.use('standard-app-packages');
    api.addFiles([
            'helpers.coffee',
            'munki/conditions/mandrillConditionsButton.html',
            'munki/conditions/mandrillConditionsButton.coffee'
        ], 'client');
    api.addFiles([
            'munki/conditions/MandrillConditions.coffee',
            'mandrill.coffee'
        ], ['client', 'server']);

    api.export('MandrillConditions');
    api.export('Mandrill');
});
