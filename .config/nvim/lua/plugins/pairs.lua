return {
  {
    "echasnovski/mini.pairs",
    opts = function()
      return {
        -- Characters classes such as %a are documented there:
        -- https://www.lua.org/pil/20.2.html
        --
        -- neigh_pattern must be composed of 2 "matchers",
        -- If the first matcher matches the character before the one being typed, the close character of the pair is added as well.
        -- If the second matcher matches the character after the one being typed, the close character of the pair is skipped and no character is added.
        --
        -- "cr = true" (the default) means that if you type {<CR>} it will result in {<CR><cursor><CR>} so that the closing character is on its own line.
        mappings = {
          ["("] = { action = "open", pair = "()", neigh_pattern = ".[%s%)%]%}>,]" },
          ["["] = { action = "open", pair = "[]", neigh_pattern = ".[%s%)%]%}>,]" },
          ["{"] = { action = "open", pair = "{}", neigh_pattern = ".[%s%)%]%}>,]" },

          [")"] = { action = "close", pair = "()", neigh_pattern = ".." },
          ["]"] = { action = "close", pair = "[]", neigh_pattern = ".." },
          ["}"] = { action = "close", pair = "{}", neigh_pattern = ".." },

          ["<"] = { action = "open", pair = "<>", neigh_pattern = "[%a][^%a]", register = { cr = false } },
          [">"] = { action = "close", pair = "<>", neigh_pattern = ".[^%a]", register = { cr = false } },

          ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^%a\\][^%a]", register = { cr = false } },
          ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\][^%a]", register = { cr = false } },
          ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\r\n`].", register = { cr = false } },
        },
      }
    end,
  },
}
