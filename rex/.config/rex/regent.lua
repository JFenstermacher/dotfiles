local M = {}

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

function M.run(ctx, subcommand, extra_args, opts)
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

function M.pick(ctx, title, placeholder, list_cmd, on_select, opts)
	if not ctx.client_id or not ctx.session_id then
		error(title .. " requires a client and a session", 0)
	end
	local stdout = M.run(ctx, list_cmd, nil, { client = false })
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

return M
