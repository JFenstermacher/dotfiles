-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jk", "<esc>")

-- Window binds
vim.keymap.set("n", "<leader>wv", "<c-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>ws", "<c-w>s", { desc = "Split window horizontally" })

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  vim.keymap.set("n", "<C-" .. key .. ">", function()
    local current = vim.api.nvim_get_current_win()
    if not pcall(vim.cmd.wincmd, key) then
      return
    end
    if vim.api.nvim_get_current_win() == current and vim.env.REX_SESSION and vim.env.REX_BLOCK then
      vim.system({ "rex", "focus", "-s", vim.env.REX_SESSION, direction }, { text = true }, function(result)
        if result.code ~= 0 then
          vim.schedule(function()
            vim.notify("Rex pane navigation failed: " .. result.stderr, vim.log.levels.ERROR)
          end)
        end
      end)
    end
  end, { desc = "Navigate " .. direction .. " window" })
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  vim.keymap.set("n", "<C-" .. key .. ">", function()
    local current = vim.api.nvim_get_current_win()
    if not pcall(vim.cmd.wincmd, key) then
      return
    end
    if vim.api.nvim_get_current_win() == current and vim.env.REX_SESSION and vim.env.REX_BLOCK then
      vim.system({ "rex", "focus", "-s", vim.env.REX_SESSION, direction }, { text = true }, function(result)
        if result.code ~= 0 then
          vim.schedule(function()
            vim.notify("Rex pane navigation failed: " .. result.stderr, vim.log.levels.ERROR)
          end)
        end
      end)
    end
  end, { desc = "Navigate " .. direction .. " window" })
end
