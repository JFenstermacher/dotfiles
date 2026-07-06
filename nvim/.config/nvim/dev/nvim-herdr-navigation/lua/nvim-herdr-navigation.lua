-- nvim-herdr-navigation: Seamless navigation between Vim splits and herdr panes.
-- Adapted from nvim-tmux-navigation by alexghergh.

local M = {}

local config = {
  disable_when_zoomed = false,
  keybindings = {},
}

--- Navigate within Vim windows.
local function vim_navigate(direction)
  if direction == "n" then
    pcall(vim.cmd, "wincmd w")
  elseif direction == "p" then
    pcall(vim.cmd, "wincmd p")
  elseif pcall(vim.cmd, "wincmd " .. direction) then
    -- success
  else
    vim.cmd(
      [[ echohl ErrorMsg | echo 'E11: Invalid in command-line window; <CR> executes, CTRL-C quits' | echohl None ]]
    )
  end
end

--- Check whether the current herdr pane is zoomed.
local function is_herdr_pane_zoomed()
  local ok, result = pcall(vim.fn.system, { "herdr", "pane", "edges", "--current" })
  if not ok then
    return false
  end
  return result:find('"zoomed":true') ~= nil
end

--- Determine whether herdr should take over navigation.
---@param is_same_winnr boolean  true if the Vim window didn't change after wincmd
local function should_herdr_control(is_same_winnr)
  if config.disable_when_zoomed and is_herdr_pane_zoomed() then
    return false
  end
  return is_same_winnr
end

--- Map Vim direction keys to herdr directions.
local herdr_directions = {
  h = "left",
  j = "down",
  k = "up",
  l = "right",
}

--- Focus a herdr pane in the given direction.
local function herdr_focus_pane(direction)
  local herdr_dir = herdr_directions[direction]
  if not herdr_dir then
    return
  end
  vim.fn.system({ "herdr", "pane", "focus", "--direction", herdr_dir })
end

--- Track whether the last navigation crossed into a herdr pane.
--- Used so that navigating "back" re-enters the herdr pane.
local herdr_control = true

--- Navigate within Vim, falling back to herdr at split edges.
local function herdr_navigate(direction)
  if direction == "n" then
    local is_last_win = vim.fn.winnr() == vim.fn.winnr("$")
    if is_last_win then
      pcall(vim.cmd, "wincmd t")
    else
      vim_navigate(direction)
    end
  elseif direction == "p" then
    vim_navigate(direction)
  else
    local winnr = vim.fn.winnr()
    vim_navigate(direction)
    local is_same_winnr = winnr == vim.fn.winnr()

    if should_herdr_control(is_same_winnr) then
      herdr_focus_pane(direction)
      herdr_control = true
    else
      herdr_control = false
    end
  end
end

--- Setup function for user configuration.
---@param user_config? { disable_when_zoomed?: boolean, keybindings?: table<string, string> }
function M.setup(user_config)
  user_config = user_config or {}
  config.disable_when_zoomed = user_config.disable_when_zoomed or false
  config.keybindings = user_config.keybindings or {}

  for func, mapping in pairs(config.keybindings) do
    local capitalized = func:gsub("^%l", string.upper):gsub("_(%l)", function(c)
      return c:upper()
    end)

    vim.api.nvim_set_keymap(
      "n",
      mapping,
      ":lua require'nvim-herdr-navigation'.NvimHerdrNavigate" .. capitalized .. "()<CR>",
      { noremap = true, silent = true }
    )
  end
end

-- Select navigation strategy based on environment.
local navigate = vim.env.HERDR_ENV ~= nil and herdr_navigate or vim_navigate

-- Exported Lua functions.
function M.NvimHerdrNavigateLeft() navigate("h") end
function M.NvimHerdrNavigateDown() navigate("j") end
function M.NvimHerdrNavigateUp() navigate("k") end
function M.NvimHerdrNavigateRight() navigate("l") end
function M.NvimHerdrNavigateLastActive() navigate("p") end
function M.NvimHerdrNavigateNext() navigate("n") end

-- Create user commands for keymap / command-line usage.
vim.api.nvim_create_user_command("NvimHerdrNavigateLeft", function() navigate("h") end, {})
vim.api.nvim_create_user_command("NvimHerdrNavigateDown", function() navigate("j") end, {})
vim.api.nvim_create_user_command("NvimHerdrNavigateUp", function() navigate("k") end, {})
vim.api.nvim_create_user_command("NvimHerdrNavigateRight", function() navigate("l") end, {})
vim.api.nvim_create_user_command("NvimHerdrNavigateLastActive", function() navigate("p") end, {})
vim.api.nvim_create_user_command("NvimHerdrNavigateNext", function() navigate("n") end, {})

return M