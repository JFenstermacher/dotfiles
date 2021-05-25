local fn = vim.fn
local utils = require('configs.utils')

local config_dir = fn.stdpath('config')

local function load_configs(dir)
  local config_dir = fn.stdpath('config') .. '/lua/configs'
  local tmp = vim.split(fn.globpath(config_dir, '*.lua'), '\n')
  
  local config_files = {}
  for _, f in ipairs(tmp) do
    if not vim.endswith(f, 'init.lua') and not vim.endswith(f, 'utils.lua') then
      config_files[#config_files + 1] = f:sub(#config_dir - 6)
    end
  end
  
  local config = {}
  for _, cf in ipairs(config_files) do
    local no_ext = cf:sub(0, -5)
    local name = no_ext:match("^.+/(.+)$")
    
    config[name] = require(no_ext)
  end
  
  return config
end

return load_configs()
