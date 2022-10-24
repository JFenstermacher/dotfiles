require('keymap.config')
local key = require('core.keymap')
local nmap, vmap = key.nmap, key.vmap
local silent, noremap = key.silent, key.noremap
local opts = key.new_opts
local cmd = key.cmd

nmap({
  -- Packer
  { '<Leader>pu', cmd('PackerUpdate'),  opts(noremap, silent)},
  { '<Leader>pi', cmd('PackerInstall'), opts(noremap, silent)},
  { '<Leader>pc', cmd('PackerCompile'), opts(noremap, silent)},

  -- Dashboard
  { '<Leader>n', cmd('DashboardNewFile'), opts(noremap, silent) },

  -- Telescope
  { '<Leader>b',  cmd('Telescope buffers'),                 opts(noremap, silent)},
  { '<Leader>fw', cmd('Telescope live_grep'),               opts(noremap, silent)},
  { '<Leader>pf', cmd('Telescope find_files'),              opts(noremap, silent)},
  { '<Leader>fq', cmd('Telescope quickfix'),                opts(noremap, silent)},
  { '-',          cmd('Telescope file_browser path=%:p:h'), opts(noremap, silent)},

  -- TMUX navigation
  { '<C-h>', [[:lua require('nvim-tmux-navigation').NvimTmuxNavigateLeft()<CR>]],  opts(noremap, silent)},
  { '<C-j>', [[:lua require('nvim-tmux-navigation').NvimTmuxNavigateDown()<CR>]],  opts(noremap, silent)},
  { '<C-k>', [[:lua require('nvim-tmux-navigation').NvimTmuxNavigateUp()<CR>]],    opts(noremap, silent)},
  { '<C-l>', [[:lua require('nvim-tmux-navigation').NvimTmuxNavigateRight()<CR>]], opts(noremap, silent)},

  -- Git
  {'<Leader>gs',  ':Git<cr>',                        opts(noremap, silent)},
  {'<Leader>gcb', ':Git blame<cr>',                  opts(noremap, silent)},
  {'<Leader>gd',  ':Gdiff<cr>',                      opts(noremap, silent)},
  {'<Leader>gp',  ':Git push<cr>',                   opts(noremap, silent)},
  {'<Leader>gl',  ':Git pull<cr>',                   opts(noremap, silent)},
  {'<Leader>gf',  ':Git fetch<cr>',                  opts(noremap, silent)},
  {'<Leader>gcc', ':Git commit --verbose<cr>',       opts(noremap, silent)},
  {'<Leader>gca', ':Git commit --all --verbose<cr>', opts(noremap, silent)},
  {'<Leader>gdl', ':diffget LOCAL<cr>',              opts(noremap, silent)},
  {'<Leader>gdr', ':diffget REMOTE<cr>',             opts(noremap, silent)},

  -- Easy Align
  {'ga', '<Plug>(EasyAlign)', opts(noremap, silent)},

  -- Leap
  {'s', '<Plug>(leap-forward-to)', opts(silent)},
  {'S', '<Plug>(leap-backward-to)', opts(silent)}
})

-- Easy Align
vmap({'ga', [[<Plug>(EasyAlign)]], opts(silent)})
