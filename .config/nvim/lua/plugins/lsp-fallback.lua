-- NOTE: Most of the mason configuration is done through LazyVim's extras.
--       What's being configured here are all the tools not already handled
--       by LSPs and LazyVim extras.
return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash-language-server",
        "shellcheck",
      })
    end,
  },
}
