local cmd = vim.cmd
local o, wo, bo = vim.o, vim.wo, vim.bo
local utils = require('configs.utils')
local bind = utils.bind_opts

local indent = 2

cmd 'syntax enable'
cmd 'filetype plugin indent on'

local global = {o}
local buffer = {o, bo}
local window = {o, wo}

local function bind_opts(opts)
  for _, value in ipairs(opts) do
    opt(unpack(value))
  end
end

local opts = {
  -- Global Scoped Options

  {'background', 'dark', global},
  {'clipboard', 'unnamed,unnamedplus', global},
  {'completeopt', 'menuone,noselect', global},
  {'guicursor', '', global},
  {'hidden', true, global},
  {'ignorecase', true, global},
  {'scrolloff', 8, global},
  {'smartcase', true, global},
  {'splitbelow', true, global},
  {'splitright', true, global},
  {'termguicolors', true, global},
  {'wildmode', 'list:longest', global},

  -- Window Scoped Options

  {'colorcolumn', '120', window},
  {'wrap', false, window},
  {'number', true, window},
  {'relativenumber', true, window},

  -- Buffer Scoped Options

  {'expandtab', true, buffer},
  {'shiftwidth', indent, buffer},
  {'smartindent', true, buffer},
  {'softtabstop', indent, buffer},
  {'tabstop', indent, buffer}
}

bind(opts)

-- Colorscheme
cmd 'colorscheme gruvbox-material'

-- Highlight on yank
cmd 'au TextYankPost * lua vim.highlight.on_yank {on_visual = false}'

-- Change Color Column color
cmd 'highlight ColorColumn ctermbg=0 guibg=lightgrey'
