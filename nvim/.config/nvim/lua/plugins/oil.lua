return {
  "stevearc/oil.nvim",
  opts = {
    view_options = {
      show_hidden = true,
    },
    keymaps = {
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<C-r>"] = "actions.refresh",
    },
  },
  keys = {
    { "-", "<CMD>Oil<CR>", mode = "n" },
  },
}
