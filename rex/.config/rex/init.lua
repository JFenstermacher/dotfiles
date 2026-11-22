local function regent(ctx, command, session)
  if not ctx.client_id or not session then
    error("Session history requires a client and a session", 0)
  end

  local data_home = os.getenv("MISE_DATA_DIR")
  if not data_home or data_home == "" then
    local xdg = os.getenv("XDG_DATA_HOME")
    if not xdg or xdg == "" then xdg = os.getenv("HOME") .. "/.local/share" end
    data_home = xdg .. "/mise"
  end
  local path = data_home .. "/shims:" .. (os.getenv("PATH") or "/usr/bin:/bin")
  -- Rex actions do not inherit the interactive shell's Rex CLI path.
  local rex_bin = os.getenv("REX_BIN_DIR")
  if not rex_bin or rex_bin == "" then
    local bundled = os.getenv("HOME") .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"
    local cli = io.open(bundled .. "/rex", "r")
    if cli then cli:close(); rex_bin = bundled end
  end
  if rex_bin and rex_bin ~= "" then path = rex_bin .. ":" .. path end
  local args = { "env", "PATH=" .. path, "regent", "session", command, "--client", ctx.client_id }
  if command == "last" then args[#args + 1] = "--current-session" end
  args[#args + 1] = session
  local result, err = rex.exec(args)
  if not result then error(err, 0) end
  if not result.ok then error(result.stderr ~= "" and result.stderr or "Regent session command failed", 0) end
end

rex.action{
  name = "switch_session",
  title = "Change Session",
  run = function(ctx)
    regent(ctx, "record", ctx.session_id)
    rex.client.queue("session.switch")
  end,
}

rex.action{
  name = "last_session",
  title = "Go to Last Session",
  run = function(ctx)
    regent(ctx, "last", ctx.session_id)
  end,
}

rex.action{
  name = "home_session",
  title = "Go to Home Session",
  run = function(ctx)
    local user = os.getenv("USER")
    local home = os.getenv("HOME")
    if not user or user == "" or not home or home == "" then
      error("USER and HOME must be set", 0)
    end

    local result, err = rex.call("session.list")
    if err then error(err, 0) end

    local session_id
    for _, session in ipairs(result.sessions or {}) do
      if session.label == user then
        session_id = session.session_id
        break
      end
    end

    if not session_id then
      result, err = rex.call("session.create", {
        label = user,
        initial_windows = {{
          layout = rex.layout.block{
            flavor = "com.superlogical.terminal.shell",
            options = { cwd = home },
          },
        }},
      })
      if err then error(err, 0) end
      session_id = result.session_id
    end

    if session_id ~= ctx.session_id then
      regent(ctx, "record", ctx.session_id)
      regent(ctx, "record", session_id)
    end
    rex.client.queue("session.select", { session_id = session_id })
  end,
}

rex.action{
  name = "copy_mode",
  title = "Open Neovim Copy Mode",
  run = function(ctx)
    if not ctx.block_id then error("Copy mode requires a terminal pane", 0) end

    local source, err = rex.session.describe_block{ block_id = ctx.block_id }
    if err then error(err, 0) end
    local block = source.block
    if block.creator_name ~= "com.superlogical.terminal" or not block.window_id then
      error("Copy mode requires a terminal pane", 0)
    end

    local config_home = os.getenv("XDG_CONFIG_HOME")
    if not config_home or config_home == "" then config_home = os.getenv("HOME") .. "/.config" end
    local viewer
    viewer, err = rex.session.new_layer{
      window_id = block.window_id,
      bounds = { 0, 0, 1, 1 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "Copy Mode",
        options = {
          interactive = true, -- Put mise's Neovim and Rex on PATH.
          command = {
            "env", "REX_COPY_SESSION=" .. ctx.session_id, "REX_COPY_BLOCK=" .. ctx.block_id,
            "nvim", "-u", config_home .. "/rex/copy-mode.nvim.lua", "-i", "NONE", "-n", "--noplugin",
          },
        },
      },
    }
    if err then error(err, 0) end
    return viewer
  end,
}

rex.action{
  name = "repository_picker",
  title = "Switch Repository…",
  run = function(ctx)
    if not ctx.client_id or not ctx.session_id then
      error("Repository picker requires a client and a session", 0)
    end

    local picker, err = rex.session.new_layer{
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "Repositories",
        options = {
          interactive = true, -- Put mise's Regent and fzf on PATH.
          command = {
            "sh", "-c", [[
              "$@" || {
                status=$?
                printf '\nPress Enter to close the picker.\n' >&2
                read -r _
                exit "$status"
              }
            ]], "repository-picker",
            "regent", "repo", "switch", "--interactive",
            "--client", ctx.client_id, "--current-session", ctx.session_id,
          },
        },
      },
    }
    if err then error(err, 0) end
    return picker
  end,
}

rex.bind("ctrl+a>[", "copy_mode")
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>v", "pane.split", { direction = "right" })
rex.bind("ctrl+a>s", "pane.split", { direction = "down" })
rex.bind("ctrl+a>shift+h", "home_session")
rex.bind("ctrl+a>j", "switch_session")
rex.bind("ctrl+a>p", "repository_picker")
rex.bind("ctrl+a>shift+l", "last_session")
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })

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
    if err then error(err, 0) end
    return true
  end)
end
