local regent = require("regent")

rex.action({
	name = "switch_session",
	title = "Switch Session…",
	run = function(ctx)
		regent.pick(ctx, "Switch Session", "Filter sessions…", { "session", "list", "--json" }, function(id)
			regent.run(ctx, { "session", "switch", id }, { "--current-session", ctx.session_id })
		end)
	end,
})

rex.action({
	name = "kill_session",
	title = "Kill Session…",
	run = function(ctx)
		regent.pick(ctx, "Kill Sessions", "Filter sessions…", { "session", "list", "--json" }, function(ids)
			for _, id in ipairs(ids) do
				regent.run(ctx, { "session", "rm", id })
			end
		end, { multiple = true })
	end,
})

rex.action({
	name = "branch_picker",
	title = "Switch Branch…",
	run = function(ctx)
		regent.pick(ctx, "Switch Branch", "Filter branches…", { "branch", "list", "--json" }, function(id)
			regent.run(ctx, { "branch", "switch", "--name", id }, { "--current-session", ctx.session_id })
		end)
	end,
})

rex.action({
	name = "branch_home",
	title = "Go to Branch Home Session",
	run = function(ctx)
		regent.run(ctx, { "branch", "switch", "--home" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "branch_add",
	title = "New Branch…",
	run = function(ctx)
		if not ctx.client_id then
			error("New Branch requires a client", 0)
		end
		local value, err = rex.ui.input({
			title = "New Branch",
			placeholder = "Branch name…",
		})
		if err then
			if err == "cancelled" then
				return
			end
			error(err, 0)
		end
		local name = type(value) == "table" and value.value or value
		if type(name) ~= "string" then
			return
		end
		name = name:match("^%s*(.-)%s*$")
		if name == "" then
			return
		end
		regent.run(ctx, { "branch", "add", "--name", name }, nil, { client = false })
		regent.run(ctx, { "branch", "switch", "--name", name }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "last_session",
	title = "Go to Last Session",
	run = function(ctx)
		regent.run(ctx, { "session", "last" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "home_session",
	title = "Go to Home Session",
	run = function(ctx)
		regent.run(ctx, { "home" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "dotfiles_session",
	title = "Go to Dotfiles Session",
	run = function(ctx)
		regent.run(ctx, { "dotfiles" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "repository_picker",
	title = "Switch Repository…",
	run = function(ctx)
		regent.pick(ctx, "Switch Repository", "Filter repositories…", { "repo", "list", "--json" }, function(id)
			local owner, repo = id:match("^([^/]+)/(.+)$")
			if not owner or not repo then
				error("Invalid repository selection: " .. tostring(id), 0)
			end
			regent.run(ctx, { "repo", "switch", "--owner", owner, "--repo", repo }, { "--current-session", ctx.session_id })
		end)
	end,
})

rex.action({
	name = "toggle_terminal",
	title = "Toggle Terminal Split",
	run = function(ctx)
		if not ctx.session_id then
			error("Toggle terminal requires a session", 0)
		end
		regent.run(ctx, { "terminal" }, { "--session", ctx.session_id }, { client = false })
	end,
})
