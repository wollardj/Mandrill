Template.pagination.firstLink = ->
	router = Router.current()
	first = {query: {}}
		
	if router? and router.params? and router.params.q?
		first.query.q = router.params.q

	if router?
		Router.path router.route.name, {}, first
	else
		'/'


Template.pagination.prevLink = ->
	router = Router.current()
	prev = {query: {}}
	currentPage = 0
	
	if router?
		if router.params.p?
			currentPage = parseInt router.params.p

		if router.params.q?
			prev.query.q = router.params.q

		if currentPage - 1 > 0
			prev.query.p = currentPage - 1

		Router.path router.route.name, {}, prev
	else
		'/'


Template.pagination.rangeStart = ->
	router = Router.current()
	currentPage = 0
	perPage = 25
	start = 0
	total = 0

	if router?
		data = router.data()
		if router.params.p?
			currentPage = parseInt router.params.p
		
		if data.recordsPerPage?
			perPage = data.recordsPerPage
		
		if data.unlimitedTotal?
			total = data.unlimitedTotal

		if currentPage? and perPage?
			start = currentPage * perPage + 1

		if total is 0
			start = 0

		start
	else
		0

Template.pagination.rangeEnd = ->
	router = Router.current()
	currentPage = 0
	end = 0
	total = 0
	perPage = 25

	if router?
		data = router.data()
		if data.recordsPerPage?
			perPage = data.recordsPerPage

		if data.unlimitedTotal?
			total = data.unlimitedTotal

		if router.params.p?
			currentPage = parseInt router.params.p

		if currentPage? and perPage?
			end = currentPage * perPage + perPage
		if end > total
			end = total
		end
	else
		0



Template.pagination.rangeTotal = ->
	router = Router.current()

	if router?
		data = router.data()
		if data? and data.unlimitedTotal?
			data.unlimitedTotal
		else
			0
	else
		0



Template.pagination.nextLink = ->
	router = Router.current()
	currentPage = 0
	next = {query: {}}
	totalRecords = 0
	perPage = 25

	if router?
		data = router.data()
		if data?
			if data.recordsPerPage?
				perPage = data.recordsPerPage
			
			if data.unlimitedTotal?
				totalRecords = data.unlimitedTotal

			totalPages = Math.floor(totalRecords / perPage)
			
			if router.params.q?
				next.query.q = router.params.q
			
			if router.params.p?
				currentPage = parseInt router.params.p

			if currentPage + 1 <= totalPages
				next.query.p = currentPage + 1
			else
				next.query.p = totalPages	

	Router.path(router.route.name, {}, next)



Template.pagination.lastLink = ->
	router = Router.current()
	totalRecords = 0
	last = {query: {}}
	currentPage = 0
	perPage = 25
	
	if router?
		data = router.data()
		if data?

			if router.params.p?
				currentPage = parseInt router.params.p
	
			if data.recordsPerPage?
				perPage = data.recordsPerPage
	
			if data.unlimitedTotal?
				totalRecords = data.unlimitedTotal

			totalPages = Math.floor(totalRecords / perPage)
	
			if router.params.q?
				last.query.q = router.params.q
	
			last.query.p = totalPages

	Router.path router.route.name, {}, last




Template.pagination.firstIsDisabled = ->
	router = Router.current()
	if router?
		if router.params.p? and router.params.p isnt 0
			''
		else
			'disabled'
	else
		'disabled'


Template.pagination.lastIsDisabled = ->
	router = Router.current()
	totalRecords = 0
	currentPage = 0
	perPage = 25

	if router?
		data = router.data()
		if data? and data.unlimitedTotal?
			totalRecords = data.unlimitedTotal

		if data.recordsPerPage?
			perPage = data.recordsPerPage

		if router.params.p?
			currentPage = parseInt router.params.p
	
		totalPages = Math.floor(totalRecords / perPage)

		if currentPage >= totalPages
			'disabled'
		else
			''
	else
		'disabled'
