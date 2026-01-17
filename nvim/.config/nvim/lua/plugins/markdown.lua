return {
  {
    "rickhowe/wrapwidth",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- The plugin defines :WrapWidth command. 
      -- We'll trigger it via autocmd for markdown files.
    end,
  },
}
