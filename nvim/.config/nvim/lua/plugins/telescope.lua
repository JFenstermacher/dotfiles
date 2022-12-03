-- :fennel:1669955726
local _local_1_ = require("core.common")
local cmdstr = _local_1_["cmdstr"]
do
  local ok_3f, _let_2_ = pcall(require, "telescope")
  local _let_3_ = _let_2_
  local setup = _let_3_["setup"]
  local load_extension = _let_3_["load_extension"]
  if ok_3f then
    local actions = require("telescope.actions")
    local sorters = require("telescope.sorters")
    local previewers = require("telescope.previewers")
    local fb_actions = (require("telescope")).extensions.file_browser.actions
    setup({defaults = {file_sorter = sorters.get_fzy_sorter, file_previewer = previewers.vim_buffer_cat.new, grep_previewer = previewers.vim_buffer_vimgrep.new, qflist_previewer = previewers.vim_buffer_qflist.new, color_devicons = true}, pickers = {find_files = {find_command = {"fd", "--type", "f", "--hidden", "--exclude", ".git"}}}, extensions = {file_browser = {hide_parent_dir = true, theme = "ivy", mappings = {n = {["-"] = fb_actions.goto_parent_dir}}, respect_gitignore = false}}, fzy_native = {override_file_sorter = true, override_generic_sorter = false}})
    load_extension("fzy_native")
    load_extension("file_browser")
  else
  end
end
vim.keymap.set({"n"}, "<leader>fb", cmdstr("Telescope buffers"), {silent = true})
vim.keymap.set({"n"}, "<leader>fw", cmdstr("Telescope live_grep"), {silent = true})
vim.keymap.set({"n"}, "<leader>pf", cmdstr("Telescope find_files"), {silent = true})
vim.keymap.set({"n"}, "<leader>fq", cmdstr("Telescope quickfix"), {silent = true})
return vim.keymap.set({"n"}, "-", cmdstr("Telescope file_browser path=%:p:h"), {silent = true})