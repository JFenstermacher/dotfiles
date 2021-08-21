local bind = require 'keymaps'.bind_maps
local silent = { silent = true }

bind{
  {'n', '<F7>', ':FloatermNew<cr>', silent},
  {'t', '<F7>', [[<C-\><C-n>:FloatermNew<cr>]], silent},
  {'n', '<F8>', ':FloatermPrev<cr>', silent},
  {'t', '<F8>', [[<C-\><C-n>:FloatermPrev<cr>]], silent},
  {'n', '<F9>', ':FloatermNext<cr>', silent},
  {'t', '<F9>', [[<C-\><C-n>:FloatermNext<cr>]], silent},
  {'n', '<F12>', ':FloatermToggle<cr>', silent},
  {'t', '<F12>', [[<C-\><C-n>:FloatermToggle<cr>]], silent}
}
