return {
  -- VSCode-style live side-by-side / inline diff workspace built for reviewing agent changes
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    opts = {
      diff = {
        layout = "side-by-side",
        disable_inlay_hints = true,
        cycle_next_hunk = true,
        cycle_next_file = true,
        cycle_hunks_across_files = true,
        jump_to_first_change = true,
      },
      explorer = {
        position = "left",
        width = 38,
        auto_refresh = true,
        view_mode = "tree",
        flatten_dirs = true,
        focus_on_select = true,
        line_stats = {
          enabled = true,
        },
      },
      history = {
        position = "bottom",
        height = 14,
        view_mode = "tree",
      },
    },
    keys = {
      { "<leader>dv", "<cmd>CodeDiff<cr>", desc = "Diff: Working Tree (CodeDiff)" },
      { "<leader>ds", "<cmd>CodeDiff --staged<cr>", desc = "Diff: Staged Changes" },
      { "<leader>dm", "<cmd>CodeDiff origin/HEAD...<cr>", desc = "Diff: Branch vs origin/HEAD" },
      { "<leader>dM", "<cmd>CodeDiff main...<cr>", desc = "Diff: Branch vs main" },
      { "<leader>dh", "<cmd>CodeDiff history<cr>", desc = "Diff: Repo History" },
      { "<leader>df", "<cmd>CodeDiff history %<cr>", desc = "Diff: Current File History" },
      { "<leader>dp", ":CodeDiff pr ", desc = "Diff: Review PR #" },
    },
  },

  -- Inline git blame & hunk inspection while reading code
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = "eol",
      },
      word_diff = false,
      preview_config = {
        border = "rounded",
      },
    },
    keys = {
      { "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle Line Blame" },
      { "<leader>gw", "<cmd>Gitsigns toggle_word_diff<cr>", desc = "Toggle Word Diff" },
      { "<leader>gx", "<cmd>Gitsigns toggle_deleted<cr>", desc = "Toggle Deleted Lines" },
    },
  },
}
