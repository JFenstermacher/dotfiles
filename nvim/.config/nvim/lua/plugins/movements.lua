local configs = {}

function configs.leap()
  require('leap').setup{}
end

function configs.flit()
  require('flit').setup{}
end

function configs.nvim_surround()
  require('nvim-surround').setup{}
end

return configs
