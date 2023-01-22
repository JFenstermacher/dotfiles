-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jk", "<esc>")

-- Window binds
vim.keymap.set("n", "<leader>wv", "<c-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>ws", "<c-w>s", { desc = "Split window horizontally" })
