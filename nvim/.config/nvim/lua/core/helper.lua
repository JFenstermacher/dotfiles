local helper = {}
local home = vim.env.HOME
local fmt = string.format

function helper.get_config_path()
  local config = os.getenv('XDG_CONFIG_DIR')
  if not config then
    config = home .. '/.config'
  end

  return string.format("%s/nvim", config)
end

function helper.get_data_path()
  local data = os.getenv('XDG_DATA_DIR')
  if not data then
    data = home .. '/.local/share'
  end

  return string.format("%s/nvim", data)
end

function helper.get_cache_path()
  local cache = os.getenv('XDG_CACHE_DIR')
  if not cache then
    cache = home .. '/.cache'
  end

  return string.format("%s/nvim", cache)
end

function helper.readdir(dir)
  local files = vim.split(vim.fn.globpath(dir, '*'), '\n')
  local roots = vim.tbl_map(function(file) return vim.fn.fnamemodify(file, ':t:r') end, files)
  return vim.tbl_filter(function(file) return file ~= 'init' end, roots)
end

return helper
