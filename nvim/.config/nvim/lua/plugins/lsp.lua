local configs = {}

function configs.nvim_lspconfig()
  local mason = require('mason')
  local mason_lsp = require('mason-lspconfig')

  mason.setup{}
  mason_lsp.setup{}

  require('mason-lspconfig').setup_handlers {
    function (server_name)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      require('lspconfig')[server_name].setup{
        capabilities = capabilities
      }
    end,
  }
end

return configs
