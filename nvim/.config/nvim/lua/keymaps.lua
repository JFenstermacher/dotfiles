local noremap = { noremap = false }
local silent = { silent = true }

local M = {
  ['core'] = {
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
    {'n', '<C-h>', '<C-w>h'},
    {'n', '<C-j>', '<C-w>j'},
    {'n', '<C-k>', '<C-w>k'},
    {'n', '<C-l>', '<C-w>l'},
    {'t', '<C-h>', [[<C-\><C-n><C-w>h]]},
    {'t', '<C-j>', [[<C-\><C-n><C-w>j]]},
    {'t', '<C-k>', [[<C-\><C-n><C-w>k]]},
    {'t', '<C-l>', [[<C-\><C-n><C-w>l]]},
    {'n', '<leader>wv', ':vsplit<CR>'},
    {'n', '<leader>ws', ':split<CR>'},
    {'n', '<leader>wh', '<c-w>5<'},
    {'n', '<leader>wj', ':resize +5<cr>'},
    {'n', '<leader>wk', ':resize -5<cr>'},
    {'n', '<leader>wl', '<c-w>5>'},
    {'n', '<leader>w=', '<c-w>='},
    {'n', '<leader>w-', '<c-w>_<c-w>|'},
    {'n', '<leader>wr', '<c-w>r'},
    {'n', '<leader>wo', '<c-w>o'},

    -- Location list
    {'n', ']l', ':lnext<cr>'},
    {'n', '[l', ':lprev<cr>'},

    -- QuickFix
    {'n', ']c', ':cnext<cr>'},
    {'n', '[c', ':cprev<cr>'},

    -- Terminal Keys
    {'t', 'jk', [[<C-\><C-n>]]},
    {'t', '<esc>', '<c-c>'},

    -- Better indenting
    {'v', '<', '<gv'},
    {'v', '>', '>gv'},

    -- Better movements
    {'nv', 'j', 'gj', noremap},
    {'nv', 'k', 'gk', noremap},
    {'n', 'H', '^'},
    {'n', 'L', '$'},

    -- Yank
    {'nv', '<leader>y', '"+y'},
    {'n', '<leader>Y', 'gg"+yG'},
    {'nv', '<leader>d', '"_d'}
  },
  ['junegunn/vim-easy-align'] = {{'nx', 'ga', '<Plug>(EasyAlign)', { silent = true, noremap = false }}},
  ['kristijanhusak/vim-dadbod-ui'] = {
    {'n', '<leader>Du', ':DBUIToggle<CR>',        silent},
    {'n', '<leader>Df', ':DBUIFindBuffer<CR>',    silent},
    {'n', '<leader>Dr', ':DBUIRenameBuffer<CR>',  silent},
    {'n', '<leader>Dl', ':DBUILastQueryInfo<CR>', silent}
  },
  ['glepnir/dashboard-nvim'] = {{'n', '<leader>fn', ':DashboardNewFile<cr>', silent}},
  ['tpope/vim-fugitive'] = {
    {'n', '<leader>gs',  ':Git<cr>',                        silent},
    {'n', '<leader>gcb', ':Git blame<cr>',                  silent},
    {'n', '<leader>gd',  ':Gdiff<cr>',                      silent},
    {'n', '<leader>gp',  ':Git push<cr>',                   silent},
    {'n', '<leader>gl',  ':Git pull<cr>',                   silent},
    {'n', '<leader>gf',  ':Git fetch<cr>',                  silent},
    {'n', '<leader>gcc', ':Git commit --verbose<cr>',       silent},
    {'n', '<leader>gca', ':Git commit --all --verbose<cr>', silent},
    {'n', '<leader>gdl', ':diffget LOCAL<cr>',              silent},
    {'n', '<leader>gdr', ':diffget REMOTE<cr>',             silent},
  },
  ['nvim-telescope/telescope.nvim'] = {
    {'n', '<leader>pf', ':Telescope find_files<cr>',   silent},
    {'n', '<leader>gb', ':Telescope git_branches<cr>', silent},
    {'n', '<leader>fb', ':Telescope buffers<cr>',      silent},
    {'n', '<leader>fg', ':Telescope git_files<cr>',    silent},
    {'n', '<leader>fo', ':Telescope oldfiles<cr>',     silent},
    {'n', '<leader>fw', ':Telescope live_grep<cr>',    silent},
    {'n', '<leader>fk', ':Telescope keymaps<cr>',      silent},
    {'n', '<leader>fp', ':Telescope projects<cr>',     silent}
  },
  ['justinmk/vim-sneak'] = {
    {'nxso', 'f', '<Plug>Sneak_f', noremap},
    {'nxso', 'F', '<Plug>Sneak_F', noremap},
    {'nxso', 't', '<Plug>Sneak_t', noremap},
    {'nxso', 'T', '<Plug>Sneak_T', noremap},
  },
  ['voldikss/vim-floaterm'] = {
    {'n', '<F10>', ':FloatermNew<cr>',                silent},
    {'t', '<F10>', [[<c-\><c-n>:FloatermNew<cr>]],    silent},
    {'n', '<F7>',  ':FloatermToggle<cr>',             silent},
    {'t', '<F7>',  [[<c-\><c-n>:FloatermToggle<cr>]], silent},
    {'n', '<F9>',  ':FloatermNext<cr>',               silent},
    {'t', '<F9>',  [[<c-\><c-n>:FloatermNext<cr>]],   silent},
    {'n', '<F8>',  ':FloatermPrev<cr>',               silent},
    {'t', '<F8>',  [[<c-\><c-n>:FloatermPrev<cr>]],   silent},
    {'n', '<F6>',  ':FloatermKill<cr>',               silent},
    {'t', '<F6>',  [[<c-\><c-n>:FloatermKill<cr>]],   silent},
    -- Python Sucks
    {'v', '<leader>ps', ':s/^$/#/ | execute "normal gv" | noh<cr>', silent},
    -- Python UnSucks
    {'v', '<leader>pu', ':s/^#//<cr>', silent},
    {'n', '<leader>rl', ':FloatermNew --wintype=vsplit --name=repl --width=0.5<cr>', silent},
    {'nv', '<leader>rs', ':FloatermSend --name=repl<cr>', silent}
  }
}

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

function M.bind_plugin(plugin_name)
  mappings = M[plugin_name]

  if mappings then
    M.bind_keymaps(mappings)
  end
end

M.bind_keymaps(M.core)

return M
