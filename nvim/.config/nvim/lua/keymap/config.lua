local keymap = require('core.keymap')
local nmap, imap, cmap, vmap, xmap = keymap.nmap, keymap.imap, keymap.cmap, keymap.vmap, keymap.xmap
local silent, noremap = keymap.silent, keymap.noremap
local opts = keymap.new_opts
local cmd = keymap.cmd

-- Use space as leader key
vim.g.mapleader = ' '

-- leaderkey
nmap({ ' ', '', opts(noremap) })
xmap({ ' ', '', opts(noremap) })

-- usage example
nmap({
  -- close buffer
  { '<C-x>k', cmd('bdelete'), opts(noremap, silent) },
  -- save
  { '<C-s>', cmd('write'), opts(noremap) },

  -- Yank
  { 'Y', 'y$', opts(noremap) },
  { '<Leader>y', '"+y'},
  { '<Leader>Y', 'gg"+yG'},
  { '<Leader>d', '"_d'},

  -- Remove Trailing spaces
  { '<Leader>t', cmd('TrimTrailingWhitespace'), opts(noremap) },

  -- Window binds
  { '<Leader>wv', ':vsplit<CR>', opts(noremap, silent) },
  { '<Leader>ws', ':split<CR>', opts(noremap, silent) },
  { '<Leader>wh', '<c-w>5<', opts(noremap, silent) },
  { '<Leader>wj', ':resize +5<cr>', opts(noremap, silents) },
  { '<Leader>wk', ':resize -5<cr>', opts(noremap, silent) },
  { '<Leader>wl', '<c-w>5>', opts(noremap, silent) },
  { '<Leader>w=', '<c-w>=', opts(noremap, silent) },
  { '<Leader>w-', '<c-w>_<c-w>|', opts(noremap, silent) },
  { '<Leader>wr', '<c-w>r', opts(noremap, silent) },
  { '<Leader>wo', '<c-w>o', opts(noremap, silent) },
})

vmap({
  -- Better indenting
  {'<', '<gv'},
  {'>', '>gv'},
})

imap({
  -- insert mode
  { '<C-h>', '<Bs>', opts(noremap) },
  { '<C-e>', '<End>', opts(noremap) },
  { 'jk', '<Esc>', opts(noremap) },
})

-- commandline remap
cmap({ '<C-b>', '<Left>', opts(noremap) })
