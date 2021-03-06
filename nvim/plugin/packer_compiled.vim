" Automatically generated packer.nvim plugin loader code

if !has('nvim-0.5')
  echohl WarningMsg
  echom "Invalid Neovim version for packer.nvim!"
  echohl None
  finish
endif

packadd packer.nvim

try

lua << END
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

  _G._packer = _G._packer or {}
  _G._packer.profile_output = results
end

time("Luarocks path setup", true)
local package_path_str = "/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/home/jfenstermacher/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time("Luarocks path setup", false)
time("try_loadstring definition", true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s))
  if not success then
    print('Error running ' .. component .. ' for ' .. name)
    error(result)
  end
  return result
end

time("try_loadstring definition", false)
time("Defining packer_plugins", true)
_G.packer_plugins = {
  ["gruvbox-material"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/gruvbox-material"
  },
  ["lspkind-nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/lspkind-nvim"
  },
  ["lspsaga.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/lspsaga.nvim"
  },
  ["nvim-compe"] = {
    config = { "\27LJ\2\n?\1\0\0\4\0\6\0\t6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\3\0005\3\4\0=\3\5\2B\0\2\1K\0\1\0\vsource\1\0\t\ttags\2\tpath\2\nspell\2\vbuffer\2\18snippets_nvim\1\rnvim_lua\2\rnvim_lsp\2\nvsnip\2\tcalc\2\1\0\5\14preselect\valways\fenabled\2\ndebug\1\15min_length\3\1\25allow_prefix_unmatch\1\nsetup\ncompe\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/nvim-compe"
  },
  ["nvim-lspconfig"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/nvim-lspconfig"
  },
  ["nvim-lspinstall"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/nvim-lspinstall"
  },
  ["packer.nvim"] = {
    loaded = false,
    needs_bufread = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/plenary.nvim"
  },
  ["popup.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/popup.nvim"
  },
  ["telescope-fzy-native.nvim"] = {
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/telescope-fzy-native.nvim"
  },
  ["telescope.nvim"] = {
    config = { "\27LJ\2\n?\3\0\0\b\0\22\0!6\0\0\0'\2\1\0B\0\2\0026\1\0\0'\3\2\0B\1\2\0026\2\0\0'\4\3\0B\2\2\0029\3\4\0005\5\15\0005\6\6\0009\a\5\1=\a\a\0069\a\b\0029\a\t\a=\a\n\0069\a\v\0029\a\t\a=\a\f\0069\a\r\0029\a\t\a=\a\14\6=\6\16\0055\6\18\0005\a\17\0=\a\19\6=\6\20\5B\3\2\0019\3\21\0'\5\19\0B\3\2\1K\0\1\0\19load_extension\15extensions\15fzy_native\1\0\0\1\0\2\25override_file_sorter\2\28override_generic_sorter\1\rdefaults\1\0\0\21qflist_previewer\22vim_buffer_qflist\19grep_previewer\23vim_buffer_vimgrep\19file_previewer\bnew\19vim_buffer_cat\16file_sorter\1\0\1\19color_devicons\2\19get_fzy_sorter\nsetup\25telescope.previewers\22telescope.sorters\14telescope\frequire\0" },
    loaded = false,
    needs_bufread = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/telescope.nvim"
  },
  undotree = {
    commands = { "UndotreeToggle" },
    config = { "vim.g.undotree_SetFocusWhenToggle = 1" },
    loaded = false,
    needs_bufread = false,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/opt/undotree"
  },
  ["vim-easy-align"] = {
    config = { "\27LJ\2\n~\0\0\a\0\a\0\v6\0\0\0'\2\1\0B\0\2\0029\0\2\0\18\1\0\0005\3\3\0'\4\4\0'\5\5\0005\6\6\0B\1\5\1K\0\1\0\1\0\2\fnoremap\1\vsilent\2\22<Plug>(EasyAlign)\aga\1\3\0\0\6x\6n\bmap\18configs.utils\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/vim-easy-align"
  },
  ["vim-floaterm"] = {
    config = { "\27LJ\2\n?\3\0\0\6\0\f\0\"6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\1\3\0004\2\t\0005\3\4\0>\1\4\3>\3\1\0025\3\5\0>\1\4\3>\3\2\0025\3\6\0>\1\4\3>\3\3\0025\3\a\0>\1\4\3>\3\4\0025\3\b\0>\1\4\3>\3\5\0025\3\t\0>\1\4\3>\3\6\0025\3\n\0>\1\4\3>\3\a\0025\3\v\0>\1\4\3>\3\b\2\18\3\0\0\18\5\2\0B\3\2\1K\0\1\0\1\4\0\0\6t\n<F12>\"<C-\\><C-n>:FloatermToggle<cr>\1\4\0\0\6n\n<F12>\24:FloatermToggle<cr>\1\4\0\0\6t\t<F9> <C-\\><C-n>:FloatermNext<cr>\1\4\0\0\6n\t<F9>\22:FloatermNext<cr>\1\4\0\0\6t\t<F8> <C-\\><C-n>:FloatermPrev<cr>\1\4\0\0\6n\t<F8>\22:FloatermPrev<cr>\1\4\0\0\6t\t<F7>\31<C-\\><C-n>:FloatermNew<cr>\1\4\0\0\6n\t<F7>\21:FloatermNew<cr>\1\0\1\vsilent\2\14bind_maps\18configs.utils\frequire\0" },
    loaded = true,
    path = "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/vim-floaterm"
  }
}

time("Defining packer_plugins", false)
-- Setup for: telescope.nvim
time("Setup for telescope.nvim", true)
try_loadstring("\27LJ\2\n?\2\0\0\6\0\b\0\0226\0\0\0'\2\1\0B\0\2\0029\0\2\0005\1\3\0004\2\5\0005\3\4\0>\1\4\3>\3\1\0025\3\5\0>\1\4\3>\3\2\0025\3\6\0>\1\4\3>\3\3\0025\3\a\0>\1\4\3>\3\4\2\18\3\0\0\18\5\2\0B\3\2\1K\0\1\0\1\4\0\0\6n\15<leader>pg!<cmd>Telescope live_grep<cr>\1\4\0\0\6n\15<leader>gf!<cmd>Telescope git_files<cr>\1\4\0\0\6n\15<leader>bfH<cmd>Telescope buffers show_all_buffers=true sort_lastused=true<cr>\1\4\0\0\6n\15<leader>pf\"<cmd>Telescope find_files<cr>\1\0\1\vsilent\2\14bind_maps\18configs.utils\frequire\0", "setup", "telescope.nvim")
time("Setup for telescope.nvim", false)
time("packadd for telescope.nvim", true)
vim.cmd [[packadd telescope.nvim]]
time("packadd for telescope.nvim", false)
-- Config for: vim-easy-align
time("Config for vim-easy-align", true)
try_loadstring("\27LJ\2\n~\0\0\a\0\a\0\v6\0\0\0'\2\1\0B\0\2\0029\0\2\0\18\1\0\0005\3\3\0'\4\4\0'\5\5\0005\6\6\0B\1\5\1K\0\1\0\1\0\2\fnoremap\1\vsilent\2\22<Plug>(EasyAlign)\aga\1\3\0\0\6x\6n\bmap\18configs.utils\frequire\0", "config", "vim-easy-align")
time("Config for vim-easy-align", false)
-- Config for: nvim-compe
time("Config for nvim-compe", true)
try_loadstring("\27LJ\2\n?\1\0\0\4\0\6\0\t6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\3\0005\3\4\0=\3\5\2B\0\2\1K\0\1\0\vsource\1\0\t\ttags\2\tpath\2\nspell\2\vbuffer\2\18snippets_nvim\1\rnvim_lua\2\rnvim_lsp\2\nvsnip\2\tcalc\2\1\0\5\14preselect\valways\fenabled\2\ndebug\1\15min_length\3\1\25allow_prefix_unmatch\1\nsetup\ncompe\frequire\0", "config", "nvim-compe")
time("Config for nvim-compe", false)
-- Config for: telescope.nvim
time("Config for telescope.nvim", true)
try_loadstring("\27LJ\2\n?\3\0\0\b\0\22\0!6\0\0\0'\2\1\0B\0\2\0026\1\0\0'\3\2\0B\1\2\0026\2\0\0'\4\3\0B\2\2\0029\3\4\0005\5\15\0005\6\6\0009\a\5\1=\a\a\0069\a\b\0029\a\t\a=\a\n\0069\a\v\0029\a\t\a=\a\f\0069\a\r\0029\a\t\a=\a\14\6=\6\16\0055\6\18\0005\a\17\0=\a\19\6=\6\20\5B\3\2\0019\3\21\0'\5\19\0B\3\2\1K\0\1\0\19load_extension\15extensions\15fzy_native\1\0\0\1\0\2\25override_file_sorter\2\28override_generic_sorter\1\rdefaults\1\0\0\21qflist_previewer\22vim_buffer_qflist\19grep_previewer\23vim_buffer_vimgrep\19file_previewer\bnew\19vim_buffer_cat\16file_sorter\1\0\1\19color_devicons\2\19get_fzy_sorter\nsetup\25telescope.previewers\22telescope.sorters\14telescope\frequire\0", "config", "telescope.nvim")
time("Config for telescope.nvim", false)
-- Config for: vim-floaterm
time("Config for vim-floaterm", true)
try_loadstring("\27LJ\2\n?\3\0\0\6\0\f\0\"6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\1\3\0004\2\t\0005\3\4\0>\1\4\3>\3\1\0025\3\5\0>\1\4\3>\3\2\0025\3\6\0>\1\4\3>\3\3\0025\3\a\0>\1\4\3>\3\4\0025\3\b\0>\1\4\3>\3\5\0025\3\t\0>\1\4\3>\3\6\0025\3\n\0>\1\4\3>\3\a\0025\3\v\0>\1\4\3>\3\b\2\18\3\0\0\18\5\2\0B\3\2\1K\0\1\0\1\4\0\0\6t\n<F12>\"<C-\\><C-n>:FloatermToggle<cr>\1\4\0\0\6n\n<F12>\24:FloatermToggle<cr>\1\4\0\0\6t\t<F9> <C-\\><C-n>:FloatermNext<cr>\1\4\0\0\6n\t<F9>\22:FloatermNext<cr>\1\4\0\0\6t\t<F8> <C-\\><C-n>:FloatermPrev<cr>\1\4\0\0\6n\t<F8>\22:FloatermPrev<cr>\1\4\0\0\6t\t<F7>\31<C-\\><C-n>:FloatermNew<cr>\1\4\0\0\6n\t<F7>\21:FloatermNew<cr>\1\0\1\vsilent\2\14bind_maps\18configs.utils\frequire\0", "config", "vim-floaterm")
time("Config for vim-floaterm", false)

-- Command lazy-loads
time("Defining lazy-load commands", true)
vim.cmd [[command! -nargs=* -range -bang -complete=file UndotreeToggle lua require("packer.load")({'undotree'}, { cmd = "UndotreeToggle", l1 = <line1>, l2 = <line2>, bang = <q-bang>, args = <q-args> }, _G.packer_plugins)]]
time("Defining lazy-load commands", false)

if should_profile then save_profiles() end

END

catch
  echohl ErrorMsg
  echom "Error in packer_compiled: " .. v:exception
  echom "Please check your config for correctness"
  echohl None
endtry
