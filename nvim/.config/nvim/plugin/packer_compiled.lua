-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

_G._packer = _G._packer or {}
_G._packer.inside_compile = true

local time
local profile_info
local should_profile = false
if should_profile then
  local hrtime = vim.loop.hrtime
  profile_info = {}
  time = function(chunk, start)
    if start then
      profile_info[chunk] = hrtime()
    else
      profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
    end
  end
else
  time = function(chunk, start) end
end

local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end
  if threshold then
    table.insert(results, '(Only showing plugins that took longer than ' .. threshold .. ' ms ' .. 'to load)')
  end

  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s), name, _G.packer_plugins[name])
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  ["Comment.nvim"] = {
    config = { "\27LJ\2\n+\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\20plugins/comment\frequire\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/Comment.nvim",
    url = "https://github.com/numToStr/Comment.nvim"
  },
  LuaSnip = {
    loaded = false,
    needs_bufread = true,
    only_cond = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/LuaSnip",
    url = "https://github.com/L3MON4D3/LuaSnip"
  },
  ["cmp-buffer"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/cmp-buffer",
    url = "https://github.com/hrsh7th/cmp-buffer"
  },
  ["cmp-cmdline"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/cmp-cmdline",
    url = "https://github.com/hrsh7th/cmp-cmdline"
  },
  ["cmp-nvim-lsp"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/cmp-nvim-lsp",
    url = "https://github.com/hrsh7th/cmp-nvim-lsp"
  },
  ["cmp-path"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/cmp-path",
    url = "https://github.com/hrsh7th/cmp-path"
  },
  cmp_luasnip = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/cmp_luasnip",
    url = "https://github.com/saadparwaiz1/cmp_luasnip"
  },
  conjure = {
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/conjure",
    url = "https://github.com/olical/conjure"
  },
  ["flit.nvim"] = {
    config = { "\27LJ\2\n(\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\17plugins/flit\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/flit.nvim",
    url = "https://github.com/ggandor/flit.nvim"
  },
  ["gruvbox-material"] = {
    config = { "\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29plugins/gruvbox-material\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/gruvbox-material",
    url = "https://github.com/sainnhe/gruvbox-material"
  },
  ["hibiscus.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/hibiscus.nvim",
    url = "https://github.com/udayvir-singh/hibiscus.nvim"
  },
  leap = {
    config = { "\27LJ\2\n(\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\17plugins/leap\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/leap",
    url = "https://github.com/ggandor/leap.nvim"
  },
  ["lualine.nvim"] = {
    config = { "\27LJ\2\n+\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\20plugins/lualine\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/lualine.nvim",
    url = "https://github.com/nvim-lualine/lualine.nvim"
  },
  mason = {
    after = { "mason-lspconfig" },
    config = { "\27LJ\2\n)\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\18plugins/mason\frequire\0" },
    loaded = true,
    only_config = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/mason",
    url = "https://github.com/williamboman/mason.nvim"
  },
  ["mason-lspconfig"] = {
    after = { "nvim-lspconfig" },
    config = { "\27LJ\2\n3\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\28plugins/mason-lspconfig\frequire\0" },
    load_after = {},
    loaded = true,
    needs_bufread = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/mason-lspconfig",
    url = "https://github.com/williamboman/mason-lspconfig.nvim"
  },
  ["nvim-autopairs"] = {
    config = { "\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27plugins/nvim-autopairs\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/nvim-autopairs",
    url = "https://github.com/windwp/nvim-autopairs"
  },
  ["nvim-cmp"] = {
    config = { "\27LJ\2\n,\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\21plugins/nvim-cmp\frequire\0" },
    load_after = {},
    loaded = true,
    needs_bufread = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/nvim-cmp",
    url = "https://github.com/hrsh7th/nvim-cmp"
  },
  ["nvim-lspconfig"] = {
    after = { "nvim-cmp" },
    config = { "\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27plugins/nvim-lspconfig\frequire\0" },
    load_after = {},
    loaded = true,
    needs_bufread = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/nvim-lspconfig",
    url = "https://github.com/neovim/nvim-lspconfig"
  },
  ["nvim-tmux-navigation"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/nvim-tmux-navigation",
    url = "https://github.com/alexghergh/nvim-tmux-navigation"
  },
  ["nvim-treesitter"] = {
    config = { "\27LJ\2\n.\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\23plugins/treesitter\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter"
  },
  ["nvim-ts-rainbow"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/nvim-ts-rainbow",
    url = "https://github.com/p00f/nvim-ts-rainbow"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/packer.nvim",
    url = "https://github.com/wbthomason/packer.nvim"
  },
  ["parinfer-rust"] = {
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/parinfer-rust",
    url = "https://github.com/eraserhd/parinfer-rust"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/plenary.nvim",
    url = "https://github.com/nvim-lua/plenary.nvim"
  },
  ["popup.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/popup.nvim",
    url = "https://github.com/nvim-lua/popup.nvim"
  },
  ["tangerine.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/tangerine.nvim",
    url = "https://github.com/udayvir-singh/tangerine.nvim"
  },
  ["telescope-file-browser.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/telescope-file-browser.nvim",
    url = "https://github.com/nvim-telescope/telescope-file-browser.nvim"
  },
  ["telescope-fzy-native.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/telescope-fzy-native.nvim",
    url = "https://github.com/nvim-telescope/telescope-fzy-native.nvim"
  },
  ["telescope.nvim"] = {
    config = { "\27LJ\2\n-\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\22plugins/telescope\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/telescope.nvim",
    url = "https://github.com/nvim-telescope/telescope.nvim"
  },
  ["vim-easy-align"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/vim-easy-align",
    url = "https://github.com/junegunn/vim-easy-align"
  },
  ["vim-surround"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/vim-surround",
    url = "https://github.com/tpope/vim-surround"
  }
}

time([[Defining packer_plugins]], false)
-- Config for: mason
time([[Config for mason]], true)
try_loadstring("\27LJ\2\n)\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\18plugins/mason\frequire\0", "config", "mason")
time([[Config for mason]], false)
-- Config for: nvim-treesitter
time([[Config for nvim-treesitter]], true)
try_loadstring("\27LJ\2\n.\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\23plugins/treesitter\frequire\0", "config", "nvim-treesitter")
time([[Config for nvim-treesitter]], false)
-- Config for: gruvbox-material
time([[Config for gruvbox-material]], true)
try_loadstring("\27LJ\2\n4\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\29plugins/gruvbox-material\frequire\0", "config", "gruvbox-material")
time([[Config for gruvbox-material]], false)
-- Config for: flit.nvim
time([[Config for flit.nvim]], true)
try_loadstring("\27LJ\2\n(\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\17plugins/flit\frequire\0", "config", "flit.nvim")
time([[Config for flit.nvim]], false)
-- Config for: leap
time([[Config for leap]], true)
try_loadstring("\27LJ\2\n(\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\17plugins/leap\frequire\0", "config", "leap")
time([[Config for leap]], false)
-- Config for: telescope.nvim
time([[Config for telescope.nvim]], true)
try_loadstring("\27LJ\2\n-\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\22plugins/telescope\frequire\0", "config", "telescope.nvim")
time([[Config for telescope.nvim]], false)
-- Config for: lualine.nvim
time([[Config for lualine.nvim]], true)
try_loadstring("\27LJ\2\n+\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\20plugins/lualine\frequire\0", "config", "lualine.nvim")
time([[Config for lualine.nvim]], false)
-- Config for: nvim-autopairs
time([[Config for nvim-autopairs]], true)
try_loadstring("\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27plugins/nvim-autopairs\frequire\0", "config", "nvim-autopairs")
time([[Config for nvim-autopairs]], false)
-- Load plugins in order defined by `after`
time([[Sequenced loading]], true)
vim.cmd [[ packadd mason-lspconfig ]]

-- Config for: mason-lspconfig
try_loadstring("\27LJ\2\n3\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\28plugins/mason-lspconfig\frequire\0", "config", "mason-lspconfig")

vim.cmd [[ packadd nvim-lspconfig ]]

-- Config for: nvim-lspconfig
try_loadstring("\27LJ\2\n2\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\27plugins/nvim-lspconfig\frequire\0", "config", "nvim-lspconfig")

vim.cmd [[ packadd nvim-cmp ]]

-- Config for: nvim-cmp
try_loadstring("\27LJ\2\n,\0\0\3\0\2\0\0036\0\0\0'\2\1\0D\0\2\0\21plugins/nvim-cmp\frequire\0", "config", "nvim-cmp")

time([[Sequenced loading]], false)
vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time([[Defining lazy-load filetype autocommands]], true)
vim.cmd [[au FileType fennel ++once lua require("packer.load")({'conjure', 'parinfer-rust'}, { ft = "fennel" }, _G.packer_plugins)]]
vim.cmd [[au FileType clojure ++once lua require("packer.load")({'conjure', 'parinfer-rust'}, { ft = "clojure" }, _G.packer_plugins)]]
time([[Defining lazy-load filetype autocommands]], false)
  -- Event lazy-loads
time([[Defining lazy-load event autocommands]], true)
vim.cmd [[au BufEnter * ++once lua require("packer.load")({'Comment.nvim'}, { event = "BufEnter *" }, _G.packer_plugins)]]
vim.cmd [[au InsertCharPre * ++once lua require("packer.load")({'LuaSnip'}, { event = "InsertCharPre *" }, _G.packer_plugins)]]
time([[Defining lazy-load event autocommands]], false)
vim.cmd("augroup END")

_G._packer.inside_compile = false
if _G._packer.needs_bufread == true then
  vim.cmd("doautocmd BufRead")
end
_G._packer.needs_bufread = false

if should_profile then save_profiles() end

end)

if not no_errors then
  error_msg = error_msg:gsub('"', '\\"')
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
