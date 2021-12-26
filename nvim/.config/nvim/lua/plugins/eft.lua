local bind = require 'keymaps'.bind_keymaps
local remap = { noremap = false }

bind{
  {'nxo', 'f', "<Plug>(eft-f)", remap},
  {'nxo', 'F', "<Plug>(eft-F)", remap}
}
