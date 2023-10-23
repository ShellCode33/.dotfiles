-- NOTE: most of the mason and none-ls configuration is done through
--       LazyVim's extras. What's being configured here are all the
--       tools not already handled by LSPs and LazyVim extras.
return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "shellcheck",
      })
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      -- Patterns order matters
      local root_patterns = {
        ".null-ls-root",
        ".neoconf.json",
        "pyproject.toml",
        "Makefile",
        ".git",
      }
      opts.debug = true
      opts.root_dir = opts.root_dir or require("null-ls.utils").root_pattern(unpack(root_patterns))
      opts.sources = vim.list_extend(opts.sources or {}, {
        -- Formatters
        nls.builtins.formatting.ruff,

        -- Diagnostics
        nls.builtins.diagnostics.shellcheck,
        nls.builtins.diagnostics.bandit,
      })
    end,
  },
}
