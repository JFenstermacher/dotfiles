local utils = require('configs.utils')
local bind = utils.bind_maps

local silent = { silent = true }

local mappings = { 
  -- <Esc> binding

  {'i', 'jk', '<Esc>'},

  -- Buffer bindings

  {'n', '<Leader>bd', ':bd<CR>'},
  {'n', '<Leader>bfd', ':bd!<CR>'},
  {'n', '<Leader>bs', ':w<CR>'},

  -- Window bindings

  {'n', '<C-H>', '<C-W>h'},
  {'n', '<C-J>', '<C-W>j'},
  {'n', '<C-K>', '<C-W>k'},
  {'n', '<C-L>', '<C-W>l'},

  {'n', '<Leader>wh', ':lefta vsp<CR>', silent},
  {'n', '<Leader>wj', ':sp<CR>', silent},
  {'n', '<Leader>wk', ':lefta sp<CR>', silent},
  {'n', '<Leader>wl', ':vsp<CR>', silent},
  {'n', '<Leader>wo', '<C-W>o'},

  -- Terminal Keys

  {'t', 'jk', [[<C-\><C-n>]]},
  {'t', '<Esc>', '<C-c>'},

  -- Close everything
  {'n', '<Leader>qa', ':qa'},

}

bind(mappings)
