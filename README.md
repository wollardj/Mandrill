Mandrill
========

Multi-user web front-end for managing a Munki repository. If you're here because of MailChimp, my apologies but this isn't the Mandrill you're looking for. /wavehand


Mandrill is a [NodeJS](http://nodejs.org/) web application written using the [Meteor](https://www.meteor.com/) framework. It supports one database engine: [MongoDB](http://www.mongodb.com/). There are no plans to support other engines, but fear not, [mandrillctl](https://github.com/wollardj/mandrillctl) will install and secure MongoDB for you. If you already have MongoDB running on your server via homebrew, you should probably remove that installation first, or use an alternate server.

![mandrill git-log](https://f.cloud.github.com/assets/2027935/2168353/05ff8e08-953a-11e3-9db0-c2b913db89e7.png)

## Installation Prerequisites

 * Host operating systems that have been tested include OS X, OS X Server, Ubuntu Server, and CentOS, but any flavor of Linux or Unix should suffice.
 * **[NodeJS >= v0.10.22 with NPM](http://nodejs.org/download/)** _(both tools are in the 'Universal' link for the Mac OS X Installer .pkg)_.
 * **[munkitools](http://munkibuilds.org/)** _but only if you plan to run `makecatalogs` from your browser_

## Installing `mandrillctl`
Installation kicks off with the installation of the command line tool for Mandrill, `mandrillctl`. Since you're here, you've already got npm and node installed, so all you need to do is...


	sudo npm install -g mandrillctl


The `-g` means it's installing mandrillctl globally instead of within your home directory. It's also going to drop a symlink in your search path which you probably wouldn't be able to do without running it through `sudo`.

### Installing Mandrill On OS X
`mandrillctl` makes it pretty simple to install MongoDB + Mandrill and have your server running in no time. In general, there are four commands you'll want to run to make this happen:



	# Install mandrill
	sudo mandrillctl --install

	# Defaults to port 80.
	# If you specify a port that's in use by another process,
	# mandrillctl let you know.
	sudo mandrillctl --set-http-port 3001

	# Set your hostname (sub directories aren't supported)
	sudo mandrillctl --set-http-host http://mandrill.example.com

	# Don't forget to turn on the lights before you go
	sudo mandrillctl --start

That's it! Using the example values above, you should now be able to open your browser to http://mandrill.example.com:3001 and login!

### Initial Login
Like any good web app, the default username and password are `admin` and `admin`. _I hope it's obvious that you should change this password immediately._

### Installing Mandrill on Linux

See the step through wiki guide for [Ubuntu](https://github.com/wollardj/Mandrill/wiki/Creating-Users-%26-Groups-%28Ubuntu%29) or [CentOS](https://github.com/wollardj/Mandrill/wiki/Creating-Users-%26-Groups-%28CentOS%29)


### Questions?
Ask away: [https://groups.google.com/d/forum/mandrill-dev](https://groups.google.com/d/forum/mandrill-dev)
