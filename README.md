Mandrill
========

Multi-user web front-end for managing a Munki repository. If you're here because of MailChimp, my apologies but this isn't the Mandrill you're looking for. /wavehand


Mandrill is a [NodeJS](http://nodejs.org/) web application writing using the [Meteor](https://www.meteor.com/) framework. It supports one database engine: [MongoDB](http://www.mongodb.com/). No there will not be support for other engines, but fear not, [mandrillctl](https://github.com/wollardj/mandrillctl) will install and secure MongoDB for you. If you already have MongoDB running on your server via homebrew, you should probably remove that installation first, or use an alternate server.

![mandrill git-log](https://f.cloud.github.com/assets/2027935/2168353/05ff8e08-953a-11e3-9db0-c2b913db89e7.png)

## Installation Prerequisites

 * **OS X client or server** _it might work on other platforms sans `makecatalogs` integration, but I'm focusing on darwin for the foreseeable future_
 * **[NodeJS with NPM](http://nodejs.org/download/)** _(both tools are in the 'Universal' link for the Mac OS X Installer .pkg)_.
 * **[munkitools](http://munkibuilds.org/)** _but only if you plan to run `makecatalogs` from your browser_

## Installing `mandrillctl`
Installation kicks off with the installation of the command line tool for Mandrill, `mandrillctl`. Since you're here, you've already got npm and node installed, so all you need to do is...


	sudo npm install -g mandrillctl


The `-g` means it's installing mandrillctl globally instead of within your home directory. It's also going to drop a symlink in your search path which you probably wouldn't be able to do without running it through `sudo`.

### Installing Mandrill
`mandrillctl` makes it pretty simple to install MongoDB + Mandrill and have your server running in no time. In general, there are four commands you'll want to run to make this happen:



	# This step can take a while, but there's plenty to watch while
	# it downloads and installs everything.
	sudo mandrillctl --install
	
	# Defaults to port 80.
	# That's probably already in use if you're installing Mandrill
	# on your existing Munki server.
	# If you give this command a port that's in use by another process,
	# it'll let you know.
	sudo mandrillctl --set-http-port 3001
	
	# If you want to use Google's OAuth, this needs to be set to
	# a publicly resolvable FQDN. If you don't plan to use OAuth,
	# what you do with this value is pretty much up to you.
	sudo mandrillctl --set-http-host http://mandrill.example.com

	# Don't forget to turn on the lights before you go
	sudo mandrillctl --start

That's it! Using the example values above, you should now be able to open your browser to http://mandrill.example.com:3001 and login!

### Initial Login
Like any good web app, the default username and password are `admin` and `admin`. _I hope it's obvious that you should change this password immediately._


### Questions?
Ask away: [https://groups.google.com/d/forum/mandrill-dev](https://groups.google.com/d/forum/mandrill-dev)
