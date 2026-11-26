-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.maplocalleader = ","
vim.g.autoformat = false

vim.opt.swapfile = false
vim.opt.autoread = true

-- Better native diff views (gitsigns diffthis, vimdiff, merge conflicts)
vim.opt.diffopt = {
  "internal",
  "filler",
  "closeoff",
  "vertical",
  "linematch:60",
  "algorithm:histogram",
  "indent-heuristic",
}

-- Keep cursor centered vertically when scanning diffs/search hits
vim.opt.scrolloff = 8

vim.filetype.add({
  pattern = {
    ["*.tf"] = "hcl",
  },
})
