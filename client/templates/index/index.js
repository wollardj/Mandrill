function serverStats() {
	var stats = ServerStats.findOne({}, {sort: {collectedDate: -1}});
	return stats || {};
}


Template.index.meteorStatus = function() {
	return Meteor.status();
};


Template.index.collectedDate = function() {
	var d = serverStats().collectedDate;
	if (d) {
		return d.toLocaleString();
	}
	return '';
};

Template.index.hostname = function() {
	return serverStats().hostname;
};


Template.index.uptime = function() {
	var seconds = serverStats().uptime,
		days = 0,
		hours = 0,
		minutes = 0,
		result = [];
	while(seconds > 86400) {
		days++;
		seconds = seconds - 86400;
	}
	if (days > 0) {result.push(days + 'd');}

	while (seconds > 3600) {
		hours++;
		seconds = seconds - 3600;
	}
	if (hours > 0) {result.push(hours + 'h');}

	while (seconds > 60) {
		minutes++;
		seconds = seconds - 60;
	}
	if (minutes > 0) {result.push(minutes + 'm');}

	return result.join(' ');
};


Template.index.numberOfCpus = function() {
	var cpus = serverStats().cpus || [];
	return cpus.length;
};


Template.index.cpuName = function() {
	var cpus = serverStats().cpus || [{}];
	return cpus[0].model;
};


Template.index.loadAverage = function() {
	var	stats = serverStats(),
		avg = stats.loadavg || [0,0,0],
		cpus = stats.cpus,
		cores = (cpus ? cpus.length : 0);

	return new Handlebars.SafeString(
		(avg[2]).toFixed(2) +
		' <span class="text-muted">' +
		Math.round(avg[2] / cores * 100) + '% capacity' + '</span>'
	);
};


Template.index.memoryStats = function() {
	var stats = serverStats(),
		totalmem = stats.totalmem || 0,
		totalmemSuffixIndex = 0,
		freemem = stats.freemem || 0,
		freememSuffixIndex = 0,
		suffixes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];

	while(totalmem > 1024) {
		totalmem = totalmem / 1024;
		totalmemSuffixIndex++;
	}

	while(freemem > 1024) {
		freemem = freemem / 1024;
		freememSuffixIndex++;
	}

	return Math.round(totalmem) + suffixes[totalmemSuffixIndex] +
		' with ' + (freemem).toFixed(2) + suffixes[freememSuffixIndex] +
		' free';
};


Template.index.platform = function() {
	var stats = serverStats();
	return new Handlebars.SafeString(stats.type + ' ' + stats.platform +
		' <small class="text-muted">' + stats.release + '</small>');
};


Template.index.networkInfo = function() {
	var stats = serverStats(),
		ifaces = stats.networkInterfaces || {},
		output = '';

	for(var iface in ifaces) {
		if (ifaces.hasOwnProperty(iface)) {
			output += '<tr><th>' + iface +
				'</th><td><ul class="list-unstyled">';
			for(var address in ifaces[iface]) {
				if (ifaces[iface].hasOwnProperty(address)) {
					output += '<li><span class="small text-muted">(' +
						ifaces[iface][address].family + ')</span> ' +
						ifaces[iface][address].address + '</li>';
				}
			}
			output += '</ul></td></tr>';
		}
	}
	return new Handlebars.SafeString(output);
};