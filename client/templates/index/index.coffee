serverStats = ->
	stats = ServerStats.findOne {}, {sort: {collectedDate: -1}}
	if stats?
		stats
	else
		{}


Template.index.meteorStatus = ->
	Meteor.status()


Template.index.collectedDate = ->
	d = serverStats().collectedDate;
	if d?
		d.toLocaleString()
	else
		''

Template.index.hostname = ->
	serverStats().hostname


Template.index.uptime = ->
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


Template.index.numberOfCpus = ->
	stats = serverStats()
	if stats? and stats.cpus?
		stats.cpus.length
	else
		0


Template.index.cpuName = ->
	stats = serverStats()
	if stats? and stats.cpus?
		stats.cpus[0].model
	else
		'??'


Template.index.loadAverage = ->
	stats = serverStats()
	avg = if stats.loadavg then stats.loadavg else [0,0,0]
	cpus = stats.cpus
	cores = if cpus then cpus.length else 0

	new Handlebars.SafeString(
		(avg[2]).toFixed(2) +
		' <span class="text-muted">' +
		Math.round(avg[2] / cores * 100) + '% capacity' + '</span>'
	)


Template.index.memoryStats = ->
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


Template.index.platform = ->
	stats = serverStats()
	new Handlebars.SafeString(stats.type + ' ' + stats.platform +
		' <small class="text-muted">' + stats.release + '</small>')


Template.index.networkInfo = ->
	stats = serverStats()
	ifaces = if stats.networkInterfaces then stats.networkInterfaces else {}
	output = ''

	for own key, value of ifaces
		output += '<tr><th>' + key +
			'</th><td><ul class="list-unstyled">';
		for own aKey, aValue of value
			output += '<li><span class="small text-muted">(' +
				aValue.family + ')</span> ' +
				aValue.address + '</li>'
		output += '</ul></td></tr>'

	new Handlebars.SafeString output