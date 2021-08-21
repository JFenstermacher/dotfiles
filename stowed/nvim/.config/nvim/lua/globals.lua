local fn = vim.fn
local execute = vim.api.nvim_command

_G.win_move_or_split = function(key)
  if fn.winnr() == fn.winnr(key) then
    local cmds = {
      h = ':lefta vsp',
      j = ':sp',
      k = ':lefta sp',
      l = ':vsp'
    }

    execute(cmds[key])
  else
    execute(':wincmd ' .. key)
  end
end

-- Map leader to space
vim.g.mapleader = [[ ]]

local function disable_plugins()
  -- Disable some built-in plugins
  local disable_built_ins = {
    'gzip',
    'man',
    'matchit',
    'shada_plugin',
    'tarPlugin',
    'tar',
    'zipPlugin',
    'zip',
  }

  for _, plg in ipairs(disable_built_ins) do vim.g['loaded_' .. plg] = 1 end
end

local function init()
  disable_plugins()
end

init()
