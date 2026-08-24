-- hooks/backend_exec_env.lua
-- BackendExecEnv: exposes an installed shipyard binary on the PATH.
--
-- Each installed tool lives directly in `ctx.install_path` as a single
-- executable named after the tool (e.g. `sessionizer`). This hook prepends
-- that directory to PATH so the binary resolves like any other tool.

-- @param ctx {install_path: string, tool: string}
-- @return {env_vars} Environment additions

function PLUGIN:BackendExecEnv(ctx)
    if not ctx.install_path or ctx.install_path == "" then
        error("mimiskelda: install_path cannot be empty")
    end

    -- Prepend the install dir (containing the tool binary) to PATH.
    local path_entries = { ctx.install_path }
    local existing = os.getenv("PATH")
    if existing and existing ~= "" then
        -- Prepend ahead of existing so an installed binary shadows any
        -- globally available copy of the same name.
        path_entries[#path_entries + 1] = existing
    end

    return {
        env_vars = {
            { key = "PATH", value = table.concat(path_entries, ":") },
        },
    }
end