require 'compe'.setup{
  enabled = true,
  autocomplete = true,
  debug = false,
  min_length = 1,
  preselect = 'enable',
  throttle_time = 80,
  source_timeout = 200,
  incomplete_delay = 400,
  max_abbr_width = 100,
  max_kind_width = 100,
  max_menu_width = 100,
  documentation = false,

  source = {
    path = true,
    buffer = true,
    calc = true,
    -- vsnip = true,
    nvim_lsp = true,
    nvim_lua = true,
    spell = true,
    tags = true,
    -- snippets_nvim = true,
    treesitter = true
  }
}


require 'nvim-autopairs'.setup{}

require 'nvim-autopairs.completion.compe'.setup{
  map_cr = true,
  map_complete = true,
  auto_select = true
}

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return vim.fn['compe#complete']()
  end
end

_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  else
    return t "<S-Tab>"
  end
end

local bind = require 'keymaps'.bind_keymaps
local expr = { expr = true }

bind{
 {'i', '<cr>', [[compe#confirm({ 'keys': '<cr>', 'select': v:true })]], expr},
 {'i', '<c-space>', 'compe#complete()', expr},
 {'is', '<tab>', 'v:lua.tab_complete()', expr},
 {'is', '<s-tab>', 'v:lua.s_tab_complete()', expr}
}
