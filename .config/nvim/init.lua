if vim.env.NVIM_CONTAINER == "1" then
    -- Send clipboard writes to the terminal hosting the container.
    vim.g.clipboard = "osc52"
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
