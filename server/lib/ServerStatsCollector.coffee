os = Meteor.npmRequire 'os'
shell = Meteor.npmRequire 'shelljs'

class @ServerStatsCollector
	@collect: ->
		data = {}

		data.hostname = os.hostname()
		data.type = os.type()
		data.platform = os.platform()
		data.arch = os.arch()
		data.release = os.release()
		data.uptime = os.uptime()
		data.loadavg = os.loadavg()
		data.totalmem = os.totalmem()
		data.freemem = os.freemem()
		data.cpus = os.cpus()
		data.networkInterfaces = os.networkInterfaces()
		data.collectedDate = new Date()

		# Play a little nicer for OS X admins.
		if data.platform is 'darwin'
			data.type = shell.exec('sw_vers -productName').output.trim()
			data.platform = shell.exec('sw_vers -productVersion').output.trim()
			data.release = shell.exec('sw_vers -buildVersion').output.trim()

		# Insert the snapshot
		ServerStats.insert(data);

		# Purge old records
		ServerStatsCollector.truncateOldRecords()


	# Removes all but the most recent 1,440 entries.
	# With 1 minute snapshots, this means we'll end up with 24 hours
	# worth of data.
	@truncateOldRecords: ->
		totalRecords = ServerStats.find().count()
		max = 60
		ids = {'$or':[]}
		toPurge = ServerStats.find {}, {
				sort: {collectedDate: 1}
				fields: {_id: 1}
				limit: totalRecords - max
			}
			.fetch()

		if max < totalRecords
			for record in toPurge
				ids.$or.push {_id: record._id}
			ServerStats.remove ids
