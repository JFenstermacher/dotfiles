-- Set space as the leader key (must be defined before plugins load)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Sourcing repositories directly via string arguments
vim.pack.add({ "https://github.com/folke/zen-mode.nvim" })
vim.pack.add({ "https://github.com/folke/twilight.nvim" })
vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" })

require("zen-mode").setup({
	window = {
		width = 85, -- Clean line width for reading/writing prose
		options = {
			number = false,
			relativenumber = false,
			signcolumn = "no",
		},
	},
	plugins = {
		twilight = { enabled = true }, -- Dims non-active text paragraphs
	},
})

-- Initialize the colorscheme
vim.cmd("colorscheme kanagawa-dragon")

-- Quick escape to normal mode using jk
vim.keymap.set("i", "jk", "<Esc>", { silent = true, desc = "Exit insert mode" })

-- Toggle writing focus (Space + z)
vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<cr>", { silent = true, desc = "Toggle Zen Mode" })

-- Visual line movements for long wrapped sentences
vim.keymap.set("n", "j", "gj", { silent = true })
vim.keymap.set("n", "k", "gk", { silent = true })

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Clean UI (Distraction-free)
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.cursorline = false
vim.opt.smartindent = false

-- Tabs as spaces (Prose standard)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Native Spellcheck & Scrolling
vim.opt.spell = true
vim.opt.spelllang = "en_us"
vim.opt.scrolloff = 8
