-- :fennel:1669829859
do
  if (0 == vim.fn.isdirectory("/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/packer.nvim")) then
    print("packer.nvim: installing in data dir...")
    local function _1_(...)
      _G["packer_bootstrap"] = true
      return nil
    end
    do local _ = (vim.fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", "/home/jfenstermacher/.local/share/nvim/site/pack/packer/start/packer.nvim"}) and _1_(...)) end
    vim.cmd("redraw")
    vim.cmd("packadd packer.nvim")
    print("packer.nvim: installed")
  else
  end
  do end (require("packer")).init({})
end
local function _3_(use)
  _G.assert((nil ~= use), "Missing argument use on core/pack.fnl:5")
  use("wbthomason/packer.nvim")
  do
    use({"udayvir-singh/tangerine.nvim"})
    use({requires = {"udayvir-singh/tangerine.nvim"}, "udayvir-singh/hibiscus.nvim"})
    use({"alexghergh/nvim-tmux-navigation"})
    local function _4_()
      return require("plugins/gruvbox-material")
    end
    use({config = _4_, "sainnhe/gruvbox-material"})
    local function _5_()
      return require("plugins/telescope")
    end
    use({config = _5_, requires = {"nvim-lua/popup.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzy-native.nvim", "nvim-telescope/telescope-file-browser.nvim"}, "nvim-telescope/telescope.nvim"})
  end
  if (true == _G.packer_bootstrap) then
    return (require("packer")).sync()
  else
    return nil
  end
end
return (require("packer")).startup(_3_)