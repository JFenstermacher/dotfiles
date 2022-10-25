local configs = {}

function configs.nvim_autopairs()
  require('nvim-autopairs').setup{}
end

function configs.nvim_cmp()
  local cmp = require('cmp')
  local cmp_autopairs = require('nvim-autopairs.completion.cmp')

  cmp.setup{
    preselect = cmp.PreselectMode.Item,
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered()
    },
    sources = cmp.config.sources(
      {
        { name = 'nvim_lsp' },
        { name = 'luasnip' }
      },
      {
        { name = 'buffer' }
      }
    ),
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true })
    })
  }

  cmp.setup.cmdline('/', {
    sources = {{ name = 'buffer' }}
  })

  cmp.setup.cmdline(':', {
    sources = cmp.config.sources(
      {{ name = 'path' }},
      {{ name = 'cmdline' }}
    )
  })

  cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
end

return configs
