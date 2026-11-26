return {
  "ibhagwan/fzf-lua",
  opts = function(_, opts)
    -- Keep LazyVim's base setup, then optimize the hot paths for large monorepos:
    -- Disabling file_icons, git_icons, and formatter removes the per-line headless
    -- Neovim Lua transform wrapper (spawn.lua), letting fzf-lua pipe fd/rg directly
    -- into fzf with zero Lua overhead.
    local actions = require("fzf-lua.actions")
    local merged = vim.tbl_deep_extend("force", opts or {}, {
      -- Keep picker process alive on <Esc> so subsequent opens are instant
      -- (re-uses the already-indexed file list in memory; <M-Esc> aborts).
      "hide",
      defaults = {
        file_icons = false,
        git_icons = false,
        formatter = false,
        multiline = false,
      },
      winopts = {
        width = 0.9,
        height = 0.85,
        preview = {
          hidden = false,
          layout = "flex",
          flip_columns = 120,
          horizontal = "right:55%",
          vertical = "down:50%",
        },
      },
      files = {
        -- Direct rg --files -> fzf pipe (no ANSI, no icons, no Lua formatter)
        file_icons = false,
        git_icons = false,
        formatter = false,
        cmd = "rg --files --hidden --color=never -g '!.git'",
        fzf_opts = {
          ["--ansi"] = false,
          ["--scheme"] = "path",
        },
        winopts = {
          preview = { hidden = true },
        },
      },
      git = {
        files = {
          file_icons = false,
          git_icons = false,
          formatter = false,
          cmd = "git ls-files --exclude-standard --cached --others",
          fzf_opts = {
            ["--ansi"] = false,
            ["--scheme"] = "path",
          },
          winopts = {
            preview = { hidden = true },
          },
        },
        status = {
          previewer = "git_diff",
          winopts = { preview = { hidden = false } },
        },
        diff = {
          winopts = { preview = { hidden = false } },
        },
        hunks = {
          winopts = { preview = { hidden = false } },
        },
        commits = {
          winopts = { preview = { hidden = false } },
        },
        bcommits = {
          winopts = { preview = { hidden = false } },
        },
        blame = {
          winopts = { preview = { hidden = false } },
        },
      },
      grep = {
        file_icons = false,
        git_icons = false,
        formatter = false,
        -- Fast rg defaults; supports `query -- *.ts !*test*` glob filtering via rg_glob
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --hidden -g '!.git' -e",
        rg_glob = true,
        winopts = {
          preview = { hidden = false },
        },
        actions = {
          ["ctrl-g"] = { actions.grep_lgrep },
          ["alt-i"] = { actions.toggle_ignore },
          ["alt-h"] = { actions.toggle_hidden },
        },
      },
    })
    -- Apply both default-title and hide profiles cleanly via LazyVim's config hook
    merged[1] = nil
    return merged
  end,
  config = function(_, opts)
    local fzf = require("fzf-lua")
    local function fix(t)
      t.prompt = t.prompt ~= nil and " " or nil
      for _, v in pairs(t) do
        if type(v) == "table" then
          fix(v)
        end
      end
      return t
    end
    local base = vim.tbl_deep_extend(
      "force",
      fix(vim.deepcopy(require("fzf-lua.profiles.default-title"))),
      vim.deepcopy(require("fzf-lua.profiles.hide"))
    )
    opts = vim.tbl_deep_extend("force", base, opts)
    opts[1] = nil
    fzf.setup(opts)
  end,
  keys = {
    -- Fast git-index file lookup (instant in huge git monorepos; skips filesystem walk)
    { "<leader><space>", LazyVim.pick("git_files", { show_untracked = true }), desc = "Find Files (git-files)" },
    { "<leader>ff", LazyVim.pick("git_files", { show_untracked = true }), desc = "Find Files (git-files)" },
    { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (rg --files, Root)" },
    -- Dedicated live_grep with zero Lua transform overhead for huge result sets
    { "<leader>sN", "<cmd>FzfLua live_grep_native<cr>", desc = "Grep Native (max speed)" },
    -- Search git hunks / changed files / buffer history
    { "<leader>gH", "<cmd>FzfLua git_hunks<cr>", desc = "Git Hunks (fzf)" },
    { "<leader>gD", "<cmd>FzfLua git_diff ref=origin/HEAD<cr>", desc = "Git Diff vs origin/HEAD (fzf)" },
    { "<leader>gC", "<cmd>FzfLua git_bcommits<cr>", desc = "Buffer Commits (fzf)" },
    -- Resume last search/picker instantly
    { "<leader>s.", "<cmd>FzfLua resume<cr>", desc = "Resume Last Picker" },
  },
}
