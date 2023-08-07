return {
  -- Disable default autopair plugin which doesn't work as I would expect
  {
    "echasnovski/mini.pairs",
    enabled = false,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      -- Don"t add pairs if it already has a close pair in the same line
      enable_check_bracket_line = true,

      -- Don"t add pairs if the next char is alphanumeric
      ignored_next_char = "[%w%.]", -- will ignore alphanumeric and `.` symbol
      fast_wrap = {},
      disable_filetype = { "TelescopePrompt", "vim" },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on(
        "confirm_done",
        cmp_autopairs.on_confirm_done({
          map_char = {
            tex = "",
          },
        })
      )
    end,
  },
}
