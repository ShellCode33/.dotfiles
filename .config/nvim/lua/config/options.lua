-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Only sections marked as @Spell by treesitter will be spellchecked.
-- In code, usually only comments and strings are spellchecked.
-- Use z= to fix spelling.
vim.opt.spell = true
vim.opt.spelllang = "en_us"
vim.opt.spelloptions:append({ "camel" })

vim.opt.swapfile = false
