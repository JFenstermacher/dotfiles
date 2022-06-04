local cmd = vim.cmd
local indent = 2
local g = vim.g

local M = {}

function M.bind_globals(opts)
  for key, value in pairs(opts) do
    g[key] = value
  end
end

function M.bind_opts(opts)
  local set = vim.opt
  for key, value in pairs(opts) do
    set[key]  = value
  end
end

M.bind_opts{
  autowrite      = true,                    -- Autowrite buffer when leaving buffer
  background     = 'dark',                  -- Inherite background to use
  belloff        = 'all',                   -- Please stop
  clipboard      = 'unnamedplus',           -- Connection to system clipboard
  completeopt    = {'menuone', 'noselect'}, -- Options for insert mode completion
  hidden         = true,                    -- Ignore unsaved buffers
  ignorecase     = true,                    -- Case insensitive searching
  scrolloff      = 8,                       -- Number of lines to keep above and below the cursor
  smartcase      = true,                    -- Case sensitivie searching
  splitbelow     = true,                    -- Splitting a new window below the current one
  splitright     = true,                    -- Splitting a new window at the right of the current one
  termguicolors  = true,                    -- Enable 24-bit RGB color in the TUI
  undofile       = true,                    -- Enable persistent undo
  hlsearch       = true,                    -- Highlight all the matches of search pattern
  swapfile       = false,                   -- Disable use of swapfile for the buffer
  colorcolumn    = '120',                   -- Colored column at 120
  wrap           = true,                    -- Disable wrapping of lines longer than the width of window
  number         = true,                    -- Show numberline
  relativenumber = true,                    -- Show relative numberline
  expandtab      = true,                    -- Enable the use of space in tab
  shiftwidth     = indent,                  -- Number of space inserted for indentation
  tabstop        = indent,                  -- Number of space in a tab
  fileencoding   = "utf-8",                 -- File content encoding for the buffer
  spelllang      = "en",                    -- Support US english
}

-- M.bind_globals{
--   do_filetype_lua = 1,    -- use filetype.lua
--   did_load_filetypes = 0  -- don't use filetype.vim
-- }

-- Highlight on yank
cmd 'au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=false}'

-- Change Color Column color
cmd 'highlight colorcolumn ctermbg=0 guibg=lightgrey'

-- cmd 'syntax enable'
-- cmd 'filetype plugin indent on'

return M
