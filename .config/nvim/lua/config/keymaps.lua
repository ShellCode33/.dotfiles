-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local opts = { noremap = true, silent = true }

-- Move arround in insert mode using CTRL key
vim.keymap.set("i", "<C-h>", "<Left>", opts)
vim.keymap.set("i", "<C-j>", "<Down>", opts)
vim.keymap.set("i", "<C-k>", "<Up>", opts)
vim.keymap.set("i", "<C-l>", "<Right>", opts)

-- Moving lines in visual and normal modes
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", opts)
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", opts)
vim.keymap.set("n", "<C-j>", ":m .+1<CR>==", opts)
vim.keymap.set("n", "<C-k>", ":m .-2<CR>==", opts)
