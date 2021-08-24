local bind_opts = require 'settings'.bind_globals
local bind_keymaps = require 'keymaps'.bind_keymaps

bind_opts{
  floaterm_wintype = 'split',
  floaterm_position = 'botright',
  floaterm_height = 0.3
}

local keymap_opts = { silent = true }

bind_keymaps{
  {'n', '<leader>tn', ':FloatermNew<cr>', keymap_opts},
  {'t', '<leader>tn', [[<c-\><c-n>:FloatermNew<cr>]], keymap_opts},
  {'n', '<leader>to', ':FloatermToggle<cr>', keymap_opts},
  {'t', '<leader>to', [[<c-\><c-n>:FloatermToggle<cr>]], keymap_opts},
  {'n', '<leader>tj', ':FloatermNext<cr>', keymap_opts},
  {'t', '<leader>tj', [[<c-\><c-n>:FloatermNext<cr>]], keymap_opts},
  {'n', '<leader>tk', ':FloatermPrev<cr>', keymap_opts},
  {'t', '<leader>tk', [[<c-\><c-n>:FloatermPrev<cr>]], keymap_opts},
  {'n', '<leader>tc', ':FloatermKill<cr>', keymap_opts},
  {'t', '<leader>tc', [[<c-\><c-n>:FloatermKill<cr>]], keymap_opts}
}
