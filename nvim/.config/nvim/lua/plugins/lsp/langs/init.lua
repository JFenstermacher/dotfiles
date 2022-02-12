local fn = vim.fn
local fmt = string.format

local M = {}

local function readdir()
  local dir = fmt('%s/lua/plugins/lsp/langs', fn.stdpath('config'))

  local files = vim.split(fn.globpath(dir, '*'), '\n')
  local roots = vim.tbl_map(function(file) return fn.fnamemodify(file, ':t:r') end, files)
  local langs = vim.tbl_filter(function(file) return file ~= 'init' end, roots)

  return langs
end

function M:init()
  local langs = readdir()

  for _, lang in ipairs(langs) do
    local module = fmt('plugins.lsp.langs.%s', lang)
    self[lang] = require(module)
  end
end

M:init()

return M
