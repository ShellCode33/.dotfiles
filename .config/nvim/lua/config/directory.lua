local readme_priority = {
    ["readme.md"] = 1,
    ["readme.markdown"] = 2,
    readme = 3,
    ["readme.rst"] = 4,
    ["readme.txt"] = 5,
}

local function find_readme(directory)
    local candidates = {}
    local entries = vim.uv.fs_scandir(directory)
    if not entries then
        return
    end
    while true do
        local name = vim.uv.fs_scandir_next(entries)
        if not name then
            break
        end
        local lower = name:lower()
        if lower == "readme" or lower:match("^readme%.") then
            local path = vim.fs.joinpath(directory, name)
            if vim.fn.filereadable(path) == 1 then
                candidates[#candidates + 1] = { path = path, priority = readme_priority[lower] or 6 }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.priority == b.priority then
            return a.path < b.path
        end
        return a.priority < b.priority
    end)
    return candidates[1] and candidates[1].path
end

vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("directory-readme", { clear = true }),
    callback = function(event)
        if event.file == "" or vim.fn.isdirectory(event.file) ~= 1 then
            return
        end
        local directory = vim.uv.fs_realpath(event.file)
        if not directory then
            return
        end
        local tab = vim.api.nvim_get_current_tabpage()
        -- Let Snacks open and focus the sidebar before switching to its editor window.
        local function open_readme()
            if not Snacks or vim.api.nvim_get_current_tabpage() ~= tab then
                return
            end
            local picker = Snacks.picker.get({ source = "explorer" })[1]
            if not picker then
                -- Snacks can toggle an existing explorer off when editing another directory.
                picker = Snacks.explorer({ cwd = directory })
            elseif vim.uv.fs_realpath(picker:cwd()) ~= directory then
                picker:set_cwd(directory)
                picker:find()
            end
            local main = picker and picker.main
            local readme = find_readme(directory)
            if readme and main and vim.api.nvim_win_is_valid(main) then
                vim.api.nvim_set_current_win(main)
                vim.cmd.edit({ args = { readme } })
            end
        end
        if vim.v.vim_did_enter == 0 then
            vim.api.nvim_create_autocmd("VimEnter", {
                once = true,
                callback = function()
                    vim.schedule(open_readme)
                end,
            })
        else
            vim.schedule(open_readme)
        end
    end,
})
