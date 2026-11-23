-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Only sections marked as @Spell by treesitter will be spellchecked.
-- In code, usually only comments and strings are spellchecked.
-- Use z= to fix spelling.
vim.opt.spell = true
vim.opt.spelllang = "en_us"
vim.opt.spelloptions:append({ "camel" })

vim.opt.swapfile = vim.env.NVIM_CONTAINER == "1"
if vim.opt.swapfile:get() then
    vim.opt.spellfile = "/tmp/nvim-spell.utf-8.add"
    -- Editor containers for the same project share the default swap directory.
    -- Keep the second editor read-only even when the PIDs are in different namespaces.
    pcall(vim.api.nvim_clear_autocmds, { group = "nvim.swapfile", event = "SwapExists" })
    vim.api.nvim_create_autocmd("SwapExists", {
        callback = function()
            vim.v.swapchoice = "o"
            vim.notify("Existing swap file. Opened read-only: " .. vim.v.swapname, vim.log.levels.WARN)
        end,
    })
    -- Two processes can both try to create the swap file before either sees it.
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        callback = function(event)
            local buffer = vim.bo[event.buf]
            if
                event.file ~= ""
                and buffer.buftype == ""
                and buffer.swapfile
                and not buffer.readonly
                and vim.o.updatecount > 0
                and vim.fn.swapname(event.buf) == ""
            then
                buffer.readonly = true
                vim.notify("Could not reserve a swap file. Opened read-only: " .. event.file, vim.log.levels.WARN)
            end
        end,
    })
end
