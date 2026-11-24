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
end

local function regent_picker(ctx, label, tag, subcommand)
	if not ctx.client_id or not ctx.session_id then
		error(label .. " requires a client and a session", 0)
	end

	local cmd = {
		"sh",
		"-c",
		[[
      "$@" || {
        status=$?
        printf '\nPress Enter to close the picker.\n' >&2
        read -r _
        exit "$status"
      }
    ]],
		tag,
		"regent",
	}
	for _, part in ipairs(subcommand) do
		cmd[#cmd + 1] = part
	end
	cmd[#cmd + 1] = "--client"
	cmd[#cmd + 1] = ctx.client_id
	cmd[#cmd + 1] = "--current-session"
	cmd[#cmd + 1] = ctx.session_id

	local options = {
		interactive = true,
		command = cmd,
	}
	local cwd = block_cwd(ctx)
	if cwd then
		options.cwd = cwd
	end

	local picker, err = rex.session.new_layer({
		bounds = { 0.1, 0.1, 0.8, 0.8 },
		focus = true,
		layout = rex.layout.block({
			flavor = "com.superlogical.terminal.shell",
			label = label,
			options = options,
		}),
	})
	if err then
		error(err, 0)
	end
	return picker
end

rex.action({
	name = "switch_session",
	title = "Switch Session…",
	run = function(ctx)
		return regent_picker(ctx, "Sessions", "session-picker", { "session", "switch", "--interactive" })
	end,
})

rex.action({
	name = "kill_session",
	title = "Kill Session…",
	run = function(ctx)
		return regent_picker(ctx, "Kill Sessions", "session-remove-picker", { "session", "rm", "--interactive" })
	end,
})

rex.action({
	name = "branch_picker",
	title = "Switch Branch…",
	run = function(ctx)
		return regent_picker(ctx, "Branches", "branch-picker", { "branch", "switch", "--interactive" })
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
		return regent_picker(ctx, "Repositories", "repository-picker", { "repo", "switch", "--interactive" })
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
