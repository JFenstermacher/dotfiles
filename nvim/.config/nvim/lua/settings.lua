local cmd = vim.cmd
local o, wo, bo = vim.o, vim.wo, vim.bo
local indent = 2

local global = {o}
local window = {o, wo}
local buffer = {o, bo}

local M = {
  global = global,
  window = window,
  buffer = buffer
}

function M.bind_opt(opt, value, scopes)
  for _, scope in ipairs(scopes) do scope[opt] = value end
end

function M.bind_opts(opts)
  for _, opt in ipairs(opts) do M.bind_opt(unpack(opt)) end
end

function M.bind_globals(opts)
  for key, value in pairs(opts) do
    vim.g[key] = value
  end
end

local opts = {
  -- Global Scoped Options

  {'autowrite', true, global},
  {'background', 'dark', global},
  {'belloff', 'all', global},
  {'clipboard', 'unnamed,unnamedplus', global},
  {'completeopt', 'menu,menuone,noselect', global},
  {'display', 'lastline', global},
  {'guicursor', '', global},
  {'hidden', true, global},
  {'ignorecase', true, global},
  {'scrolloff', 8, global},
  {'showcmd', true, global},
  {'smartcase', true, global},
  {'splitbelow', true, global},
  {'splitright', true, global},
  {'termguicolors', true, global},
  {'wildmode', 'list:longest', global},

  -- Window Scoped Options

  {'colorcolumn', '120', window},
  {'wrap', true, window},
  {'number', true, window},
  {'relativenumber', true, window},

  -- Buffer Scoped Options

  {'autoindent', true, buffer},
  {'expandtab', true, buffer},
  {'shiftwidth', indent, buffer},
  {'softtabstop', indent, buffer},
  {'tabstop', indent, buffer}
}

M.bind_opts(opts)

-- Highlight on yank
cmd 'au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=false}'

-- Change Color Column color
cmd 'highlight colorcolumn ctermbg=0 guibg=lightgrey'

cmd 'syntax enable'
cmd 'filetype plugin indent on'

return M
