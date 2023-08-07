return {
  -- Remove keymaps from the LSP config
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()

      for index, keymap in pairs(keys) do
        -- Remove <c-k> keymap in insert mode because it conflicts with our own
        if keymap[1] == "<c-k>" and keymap.mode == "i" then
          keys[index] = nil
          break
        end
      end
    end,
  },
}
