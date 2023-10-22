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

        -- Highlight symbol under cursor
        IlluminatedWordText = { bg = "#333333", bold = true },
        IlluminatedWordRead = { bg = "#333333", bold = true },
        IlluminatedWordWrite = { bg = "#333333", bold = true },

        -- Dashboard colors
        DashboardHeader = { link = "GruvboxYellow" },
        DashboardFooter = { link = "GruvboxYellow" },
        DashboardDesc = { link = "GruvboxGray" },
        DashboardKey = { link = "GruvboxYellow" },
        DashboardIcon = { link = "GruvboxYellow" },
        DashboardShortCut = { link = "GruvboxRed" },
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
