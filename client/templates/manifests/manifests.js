Template.manifests.rendered = function() {
	var headerBottom = $('.mandrill-header').outerHeight();
	$('.paging-toolbar').affix({
		offset: { top: headerBottom }
	});


	if ($(window).scrollTop() >= headerBottom) {
		// Bring the header below the trigger point for bootstrap's affix
		window.scrollTo(0, headerBottom);

		// Wait 1ms before scrolling 1px above the affix trigger so
		// the drop shadow will appear. 1ms because we want to give
		// the affix plugin time to respond to the previous scroll event.
		window.setTimeout(function() {
			window.scrollTo(0, headerBottom + 1);
		}, 1);
	}

	// Let's also set the initial value of the search box, _if_
	// it doesn't already have something in it.
	if ($('#manifest-search').val() === '' && Router.current().params.q) {
		$('#manifest-search').val(Router.current().params.q);
	}
};



Template.manifests.basePath = function() {
	var settings = MandrillSettings.findOne();
	if (settings && settings.munkiRepoPath) {
		return settings.munkiRepoPath;
	}
	return '/';
};



Template.manifests.relativePath = function() {
	var settings = MandrillSettings.findOne();
	if (settings && settings.munkiRepoPath) {
		return this.path.replace(settings.munkiRepoPath + 'manifests/', '');
	}
	return this.path;
};



Template.manifests.events({
	'submit #searchForm': function(event) {
		event.stopPropagation();
		event.preventDefault();
	},


	'keyup #manifest-search': function() {
		var oldQuery = Router.current().params.q ?
				Router.current().params.q :
				'',
			query = $('#manifest-search').val();

		// A little clearTimeout/setTimeout magic to only submit
		// the search after the user has stopped typing for 250ms.
		window.clearTimeout(window.manifestsSearchTimer);
		window.manifestsSearchTimer = window.setTimeout(function() {
			if (oldQuery !== query && query !== '') {
				Router.go('manifests', {}, {'query': {'q': query}});
			}
			else if (oldQuery !== query) {
				Router.go('manifests');
			}
		}, 250);
	},




	'click tr.manifest-item-row': function() {
		if (this.urlName) {
			Router.go('manifests', {urlName: this.urlName});
		}
		else {
			Mandrill.show.error(new Meteor.Error('-1',
				'Couldn\'t figure out which manifest file represents "' +
				this.dom.name + '"'));
		}
	},




	'submit #manifestNameForm': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var settings = MandrillSettings.findOne();
		
		if (settings.munkiRepoPath) {
			Meteor.call(
				'createManifest',
				settings.munkiRepoPath + 'manifests/' +
					$('#manifestName').val(),
				function(err, data) {
					if (err) {
						Mandrill.show.error(err);
					}
					else {
						Router.go(
							'manifests',
							{},
							{query: {q: data.urlName}}
						);
					}
				}
			);
		}
		else {
			Mandrill.show.error(new Meteor.Error(500,
				'Path to munki_repo has not been set.'));
		}
	},


	// Display the new manifest form
	'click #newManifest': function(event) {
		event.preventDefault();
		event.stopPropagation();
		$('#newManifestForm').toggleClass('newManifestFormClosed');
		if ($('#newManifestForm').hasClass('newManifestFormClosed')) {
			$('#manifestName').blur();
		}
		else {
			$('#manifestName').focus();
		}
	},


	// Hide the new manifest form if the user presses the esc key
	'keyup #manifestName': function(event) {
		if (event.which === 27) {
			$('#newManifestForm').addClass('newManifestFormClosed');
			$('#manifestName').blur();
		}
	}
});