if vim.g.nvim_image_prewarm then
    -- The build installs the configured tools synchronously in prewarm.lua.
    return {
        {
            "mason-org/mason.nvim",
            build = false,
            config = function(_, opts)
                require("mason").setup(opts)
            end,
        },
        { "jay-babu/mason-nvim-dap.nvim", config = function() end },
        {
            "iamcco/markdown-preview.nvim",
            build = function()
                require("lazy").load({ plugins = { "markdown-preview.nvim" } })
                vim.fn["mkdp#util#install_sync"]()
            end,
        },
    }
end

return {
    { "mason-org/mason.nvim", opts = { registry_cache = { refresh = false } } },
}
