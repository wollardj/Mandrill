serverStats = ->
	stats = ServerStats.findOne {}, {sort: {collectedDate: -1}}
	if stats?
		stats
	else
		{}



Template.index.helpers {
	meteorStatus: ->
		Meteor.status()


	collectedDate: ->
		d = serverStats().collectedDate;
		if d?
			d.toLocaleString()
		else
			''

	hostname: ->
		serverStats().hostname


	uptime: ->
		seconds = serverStats().uptime
		days = 0
		hours = 0
		minutes = 0
		result = []

		while seconds > 86400
			days++
			seconds = seconds - 86400

		if days > 0
			result.push days + 'd'

		while seconds > 3600
			hours++
			seconds = seconds - 3600

		if hours > 0
			result.push hours + 'h'

		while seconds > 60
			minutes++
			seconds = seconds - 60
		if minutes > 0
			result.push minutes + 'm'

		result.join ' '


	numberOfCpus: ->
		stats = serverStats()
		if stats? and stats.cpus?
			stats.cpus.length
		else
			0


	cpuName: ->
		stats = serverStats()
		if stats? and stats.cpus?
			stats.cpus[0].model
		else
			'??'


	loadAverage: ->
		stats = serverStats()
		avg = if stats.loadavg then stats.loadavg else [0,0,0]
		cpus = stats.cpus
		cores = if cpus then cpus.length else 0

		new Handlebars.SafeString(
			(avg[2]).toFixed(2) +
			' <span class="text-muted">' +
			Math.round(avg[2] / cores * 100) + '% capacity' + '</span>'
		)


	memoryStats: ->
		stats = serverStats()
		totalmem = if stats.totalmem then stats.totalmem else 0
		totalmemSuffixIndex = 0
		freemem = if stats.freemem then stats.freemem else 0
		freememSuffixIndex = 0
		suffixes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB']

		while totalmem > 1024
			totalmem = totalmem / 1024
			totalmemSuffixIndex++

		while freemem > 1024
			freemem = freemem / 1024
			freememSuffixIndex++

		Math.round(totalmem) + suffixes[totalmemSuffixIndex] +
			' with ' + (freemem).toFixed(2) + suffixes[freememSuffixIndex] +
			' free'


	platform: ->
		stats = serverStats()
		new Handlebars.SafeString(stats.type + ' ' + stats.platform +
			' <small class="text-muted">' + stats.release + '</small>')


	networkInfo: ->
		stats = serverStats()
		ifaces = if stats.networkInterfaces then stats.networkInterfaces else {}
		output = ''

		for own key, value of ifaces
			if /^utun/.test(key) or key is 'lo0'
				continue

			output += '<tr><th>' + key +
				'</th><td><ul class="list-unstyled">';
			for own aKey, aValue of value
				output += '<li><span class="small text-muted">(' +
					aValue.family + ')</span> ' +
					aValue.address + '</li>'
			output += '</ul></td></tr>'

		new Handlebars.SafeString output
}
