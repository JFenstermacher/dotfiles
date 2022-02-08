local bind = require 'keymaps'.bind_keymaps

local M = {}

function M.launch_runner()
  local ext = vim.fn.expand('%:e')

  local ext_map = {
    ex = 'iex',
    js = 'node',
    py = 'python'
  }

  local runner_cmd = ext_map[ext] or "clear"

  local cmd = string.format(":VtrOpenRunner {'orientation': 'h', 'percentage': 50, 'cmd': '%s'}", runner_cmd)

  vim.cmd(cmd)
end

bind{
  -- trl - TMUX Launch REPL
  {'n', '<leader>tl', ":lua require('plugins.vim-tmux-runner').launch_runner()<CR>"},
  -- tk - TMUX Kill
  {'n', '<leader>tk', ":VtrKillRunner<CR>"},
  {'n', '<leader>tc', ":VtrClearRunner<CR>"},
  {'n', '<leader>ta', ":VtrAttachToPane<CR>"},
  -- ts - TMUX send
  {'nv', '<leader>ts', ':VtrSendLinesToRunner<cr>'}
}

return M
