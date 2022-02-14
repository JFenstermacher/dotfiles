local fn = vim.fn
local util = require('lspconfig.util')
local path = util.path
local fmt = string.format

local M = {
  on_attach = require 'plugins.lsp.on_attach',
  before_init = function(_, config)
    config.settings.python.pythonPath = get_python_path(config.root_dir)
  end,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'off'
      }
    }
  }
}

function get_python_path(workspace)
  -- Use activated virtualenv
  if vim.env.VIRTUAL_ENV then
    return path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- Handle different sorts of setups
  local mappings = {
    ['.venv']       = function(match) return match end,
    ['pyvenv.cfg']  = function(match) return path.dirname(match) end,
    ['Pipfile']     = function(_) return fn.trim(fn.system('pipenv --venv')) end,
    ['poetry.lock'] = function(_) return fn.trim(fn.system('poetry env info -p')) end
  }

  for pattern, prefix_fn in pairs(mappings) do
    local match = vim.fn.glob(path.join(workspace, pattern))

    if match ~= "" then
      local prefix = prefix_fn(match)

      return path.join(prefix, 'bin', 'python')
    end
  end

  return fn.exepath('python3') or fn.exepath('python3') or 'python'
end

return M
