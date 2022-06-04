local M = {}

local function lsp_highlight_document(client)
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_create_augroup("lsp_document_highlight")
    vim.api.nvim_create_autocmd("CursorHold", {
      group = "lsp_document_highlight",
      pattern = "<buffer>",
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = "lsp_document_highlight",
      pattern = "<buffer>",
      callback = vim.lsp.buf.clear_references,
    })
  end
end

M.on_attach = function(client, bufnr)
  local no_formatting_clients = {
    tsserver = true,
    jsonls = true,
    html = true,
    sumneko_lua = true
  }

  if no_formatting_clients[client.name] ~= nil then
    client.resolved_capabilities.document_formatting = false
  end

  -- Autoformatting
  if client.resolved_capabilities.document_formatting then
    vim.api.nvim_create_augroup("lsp_formatting")
    vim.api.nvim_create_autocmd("BufWritePre", {
      desc = "Auto format before save",
      pattern = "<buffer>",
      callback = vim.lsp.buf.formatting_sync,
    })
  end

  -- Key Mappings
  local keymaps = require('keymaps')
  keymaps.bind_buf_keymaps(bufnr, keymaps['lsp'])

  -- Format Command and highlighting
  vim.api.nvim_create_user_command("Format", vim.lsp.buf.formatting, { desc = "Format file with LSP" })
  lsp_highlight_document(client)
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  }
}
M.capabilities = require('cmp_nvim_lsp').update_capabilities(M.capabilities)

return M
