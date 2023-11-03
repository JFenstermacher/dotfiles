return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-telescope/telescope-fzy-native.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
  },
  config = function(_, opts)
    local telescope = require("telescope")

    local extensions = {
      "fzy_native",
      "file_browser",
    }

    for _, ext in ipairs(extensions) do
      telescope.load_extension(ext)
    end
  end,
}
