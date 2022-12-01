-- :fennel:1669871450
local _local_1_ = require("core.common")
local cmdstr = _local_1_["cmdstr"]
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
  do end (require("packer")).init({})
end
local function _4_(use)
  _G.assert((nil ~= use), "Missing argument use on core/pack.fnl:7")
  use("wbthomason/packer.nvim")
  do
    use({"udayvir-singh/tangerine.nvim"})
    use({requires = {"udayvir-singh/tangerine.nvim"}, "udayvir-singh/hibiscus.nvim"})
    use({"alexghergh/nvim-tmux-navigation"})
    local function _5_()
      return require("plugins/gruvbox-material")
    end
    use({config = _5_, "sainnhe/gruvbox-material"})
    local function _6_()
      return require("plugins/telescope")
    end
    use({config = _6_, requires = {"nvim-lua/popup.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzy-native.nvim", "nvim-telescope/telescope-file-browser.nvim"}, "nvim-telescope/telescope.nvim"})
    local function _7_()
      return require("plugins/treesitter")
    end
    use({config = _7_, run = "TSUpdate", "nvim-treesitter/nvim-treesitter"})
    local function _8_()
      return require("plugins/comment")
    end
    use({config = _8_, event = "BufEnter", "numToStr/Comment.nvim"})
    local function _9_()
      return require("plugins/nvim-autopairs")
    end
    use({config = _9_, "windwp/nvim-autopairs"})
    use({"junegunn/vim-easy-align"})
    local function _10_()
      return require("plugins/leap")
    end
    use({as = "leap", config = _10_, "ggandor/leap.nvim"})
    local function _11_()
      return require("plugins/flit")
    end
    use({config = _11_, requires = "leap", "ggandor/flit.nvim"})
    local function _12_()
      return require("plugins/mason")
    end
    use({as = "mason", config = _12_, "williamboman/mason.nvim"})
    local function _13_()
      return require("plugins/mason-lspconfig")
    end
    use({after = "mason", as = "mason-lspconfig", config = _13_, "williamboman/mason-lspconfig.nvim"})
    local function _14_()
      return require("plugins/nvim-lspconfig")
    end
    use({after = "mason-lspconfig", config = _14_, "neovim/nvim-lspconfig"})
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
return vim.keymap.set({"n"}, "<leader>pc", cmdstr("PackerCompile"), {silent = true})