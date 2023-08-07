return {

  -- Disable default LuaSnip behavior, nvim-cmp will take car of it
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },

  -- Setup completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "f3fora/cmp-spell" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, {
        -- Plugin that injects spelling suggestions into the completion engine
        {
          name = "spell",
          option = {
            keep_all_entries = false,
            enable_in_context = function()
              return true
            end,
          },
        },
      }))

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        -- Note: snippets are being processed first,
        -- it means that Tab won't trigger completion while filling in a snippet
        ["<Tab>"] = cmp.mapping(function(fallback)
          if luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif cmp.visible() then
            cmp.select_next_item()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          elseif cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      })
    end,
  },
}
