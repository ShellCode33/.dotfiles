local function git(args)
    local result = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
    assert(result.code == 0, result.stderr)
    return vim.trim(result.stdout)
end

local function prewarm()
    local lock_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
    local refresh_lock = vim.env.NVIM_REFRESH_LOCK == "1"
    local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
    if vim.g.nvim_image_bootstrap then
        -- Make LazyVim's imported specs available before Lazy resolves the lockfile.
        for name, repository in pairs({
            ["lazy.nvim"] = { path = "folke/lazy.nvim", ref = "stable" },
            LazyVim = { path = "LazyVim/LazyVim", ref = "HEAD" },
        }) do
            local directory = vim.fn.stdpath("data") .. "/lazy/" .. name
            local url = "https://github.com/" .. repository.path .. ".git"
            if refresh_lock then
                -- A normal clone records the upstream branch and tracking ref for Lazy's lockfile.
                git({ "clone", "--quiet", "--filter=blob:none", url, directory })
                if repository.ref ~= "HEAD" then
                    git({ "-C", directory, "checkout", "--quiet", repository.ref })
                end
            else
                local revision = assert(lock[name], "Missing pin for " .. name)
                vim.fn.mkdir(directory, "p")
                git({ "-C", directory, "init", "--quiet" })
                git({ "-C", directory, "remote", "add", "origin", url })
                git({ "-C", directory, "fetch", "--quiet", "--depth", "1", "origin", revision.commit })
                git({ "-C", directory, "checkout", "--quiet", "-B", revision.branch, "FETCH_HEAD" })
            end
        end
        return
    end

    assert(vim.g.lazy_did_setup, "LazyVim failed to start")
    local lazy = require("lazy")
    if refresh_lock then
        require("lazy.manage.lock").update()
        lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
    end
    local specs = require("lazy.core.config").plugins
    for name, plugin in pairs(specs) do
        assert(plugin._.installed, "Could not install plugin: " .. name)
        local revision = lock[name]
        if refresh_lock and plugin.url then
            assert(revision, "Could not lock plugin: " .. name)
        end
        if revision then
            assert(
                git({ "-C", plugin.dir, "rev-parse", "HEAD" }) == revision.commit,
                "Could not install pinned plugin: " .. name
            )
        end
    end

    lazy.load({ plugins = { "blink.cmp", "markdown-preview.nvim" } })
    assert(vim.fn["mkdp#util#pre_build_version"]() ~= "", "Missing Markdown preview binary")
    assert(
        vim.wait(60000, function()
            return require("blink.cmp.fuzzy").implementation_type == "rust"
        end, 100),
        "Missing Blink completion library"
    )

    lazy.load({ plugins = { "mason.nvim", "mason-nvim-dap.nvim", "nvim-treesitter" } })
    local registry = require("mason-registry")
    registry.refresh()
    lazy.load({ plugins = { "nvim-lspconfig" } })

    local packages = vim.deepcopy(LazyVim.opts("mason.nvim").ensure_installed)
    local lsp_packages = require("mason-lspconfig").get_mappings().lspconfig_to_package
    for _, server in ipairs(require("mason-lspconfig.settings").current.ensure_installed) do
        local package = assert(lsp_packages[server], "Missing Mason mapping for " .. server)
        table.insert(packages, package)
    end
    local dap_packages = require("mason-nvim-dap.mappings.source").nvim_dap_to_package
    for _, adapter in ipairs(LazyVim.opts("mason-nvim-dap.nvim").ensure_installed) do
        local package = assert(dap_packages[adapter], "Missing Mason mapping for " .. adapter)
        table.insert(packages, package)
    end

    local function missing_tools()
        return vim.tbl_filter(function(package)
            return not registry.is_installed(package)
        end, vim.list.unique(packages))
    end
    local missing = missing_tools()
    if #missing > 0 then
        -- Mason forwards subprocess stderr as Neovim errors without --quiet.
        vim.cmd.MasonInstall({ args = vim.list_extend({ "--quiet" }, missing) })
    end
    assert(
        vim.wait(300000, function()
            return #missing_tools() == 0
        end, 100),
        "Missing Mason packages: " .. table.concat(missing_tools(), ", ")
    )

    local parsers = LazyVim.opts("nvim-treesitter").ensure_installed
    local function missing_parsers()
        local installed = require("nvim-treesitter").get_installed("parsers")
        return vim.tbl_filter(function(parser)
            return not vim.tbl_contains(installed, parser)
        end, parsers)
    end
    assert(
        vim.wait(300000, function()
            return #missing_parsers() == 0
        end, 100),
        "Missing Treesitter parsers: " .. table.concat(missing_parsers(), ", ")
    )
end

local ok, error_message = xpcall(prewarm, debug.traceback)
if not ok then
    io.stderr:write(error_message, "\n")
    vim.cmd.cquit()
end
