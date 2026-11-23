local function warm_filetypes()
    assert(vim.g.lazy_did_setup and jit.status(), "LazyVim or LuaJIT failed to start")

    -- Exercise file-open hooks without starting language server processes.
    vim.lsp.start = function() end
    local lazy = require("lazy")
    lazy.load({ plugins = { "nvim-lspconfig" } })
    local servers = require("mason-lspconfig").get_installed_servers()
    vim.list_extend(servers, vim.tbl_keys(LazyVim.opts("nvim-lspconfig").servers))

    local filetypes = {}
    for _, server in ipairs(vim.list.unique(servers)) do
        if vim.lsp.is_enabled(server) then
            for _, filetype in ipairs(vim.lsp.config[server].filetypes or {}) do
                filetypes[filetype] = true
            end
        end
    end
    -- Rustaceanvim manages its own language server outside nvim-lspconfig.
    if LazyVim.has("rustaceanvim") then
        filetypes.rust = true
    end
    assert(next(filetypes), "No configured LSP filetypes found to prewarm")

    local directory = vim.fn.tempname()
    vim.fn.mkdir(directory, "p")
    if filetypes.rust then
        vim.fn.writefile({ '{"crates":[]}' }, directory .. "/rust-project.json")
    end
    local warmed = {}
    for filetype in vim.spairs(filetypes) do
        local filename = directory .. (filetype == "rust" and "/main.rs" or "/warmup-" .. filetype)
        vim.filetype.add({ filename = { [filename] = filetype } })
        vim.fn.writefile({ "" }, filename)
        vim.cmd.edit({ args = { filename } })
        assert(vim.bo.filetype == filetype, "Could not open warmup buffer for " .. filetype)
        warmed[#warmed + 1] = filetype
    end
    io.stdout:write("Prewarmed filetypes: ", table.concat(warmed, ", "), "\n")
end

-- Start with a real UI so the dashboard and UI plugins run their usual startup.
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
        vim.schedule(function()
            local ok, error_message = xpcall(warm_filetypes, debug.traceback)
            if not ok then
                io.stderr:write(error_message, "\n")
            end
            -- The cache is written synchronously. Skip session shutdown hooks in the build.
            os.exit(ok and 0 or 1)
        end)
    end,
})
