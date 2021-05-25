local M = {}

function M.config()
  local telescope = require('telescope')
  local sorters = require('telescope.sorters')
  local previewers = require('telescope.previewers')

  telescope.setup {
    defaults = {
      file_sorter = sorters.get_fzy_sorter,
      color_devicons = true,

      file_previewer   = previewers.vim_buffer_cat.new,
      grep_previewer   = previewers.vim_buffer_vimgrep.new,
      qflist_previewer = previewers.vim_buffer_qflist.new,
    },
    extensions = {
      fzy_native = {
        override_generic_sorter = false,
        override_file_sorter = true,
      }
    }
  }

  telescope.load_extension('fzy_native')
end

function M.setup()
  local bind = require('configs.utils').bind_maps

  local silent = { silent = true }
  local mappings = {
    {'n', '<leader>pf', '<cmd>Telescope find_files<cr>', silent},
    {'n', '<leader>bf', '<cmd>Telescope buffers show_all_buffers=true sort_lastused=true<cr>', silent},
    {'n', '<leader>gf', '<cmd>Telescope git_files<cr>', silent},
    {'n', '<leader>pg', '<cmd>Telescope live_grep<cr>', silent}
  }

  bind(mappings)
end

return M
