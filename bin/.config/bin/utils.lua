local M = {}

function M.exec_capture(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end

function M.exec(cmd)
	local status = os.execute(cmd)
	return status
end

-- Walk up from start looking for a *.git directory (bare repo)
function M.find_git_dir(start)
	local current = start or M.exec_capture("pwd"):gsub("%s+", "")
	while current ~= "/" do
		if current:match("%.git$") then
			local check = M.exec_capture(string.format('test -d "%s" && echo yes', current)):gsub("%s+", "")
			if check == "yes" then
				return current
			end
		end
		local found = M.exec_capture(string.format('find "%s" -maxdepth 2 -name "*.git" -type d 2>/dev/null | head -n 1', current)):gsub("%s+", "")
		if found ~= "" then
			return found
		end
		current = current:match("^(.+)/[^/]+$") or "/"
	end
	return nil
end

-- Extract repo context from a git_dir path: parent_dir, repo_name, org_name
function M.repo_context(git_dir)
	local parent_dir = git_dir:match("^(.+)/[^/]+$")
	local repo_name = parent_dir:match("^.+/([^/]+)$")
	local org_dir = parent_dir:match("^(.+)/[^/]+$")
	local org_name = org_dir:match("^.+/([^/]+)$")
	return {
		parent_dir = parent_dir,
		repo_name = repo_name,
		org_name = org_name,
	}
end

-- Parse git worktree list --porcelain, returns array of {path, branch}
function M.get_worktree_branches(git_dir)
	local output = M.exec_capture(string.format('git -C "%s" worktree list --porcelain', git_dir))
	local worktrees = {}
	local current_path = nil
	for line in output:gmatch("[^\n]+") do
		local wt_path = line:match("^worktree (.+)")
		if wt_path then
			current_path = wt_path
		end
		local branch = line:match("^branch refs/heads/(.+)")
		if branch and current_path then
			worktrees[#worktrees + 1] = { path = current_path, branch = branch }
			current_path = nil
		end
	end
	return worktrees
end

function M.session_name(org_name, repo_name, branch_name)
	return (org_name .. "/" .. repo_name .. "@" .. branch_name):gsub("[%. ]", "_")
end

function M.trust_mise(worktree_path)
	if M.exec("command -v mise >/dev/null 2>&1") ~= 0 then
		return
	end
	if M.exec(string.format('test -f "%s/.mise.toml"', worktree_path)) == 0 then
		M.exec(string.format('mise trust -q "%s/.mise.toml" 2>/dev/null', worktree_path))
	elseif M.exec(string.format('test -f "%s/mise.toml"', worktree_path)) == 0 then
		M.exec(string.format('mise trust -q "%s/mise.toml" 2>/dev/null', worktree_path))
	end
end

-- Require git_dir or exit with error
function M.require_git_dir()
	local git_dir = M.find_git_dir()
	if not git_dir then
		io.stderr:write("Error: Could not find a .git directory.\n")
		os.exit(1)
	end
	return git_dir
end

-- Require bare repo (has worktrees dir) or exit with error
function M.require_bare_repo()
	local git_dir = M.require_git_dir()
	if M.exec(string.format('test -d "%s/worktrees"', git_dir)) ~= 0 then
		io.stderr:write("Error: This does not appear to be a bare repository with worktrees.\n")
		io.stderr:write("Re-clone with: git-clone --bare <repo>\n")
		os.exit(1)
	end
	return git_dir
end

-- Create a worktree for a branch, handling local/remote/new cases
function M.create_worktree(git_dir, worktree_path, branch_name)
	local local_exists = M.exec(string.format('git -C "%s" rev-parse --verify "%s" >/dev/null 2>&1', git_dir, branch_name)) == 0

	if local_exists then
		print("Branch '" .. branch_name .. "' exists locally.")
		M.exec(string.format('git -C "%s" worktree add "%s" "%s"', git_dir, worktree_path, branch_name))
	else
		local remote_branch = M.exec_capture(string.format('git -C "%s" branch -r --no-color | grep "/%s$" | head -n 1', git_dir, branch_name)):gsub("^%s+", ""):gsub("%s+$", "")
		if remote_branch ~= "" then
			print("Branch '" .. branch_name .. "' exists on remote as " .. remote_branch .. ".")
			M.exec(string.format('git -C "%s" worktree add -b "%s" "%s" "%s"', git_dir, branch_name, worktree_path, remote_branch))
		else
			print("Branch '" .. branch_name .. "' does not exist. Creating new branch.")
			M.exec(string.format('git -C "%s" worktree add -b "%s" "%s"', git_dir, branch_name, worktree_path))
		end
	end
end

-- Create or switch to a tmux session for a worktree
function M.tmux_switch_or_create(session_name, worktree_path)
	if not os.getenv("TMUX") then
		return false
	end

	if M.exec(string.format('tmux has-session -t "%s" 2>/dev/null', session_name)) == 0 then
		M.exec(string.format('tmux switch-client -t "%s"', session_name))
	else
		M.exec(string.format('TMUX="" tmux new-session -d -s "%s" -c "%s"', session_name, worktree_path))
		M.exec(string.format('tmux send-keys -t "%s" "nvim" Enter', session_name))
		M.exec(string.format('tmux switch-client -t "%s"', session_name))
	end
	return true
end

-- Kill a tmux session if it exists
function M.tmux_kill_session(session_name)
	if not os.getenv("TMUX") then
		return
	end
	if M.exec(string.format('tmux has-session -t "%s" 2>/dev/null', session_name)) == 0 then
		print("Killing tmux session '" .. session_name .. "'...")
		M.exec(string.format('tmux kill-session -t "%s"', session_name))
	end
end

-- Pipe lines to fzf, return selected line(s)
function M.fzf(lines, opts)
	opts = opts or ""
	-- Shell-quote each line individually to handle special characters
	local quoted = {}
	for i, line in ipairs(lines) do
		quoted[i] = "'" .. line:gsub("'", "'\\''") .. "'"
	end
	local handle = io.popen(string.format("printf '%%s\\n' %s | fzf %s", table.concat(quoted, " "), opts))
	local selected = handle:read("*a"):gsub("%s+$", "")
	handle:close()
	return selected
end

-- Get default branch name for a bare repo
function M.default_branch(git_dir)
	return M.exec_capture(string.format(
		'git -C "%s" symbolic-ref --short HEAD 2>/dev/null || git -C "%s" rev-parse --abbrev-ref HEAD',
		git_dir, git_dir
	)):gsub("%s+$", "")
end

function M.in_tmux()
	return os.getenv("TMUX") ~= nil
end

-- Split string by delimiter
function M.str_split(str, delimiter)
	local result = {}
	local pattern = string.format("([^%s]+)", delimiter)
	for match in string.gmatch(str, pattern) do
		result[#result + 1] = match
	end
	return result
end

-- Run command and return output lines as a table
function M.exec_lines(cmd)
	local lines = {}
	local handle = io.popen(cmd, "r")
	if handle then
		for line in handle:lines() do
			lines[#lines + 1] = line
		end
		handle:close()
	end
	return lines
end

-- Trim trailing whitespace
function M.trim(str)
	return str:gsub("%s+$", "")
end

return M
