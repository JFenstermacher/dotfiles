local bind_opts = require 'settings'.bind_globals
local bind_keymaps = require 'keymaps'.bind_keymaps

bind_opts{
  floaterm_wintype = 'split',
  floaterm_position = 'botright',
  floaterm_height = 0.3
}

local keymap_opts = { silent = true }

bind_keymaps{
  {'n', '<F10>', ':FloatermNew<cr>', keymap_opts},
  {'t', '<F10>', [[<c-\><c-n>:FloatermNew<cr>]], keymap_opts},
  {'n', '<F7>', ':FloatermToggle<cr>', keymap_opts},
  {'t', '<F7>', [[<c-\><c-n>:FloatermToggle<cr>]], keymap_opts},
  {'n', '<F9>', ':FloatermNext<cr>', keymap_opts},
  {'t', '<F9>', [[<c-\><c-n>:FloatermNext<cr>]], keymap_opts},
  {'n', '<F8>', ':FloatermPrev<cr>', keymap_opts},
  {'t', '<F8>', [[<c-\><c-n>:FloatermPrev<cr>]], keymap_opts},
  {'n', '<F6>', ':FloatermKill<cr>', keymap_opts},
  {'t', '<F6>', [[<c-\><c-n>:FloatermKill<cr>]], keymap_opts}
}
