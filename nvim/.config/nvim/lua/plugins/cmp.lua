local cmp = require 'cmp'

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local tab_complete = function(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  elseif vim.fn["vsnip#available"](1) == 1 then
    feedkey("<Plug>(vsnip-expand-or-jump)", "")
  elseif has_words_before() then
    cmp.complete()
  else
    fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
  end
end

local shift_tab_complete = function()
  if cmp.visible() then
    cmp.select_prev_item()
  elseif vim.fn["vsnip#jumpable"](-1) == 1 then
    feedkey("<Plug>(vsnip-jump-prev)", "")
  end
end

cmp.setup({
  mapping = {
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close()
    }),
    ['<CR>'] = cmp.mapping(cmp.mapping.confirm({ select = true })),
    ["<Tab>"] = cmp.mapping(tab_complete, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(shift_tab_complete, { "i", "s" })
  },
  sources = cmp.config.sources({{ name = 'nvim_lsp' }}, {{ name = 'buffer' }})
})

cmp.setup.cmdline('/', {
  sources = {{ name = 'buffer' }}
})

cmp.setup.cmdline(':', {
  sources = cmp.config.sources({{ name = 'path' }}, {{ name = 'cmdline' }})
})

local autopairs = require 'nvim-autopairs'
local cmp_autopairs = require 'nvim-autopairs.completion.cmp'

autopairs.setup{}

cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = '' }}))
