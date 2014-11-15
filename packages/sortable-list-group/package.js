Package.describe({
  name: 'sortable-list-group',
  summary: 'provides a sortable list-group that emits Meteor-style events.',
  version: '0.8.0',
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.use('coffeescript');
  api.use('stylus');
  api.use('standard-app-packages');
  api.addFiles([
        'sortable-list-group.coffee',
        'sortable-list-group.html',
        'sortable-list-group.styl'
      ], ['client']);
});
