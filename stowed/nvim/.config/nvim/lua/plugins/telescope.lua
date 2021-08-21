local telescope = require 'telescope'
local actions = require 'telescope.actions'
local sorters = require 'telescope.sorters'
local previewers = require 'telescope.previewers'

telescope.setup {
  defaults = {
    file_sorter = sorters.get_fzy_sorter,
    color_devicons = true,
    file_previewer   = previewers.vim_buffer_cat.new,
    grep_previewer   = previewers.vim_buffer_vimgrep.new,
    qflist_previewer = previewers.vim_buffer_qflist.new,

    mappings = {
      i = {
        ['<C-q>'] = actions.send_to_qflist
      }
    }
  },
  pickers = {
    buffers = {
      sort_lastused = true,
      theme = 'dropdown',
      previewer = false,
      mappings = {
        i = { ['<c-d>'] = require('telescope.actions').delete_buffer },
        n = { ['<c-d>'] = require('telescope.actions').delete_buffer }
      }
    }
  },
  extensions = {
    fzy_native = {
      override_generic_sorter = false,
      override_file_sorter = true,
    }
  }
}

telescope.load_extension('fzy_native')

local bind = require 'keymaps'.bind_keymaps
local silent = { silent = true }

bind{
  {'n', '<leader>pf', '<cmd>Telescope find_files<cr>', silent},
  {'n', '<leader>bf', '<cmd>Telescope buffers<cr>'},
  {'n', '<C-p>',      '<cmd>Telescope git_files<cr>',  silent},
  {'n', '<leader>pg', '<cmd>Telescope live_grep<cr>',  silent}
}

