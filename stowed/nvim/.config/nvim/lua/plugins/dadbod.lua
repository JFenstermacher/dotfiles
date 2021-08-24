local bind_opts = require 'settings'.bind_globals
local bind_keymaps = require 'keymaps'.bind_keymaps

bind_opts{
  db_ui_show_help = 0,
  do_ui_win_position = 'left',
  do_ui_use_nerd_fonts = 1,
  db_ui_winwidth = 35,
  db_ui_auto_execute_table_helpers = true
}

local silent = { silent = true }
bind_keymaps{
  {'n', '<leader>Du', ':DBUIToggle<CR>', silent},
  {'n', '<leader>Df', ':DBUIFindBuffer<CR>', silent},
  {'n', '<leader>Dr', ':DBUIRenameBuffer<CR>', silent},
  {'n', '<leader>Dl', ':DBUILastQueryInfo<CR>', silent}
}
