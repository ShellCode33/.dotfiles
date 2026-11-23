local mason = {
    "mason-org/mason.nvim",
    config = function(_, opts)
        -- The image build installs and verifies the configured tools.
        require("mason").setup(opts)
    end,
}

if vim.g.nvim_image_prewarm then
    mason.build = false
    return {
        mason,
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

mason.opts = { registry_cache = { refresh = false } }
return { mason }
