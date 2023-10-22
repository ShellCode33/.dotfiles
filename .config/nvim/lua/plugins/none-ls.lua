return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local nls = require("null-ls")
    opts.root_dir = opts.root_dir
      or require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")
    opts.sources = vim.list_extend(opts.sources or {}, {
      -- Formatters
      nls.builtins.formatting.stylua,
      nls.builtins.formatting.shfmt,

      -- Diagnostics
      nls.builtins.diagnostics.shellcheck,
      nls.builtins.diagnostics.bandit,
    })
  end,
}
