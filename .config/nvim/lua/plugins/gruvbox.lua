return {
  -- add gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      contrast = "hard",
      overrides = {
        -- Add some Telescope missing colors
        TelescopePromptTitle = { fg = "#282828", bg = "#689d6a" },
        TelescopePreviewTitle = { fg = "#282828", bg = "#d65d0e" },
        TelescopeTitle = { fg = "#282828", bg = "#98971a" },

        -- Highlight what's under cursor
        IlluminatedWordText = { bg = "#333333" },
        IlluminatedWordRead = { bg = "#333333" },
        IlluminatedWordWrite = { bg = "#333333" },
      },
    },
  },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
