local bind = require 'keymaps'.bind_keymaps

local silent = { silent = true }

bind{
  {'n', '<leader>gs', ':Git<cr>', silent},
  {'n', '<leader>gb', ':Git blame<cr>', silent},
  {'n', '<leader>gd', ':Gdiff<cr>', silent},
  {'n', '<leader>gp', ':Git push<cr>', silent},
  {'n', '<leader>gl', ':Git pull<cr>', silent},
  {'n', '<leader>gf', ':Git fetch<cr>', silent},
  {'n', '<leader>gcc', ':Git commit --verbose<cr>', silent},
  {'n', '<leader>gca', ':Git commit -all --verbose<cr>', silent},
  {'n', '<leader>gdl', ':diffget LOCAL<cr>', silent},
  {'n', '<leader>gdr', ':diffget REMOTE<cr>', silent},
}
