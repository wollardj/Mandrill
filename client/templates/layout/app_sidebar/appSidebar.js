Session.setDefault('runningMakeCatalogs', false);

Template.appSidebar.rendered = function () {
	Template.appSidebar.resize();
};



Template.appSidebar.resize = function () {
	// Make sure the height of the sidebar matches the available height
	// within the window.
	var winHeight = $(window).height() - 25,
		$sidebar = $('#appSidebar'),
		currentHeight = $sidebar.height();

	// avoid triggering a re-draw if the height of the window
	// isn't changing.
	if (currentHeight !== winHeight) {
		$sidebar.height(winHeight);
	}
};


Template.appSidebar.created = function () {

	// Make sure the height of the sidebar always matches the available
	// height when the window is resized.
	$(window).on('resize', Template.appSidebar.resize);
};



Template.appSidebar.otherTools = function () {
	return OtherTools.find({}, {sort: {displayText: 1}}).fetch();
};


Template.appSidebar.manifestsCount = function() {
	var record = RepoStats.findOne('manifests');
	return record ? record.count : 0;
	//return MunkiManifests.find().count();
};

Template.appSidebar.manifestErrorsCount = function() {
	var record = RepoStats.findOne('manifestErrors');
	return record ? record.count : 0;
};


Template.appSidebar.installsCount = function() {
	var record = RepoStats.findOne('pkgsinfo');
	return record ? record.count : 0;
};

Template.appSidebar.installsErrorsCount = function() {
	var record = RepoStats.findOne('pkgsinfoErrors');
	return record ? record.count : 0;
};


Template.appSidebar.catalogsCount = function() {
	var record = RepoStats.findOne('catalogs');
	return record ? record.count : 0;
};

Template.appSidebar.catalogsErrorsCount = function() {
	var record = RepoStats.findOne('catalogErrors');
	return record ? record.count : 0;
};


Template.appSidebar.makeCatalogsIsEnabled = function() {
	var settings = MandrillSettings.findOne();
	return settings && settings.makeCatalogsIsEnabled === true;
};


Template.appSidebar.loggedInUserDisplayName = function () {
	var act = Meteor.users.findOne();
	return act.profile && act.profile.name ? act.profile.name : '??';
};


Template.appSidebar.runningMakeCatalogs = function() {
	return Session.get('runningMakeCatalogs');
};


Template.appSidebar.makecatalogsCommand = function() {
	var settings = MandrillSettings.findOne();
	if (settings && settings.makeCatalogsSanityIsDisabled === true) {
		return 'makecatalogs -f';
	}
	return 'makecatalogs';
};




Template.appSidebar.events({
	'click #logout': function (event) {
		event.stopPropagation();
		event.preventDefault();
		Meteor.logout();
	},


	'click #makecatalogs': function(event) {
		event.stopPropagation();
		event.preventDefault();
		Session.set('runningMakeCatalogs', true);
		Meteor.call('runMakeCatalogs', function(err, data) {
			Session.set('runningMakeCatalogs', false);
			if (err) {
				Mandrill.show.error(err);
			}
		});
	}
});