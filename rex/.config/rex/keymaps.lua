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
rex.bind("ctrl+a>n", "branch_add")
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
