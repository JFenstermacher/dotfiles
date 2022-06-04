local fn = vim.fn

function P(tbl)
  print(vim.inspect(tbl))
end

_G.toggle_quickfix = function()
  local cmd = 'copen'
  for _, win in pairs(fn.getwininfo()) do
    if win.quickfix == 1 then cmd = 'cclose' end
  end

  vim.cmd(cmd)
end

_G.toggle_loclist = function()
  local cmd = 'lopen'
  for _, win in pairs(fn.getwininfo()) do
    if win.loclist == 1 then cmd = 'lclose' end
  end

  vim.cmd(cmd)
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
  vim.g.do_filetype_lua = 1
  vim.g.did_load_filetype = 0

  disable_plugins()
end

init()
