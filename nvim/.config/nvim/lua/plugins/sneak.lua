local bind = require 'keymaps'.bind_keymaps

local opts = { noremap = false }

bind{
  {'nxso', 'f', '<Plug>Sneak_f', opts},
  {'nxso', 'F', '<Plug>Sneak_F', opts},
  {'nxso', 't', '<Plug>Sneak_t', opts},
  {'nxso', 'T', '<Plug>Sneak_T', opts},
}
