-- :fennel:1670104495
local _local_1_ = require("core.common")
local cmdstr = _local_1_["cmdstr"]
local data_path = _local_1_["data-path"]
do
  if (0 == vim.fn.isdirectory("/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/packer.nvim")) then
    print("packer.nvim: installing in data dir...")
    local function _2_(...)
      _G["packer_bootstrap"] = true
      return nil
    end
    do local _ = (vim.fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/packer.nvim"}) and _2_(...)) end
    vim.cmd("redraw")
    vim.cmd("packadd packer.nvim")
    print("packer.nvim: installed")
  else
  end
  do end (require("packer")).init({git = {clone_timeout = 120}, display = {open_fn = (require("packer.util")).float, working_sym = "\239\176\173", error_sym = "\239\153\150", done_sym = "\239\152\177", removed_sym = "\239\161\180", moved_sym = "\239\176\179"}})
end
local function _4_(use)
  _G.assert((nil ~= use), "Missing argument use on core/pack.fnl:16")
  use("wbthomason/packer.nvim")
  do
    use({"udayvir-singh/tangerine.nvim"})
    use({requires = {"udayvir-singh/tangerine.nvim"}, "udayvir-singh/hibiscus.nvim"})
    local function _5_()
      vim.cmd("colorscheme gruvbox-material")
      return true
    end
    use({config = _5_, "sainnhe/gruvbox-material"})
    use({"p00f/nvim-ts-rainbow"})
    local function _6_()
      return require("plugins/lualine")
    end
    use({config = _6_, "nvim-lualine/lualine.nvim"})
    local function _7_()
      local mod_1_auto = require("mason")
      return mod_1_auto.setup((nil or {}))
    end
    use({as = "mason", config = _7_, "williamboman/mason.nvim"})
    local function _8_()
      local mod_1_auto = require("mason-lspconfig")
      return mod_1_auto.setup((nil or {}))
    end
    use({after = "mason", as = "mason-lspconfig", config = _8_, "williamboman/mason-lspconfig.nvim"})
    local function _9_()
      return require("plugins/nvim-lspconfig")
    end
    use({after = "mason-lspconfig", config = _9_, requires = {"hrsh7th/cmp-nvim-lsp"}, "neovim/nvim-lspconfig"})
    local function _10_()
      return require("plugins/leap")
    end
    use({as = "leap", config = _10_, "ggandor/leap.nvim"})
    local function _11_()
      local mod_1_auto = require("flit")
      return mod_1_auto.setup((nil or {}))
    end
    use({config = _11_, requires = "leap", "ggandor/flit.nvim"})
    use({"junegunn/vim-easy-align"})
    use({"alexghergh/nvim-tmux-navigation"})
    local function _12_()
      return require("plugins/telescope")
    end
    use({config = _12_, requires = {"nvim-lua/popup.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzy-native.nvim", "nvim-telescope/telescope-file-browser.nvim"}, "nvim-telescope/telescope.nvim"})
    local function _13_()
      return require("plugins/treesitter")
    end
    use({config = _13_, run = "TSUpdate", "nvim-treesitter/nvim-treesitter"})
    local function _14_()
      local mod_1_auto = require("Comment")
      return mod_1_auto.setup((nil or {}))
    end
    use({config = _14_, event = "BufEnter", "numToStr/Comment.nvim"})
    local function _15_()
      return require("plugins/nvim-autopairs")
    end
    use({config = _15_, "windwp/nvim-autopairs"})
    use({event = "InsertCharPre", "L3MON4D3/LuaSnip"})
    local function _16_()
      return require("plugins/nvim-cmp")
    end
    use({after = "nvim-lspconfig", config = _16_, requires = {"saadparwaiz1/cmp_luasnip", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline"}, "hrsh7th/nvim-cmp"})
    use({ft = {"clojure", "fennel"}, run = "cargo build --release", "eraserhd/parinfer-rust"})
    use({"tpope/vim-surround"})
  end
  if (true == _G.packer_bootstrap) then
    return (require("packer")).sync()
  else
    return nil
  end
end
do end (require("packer")).startup(_4_)
vim.keymap.set({"n"}, "<leader>pu", cmdstr("PackerUpdate"), {silent = true})
vim.keymap.set({"n"}, "<leader>pi", cmdstr("PackerInstall"), {silent = true})
vim.keymap.set({"n"}, "<leader>pc", cmdstr("PackerCompile"), {silent = true})
return vim.keymap.set({"n"}, "<leader>ps", cmdstr("PackerSync"), {silent = true})