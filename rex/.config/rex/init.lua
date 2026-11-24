local function block_cwd(ctx)
	local block_id = ctx.block_id
	if not block_id and ctx.session_id then
		local view = rex.session.view()
		if view and view.active_window_id then
			for _, win in ipairs(view.windows or {}) do
				if win.window_id == view.active_window_id then
					block_id = win.focused_block_id
					break
				end
			end
		end
	end
	if not block_id then
		return nil
	end

	local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = block_id })
	if not proc then
		return nil
	end
	if proc.foreground and proc.foreground.cwd and proc.foreground.cwd ~= "" then
		return proc.foreground.cwd
	end
	for _, ancestor in ipairs(proc.ancestors or {}) do
		if ancestor.cwd and ancestor.cwd ~= "" then
			return ancestor.cwd
		end
	end
	if proc.child and proc.child.cwd and proc.child.cwd ~= "" then
		return proc.child.cwd
	end
	return nil
end

local function regent(ctx, subcommand, extra_args, opts)
	local use_client = not opts or opts.client ~= false
	if use_client and not ctx.client_id then
		error("Regent commands require a client", 0)
	end

	local data_home = os.getenv("MISE_DATA_DIR")
	if not data_home or data_home == "" then
		local xdg = os.getenv("XDG_DATA_HOME")
		if not xdg or xdg == "" then
			xdg = os.getenv("HOME") .. "/.local/share"
		end
		data_home = xdg .. "/mise"
	end
	local path = data_home .. "/shims:" .. (os.getenv("PATH") or "/usr/bin:/bin")
	-- Rex actions do not inherit the interactive shell's Rex CLI path.
	local rex_bin = os.getenv("REX_BIN_DIR")
	if not rex_bin or rex_bin == "" then
		local bundled = os.getenv("HOME")
			.. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"
		local cli = io.open(bundled .. "/rex", "r")
		if cli then
			cli:close()
			rex_bin = bundled
		end
	end
	if rex_bin and rex_bin ~= "" then
		path = rex_bin .. ":" .. path
	end

	local args = { "env", "PATH=" .. path, "regent" }
	for _, part in ipairs(subcommand) do
		args[#args + 1] = part
	end
	if use_client then
		args[#args + 1] = "--client"
		args[#args + 1] = ctx.client_id
	end
	for _, arg in ipairs(extra_args or {}) do
		args[#args + 1] = arg
	end

	local cwd = block_cwd(ctx)
	local result, err = rex.exec(args, cwd and { cwd = cwd } or nil)
	if not result then
		error(err, 0)
	end
	if not result.ok then
		error(result.stderr ~= "" and result.stderr or "Regent command failed", 0)
	end
	return result.stdout
end

local function regent_ui_pick(ctx, title, placeholder, list_cmd, on_select, opts)
	if not ctx.client_id or not ctx.session_id then
		error(title .. " requires a client and a session", 0)
	end
	local stdout = regent(ctx, list_cmd, nil, { client = false })
	local items, decode_err = rex.json.decode(stdout)
	if not items then
		error(decode_err or "Failed to decode Regent output", 0)
	end
	local multiple = opts and opts.multiple == true
	local picked, err = rex.ui.pick({
		title = title,
		placeholder = placeholder,
		items = items,
		multiple = multiple,
	})
	if err then
		if err == "cancelled" then
			return
		end
		error(err, 0)
	end
	if multiple then
		local ids = {}
		if type(picked) == "string" and picked ~= "" then
			ids[1] = picked
		elseif type(picked) == "table" then
			local list = type(picked.ids) == "table" and picked.ids or picked
			for _, item in ipairs(list) do
				local id = type(item) == "table" and item.id or item
				if type(id) == "string" and id ~= "" then
					ids[#ids + 1] = id
				end
			end
			if #ids == 0 and type(picked.id) == "string" and picked.id ~= "" then
				ids[1] = picked.id
			end
		end
		if #ids == 0 then
			return
		end
		on_select(ids)
		return
	end
	local id
	if type(picked) == "string" then
		id = picked
	elseif type(picked) == "table" then
		id = picked.id or (picked.ids and picked.ids[1]) or picked[1]
	end
	if not id or id == "" then
		return
	end
	on_select(id)
end

rex.action({
	name = "switch_session",
	title = "Switch Session…",
	run = function(ctx)
		regent_ui_pick(ctx, "Switch Session", "Filter sessions…", { "session", "list", "--json" }, function(id)
			regent(ctx, { "session", "switch", id }, { "--current-session", ctx.session_id })
		end)
	end,
})

rex.action({
	name = "kill_session",
	title = "Kill Session…",
	run = function(ctx)
		regent_ui_pick(ctx, "Kill Sessions", "Filter sessions…", { "session", "list", "--json" }, function(ids)
			for _, id in ipairs(ids) do
				regent(ctx, { "session", "rm", id })
			end
		end, { multiple = true })
	end,
})

rex.action({
	name = "branch_picker",
	title = "Switch Branch…",
	run = function(ctx)
		regent_ui_pick(ctx, "Switch Branch", "Filter branches…", { "branch", "list", "--json" }, function(id)
			regent(ctx, { "branch", "switch", "--name", id }, { "--current-session", ctx.session_id })
		end)
	end,
})

rex.action({
	name = "branch_home",
	title = "Go to Branch Home Session",
	run = function(ctx)
		regent(ctx, { "branch", "switch", "--home" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "last_session",
	title = "Go to Last Session",
	run = function(ctx)
		regent(ctx, { "session", "last" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "home_session",
	title = "Go to Home Session",
	run = function(ctx)
		regent(ctx, { "home" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "dotfiles_session",
	title = "Go to Dotfiles Session",
	run = function(ctx)
		regent(ctx, { "dotfiles" }, ctx.session_id and { "--current-session", ctx.session_id } or nil)
	end,
})

rex.action({
	name = "copy_mode",
	title = "Open Neovim Copy Mode",
	run = function(ctx)
		if not ctx.block_id then
			error("Copy mode requires a terminal pane", 0)
		end

		local source, err = rex.session.describe_block({ block_id = ctx.block_id })
		if err then
			error(err, 0)
		end
		local block = source.block
		if block.creator_name ~= "com.superlogical.terminal" or not block.window_id then
			error("Copy mode requires a terminal pane", 0)
		end

		local config_home = os.getenv("XDG_CONFIG_HOME")
		if not config_home or config_home == "" then
			config_home = os.getenv("HOME") .. "/.config"
		end
		local viewer
		viewer, err = rex.session.new_layer({
			window_id = block.window_id,
			bounds = { 0, 0, 1, 1 },
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				label = "Copy Mode",
				options = {
					interactive = true, -- Put mise's Neovim and Rex on PATH.
					command = {
						"env",
						"REX_COPY_SESSION=" .. ctx.session_id,
						"REX_COPY_BLOCK=" .. ctx.block_id,
						"nvim",
						"-u",
						config_home .. "/rex/copy-mode.nvim.lua",
						"-i",
						"NONE",
						"-n",
						"--noplugin",
					},
				},
			}),
		})
		if err then
			error(err, 0)
		end
		return viewer
	end,
})

rex.action({
	name = "repository_picker",
	title = "Switch Repository…",
	run = function(ctx)
		regent_ui_pick(ctx, "Switch Repository", "Filter repositories…", { "repo", "list", "--json" }, function(id)
			local owner, repo = id:match("^([^/]+)/(.+)$")
			if not owner or not repo then
				error("Invalid repository selection: " .. tostring(id), 0)
			end
			regent(ctx, { "repo", "switch", "--owner", owner, "--repo", repo }, { "--current-session", ctx.session_id })
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
		regent(ctx, { "terminal" }, { "--session", ctx.session_id }, { client = false })
	end,
})

rex.action({
	name = "test_ui_pick",
	title = "Test UI Pick…",
	run = function()
		return rex.ui.pick({
			title = "Test Picker",
			placeholder = "Type to filter…",
			items = {
				{ id = "alpha", label = "Alpha", detail = "First test item" },
				{ id = "beta", label = "Beta", detail = "Second test item" },
				{ id = "gamma", label = "Gamma", detail = "Third test item" },
			},
		})
	end,
})

rex.bind("ctrl+a>[", "copy_mode")
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>h", "branch_home")
rex.bind("ctrl+a>shift+h", "home_session")
rex.bind("ctrl+a>shift+d", "dotfiles_session")
rex.bind("ctrl+a>j", "switch_session")
rex.bind("ctrl+a>p", "repository_picker")
rex.bind("ctrl+a>o", "toggle_terminal")
rex.bind("ctrl+a>shift+l", "last_session")
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+-", "branch_picker")
rex.bind("ctrl+a>k", "kill_session")
rex.bind("ctrl+a>t", "test_ui_pick")
rex.bind("ctrl+a>b", "client.sidebar.toggle")
for index = 1, 9 do
	rex.bind("ctrl+a>" .. index, "client.tab.goto", { index = index })
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, function(ctx)
		local process = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
		if process and process.foreground and process.foreground.name == "nvim" then
			return false
		end

		local _, err = rex.session.focus_direction({ direction = direction })
		if err then
			error(err, 0)
		end
		return true
	end)
end
