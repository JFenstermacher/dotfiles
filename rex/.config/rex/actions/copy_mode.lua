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
