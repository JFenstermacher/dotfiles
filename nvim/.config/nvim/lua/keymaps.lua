local M = {}

function M.bind_keymap(modes, lhs, rhs, opts)
  local map = vim.api.nvim_set_keymap
  local defaults = { noremap = true }

  for mode in modes:gmatch('.') do
    map(mode, lhs, rhs, vim.tbl_extend('force', defaults, opts or {}))
  end
end

function M.bind_keymaps(mappings)
  for _, value in ipairs(mappings) do
    M.bind_keymap(unpack(value))
  end
end

local silent = { silent = true }
local remap = { noremap = false }

local mappings = {
  -- <Esc> binding
  {'i', 'jk', '<esc>'},
  {'ni', '<esc>', '<c-c>'},

  -- Buffer bindings

  {'n', '<leader>bj', ':bprevious<CR>'},
  {'n', '<leader>bk', ':bnext<CR>'},
  {'n', '<leader>bh', ':bfirst<CR>'},
  {'n', '<leader>bl', ':blast<CR>'},
  {'n', '<leader>bd', ':bd!<CR>'},

  -- Window bindings

  {'n', '<leader>wv', ':vsplit<CR>'},
  {'n', '<leader>ws', ':split<CR>'},
  {'n', '<leader>wH', '<c-w>5<'},
  {'n', '<leader>wJ', ':resize +5<cr>'},
  {'n', '<leader>wK', ':resize -5<cr>'},
  {'n', '<leader>wL', '<c-w>5>'},
  {'n', '<leader>w=', '<c-w>='},
  {'n', '<leader>wr', '<c-w>r'},
  {'n', '<leader>wo', '<c-w>o'},

  -- Location list
  {'n', '<leader>tl', ':lua toggle_loclist()<cr>'},
  {'n', ']l', ':lnext<cr>'},
  {'n', '[l', ':lprev<cr>'},

  -- QuickFix
  {'n', '<leader>tq', ':lua toggle_quickfix()<cr>'},
  {'n', ']c', ':cnext<cr>'},
  {'n', '[c', ':cprev<cr>'},

  -- Terminal Keys

  {'t', 'jk', [[<C-\><C-n>]]},
  {'t', '<esc>', '<c-c>'},

  -- Better indenting
  {'v', '<', '<gv'},
  {'v', '>', '>gv'},

  -- Better movements
  {'nv', 'j', 'gj', remap},
  {'nv', 'k', 'gk', remap},
  {'n', 'H', '^'},
  {'n', 'L', '$'},

  -- Yank
  {'nv', '<leader>y', '"+y'},
  {'n', '<leader>Y', 'gg"+yG'},
  {'nv', '<leader>d', '"_d'}
}

M.bind_keymaps(mappings)

return M
