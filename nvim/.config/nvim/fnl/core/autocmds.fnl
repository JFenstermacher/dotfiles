(import-macros {: augroup!} :hibiscus.vim)

(augroup! :highlight-yank
          [[TextYankPost :desc "highlights yanked region."]
           * #(vim.highlight.on_yank {:timeout 80})])
