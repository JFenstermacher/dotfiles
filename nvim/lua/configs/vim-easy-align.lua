local M = {}

function M.config()
  local map = require('configs.utils').map

  map({'x', 'n'}, 'ga', '<Plug>(EasyAlign)', { silent = true, noremap = false })
end

return M
