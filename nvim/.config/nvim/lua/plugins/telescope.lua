-- :fennel:1669830422
do
  local ok_3f, telescope = pcall(require, "telescope")
  local actions = require("telescope.actions")
  if ok_3f then
    telescope.setup({default = {mappings = {i = {["<C-q>"] = actions.send_to_qflist}}}})
    telescope.load_extension("fzf")
  else
  end
end
local _2_
do
  vim.cmd(":Telescope buffers")
  _2_ = true
end
vim.keymap.set({"n"}, "<leader>b", _2_, {silent = true})
local _3_
do
  vim.cmd("Telescope live_grep")
  _3_ = true
end
vim.keymap.set({"n"}, "<leader>fw", _3_, {silent = true})
local _4_
do
  vim.cmd("Telescope find_files")
  _4_ = true
end
vim.keymap.set({"n"}, "<leader>ff", _4_, {silent = true})
local _5_
do
  vim.cmd("Telescope quickfix")
  _5_ = true
end
vim.keymap.set({"n"}, "<leader>fq", _5_, {silent = true})
local _6_
do
  vim.cmd("Telescope file_browser path=%:p:h")
  _6_ = true
end
return vim.keymap.set({"n"}, "-", _6_, {silent = true})