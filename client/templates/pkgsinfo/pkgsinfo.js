Template.pkgsinfo.rendered = function() {
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
	if ($('#pkgsinfo-search').val() === '' && Router.current().params.q) {
		$('#pkgsinfo-search').val(Router.current().params.q);
	}
};



Template.pkgsinfo.relativePath = function() {
	var settings = MandrillSettings.findOne();
	if (!settings.munkiRepoPath) {
		return this.path;
	}

	if (this.path) {
		return this.path.replace(settings.munkiRepoPath + 'pkgsinfo/', '');
	}
	return '??';
};



Template.pkgsinfo.basePath = function() {
	var settings = MandrillSettings.findOne();
	if (settings && settings.munkiRepoPath) {
		return settings.munkiRepoPath;
	}
	return '/';
}



Template.pkgsinfo.events({
	'submit form': function(event) {
		event.stopPropagation();
		event.preventDefault();
	},


	'keyup #pkgsinfo-search': function() {
		var oldQuery = Router.current().params.q ?
				Router.current().params.q :
				'',
			query = $('#pkgsinfo-search').val();

		// A little clearTimeout/setTimeout magic to only submit
		// the search after the user has stopped typing for 250ms.
		window.clearTimeout(window.pkgsinfoSearchTimer);
		window.pkgsinfoSearchTimer = window.setTimeout(function() {
			if (oldQuery !== query && query !== '') {
				Router.go('pkgsinfo', {}, {'query': {'q': query}});
			}
			else if (oldQuery !== query) {
				Router.go('pkgsinfo');
			}
		}, 250);
	},


	'click tr.pkgsinfo-item-row': function() {
		if (this.urlName) {
			Router.go('pkgsinfo', {urlName: this.urlName});
		}
		else {
			Mandrill.show.error(new Meteor.Error('-1',
				'Couldn\'t figure out which pkginfo file represents "' +
				this.dom.name + '"'));
		}
	},


	// Add a new pkginfo file.
	'submit #pkginfoNameForm': function(event) {
		event.stopPropagation();
		event.preventDefault();

		var settings = MandrillSettings.findOne();
		
		if (settings.munkiRepoPath) {
			Meteor.call(
				'createPkginfo',
				settings.munkiRepoPath + 'pkgsinfo/' +
					$('#pkginfoName').val(),
				function(err, data) {
					if (err) {
						Mandrill.show.error(err);
					}
					else {
						Router.go(
							'pkgsinfo',
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


	// Display the new pkginfo form
	'click #newPkginfo': function(event) {
		event.preventDefault();
		event.stopPropagation();
		$('#newPkginfoForm').toggleClass('newPkginfoFormClosed');
		if ($('#newPkginfoForm').hasClass('newPkginfoFormClosed')) {
			$('#pkginfoName').blur();
		}
		else {
			$('#pkginfoName').focus();
		}
	},


	// Hide the new pkginfo form if the user presses the esc key
	'keyup #pkginfoName': function(event) {
		if (event.which === 27) {
			$('#newPkginfoForm').addClass('newPkginfoFormClosed');
			$('#pkginfoName').blur();
		}
	}
});