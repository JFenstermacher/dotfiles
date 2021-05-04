local utils = require('utils')

-- <Esc> binding
utils.map('i', 'jk', '<Esc>')

-- Quick window keys
utils.map('n', '<C-H>', '<C-W>h', { noremap = true })
utils.map('n', '<C-J>', '<C-W>j', { noremap = true })
utils.map('n', '<C-K>', '<C-W>k', { noremap = true })
utils.map('n', '<C-L>', '<C-W>l', { noremap = true })

utils.map('n', '<leader>wh', '<C-W>h', { noremap = true })
utils.map('n', '<leader>wj', '<C-W>j', { noremap = true })
utils.map('n', '<leader>wk', '<C-W>k', { noremap = true })
utils.map('n', '<leader>wl', '<C-W>l', { noremap = true })

utils.map('n', '<leader>wv', ':vsp<CR>', { silent = true })
utils.map('n', '<leader>ws', ':sp<CR>', { silent = true })

utils.map('n', '<leader>ff', ':Telescope find_files<CR>', { silent = true })
