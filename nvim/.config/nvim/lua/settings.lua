local utils = require('utils')

local cmd = vim.cmd
local indent = 2

cmd 'syntax enable'
cmd 'filetype plugin indent on'

local function bind_opts(scope, mapping)
  for option,value in pairs(mapping) do
    utils.opt(scope, option, value) 
  end
end

-- Global Scoped Options

local global_opts = {
  clipboard = 'unnamed,unnamedplus',
  guicursor = '',
  hidden = true,
  ignorecase = true,
  scrolloff = 8,
  smartcase = true,
  splitbelow = true,
  splitright = true,
  wildmode = 'list:longest'
}

bind_opts('o', global_opts)

-- Window Scoped Options

local window_opts = {
  colorcolumn = '120',
  wrap = false,
  number = true,
  relativenumber = true
}

bind_opts('w', window_opts)

-- Buffer Scoped Options

local buffer_opts = {
  expandtab = true,
  shiftwidth = indent,
  smartindent = true,
  softtabstop = indent,
  tabstop = indent
}

bind_opts('b', buffer_opts)

-- Highlight on yank
cmd 'au TextYankPost * lua vim.highlight.on_yank {on_visual = false}'

-- Change Color Column color
cmd 'highlight ColorColumn ctermbg=0 guibg=lightgrey'
