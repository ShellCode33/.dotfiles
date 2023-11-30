return {
  "jay-babu/mason-nvim-dap.nvim",
  opts = {
    -- Makes a best effort to setup the various debuggers with
    -- reasonable debug configurations
    automatic_installation = true,

    handlers = {
      function(config)
        -- all sources with no handler get passed here

        -- Keep original functionality
        require("mason-nvim-dap").default_setup(config)
      end,
      python = function(config)
        config.adapters = {
          type = "executable",
          command = "/usr/bin/env",
          args = {
            "python3",
            "-m",
            "debugpy.adapter",
          },
        }

        -- Don't forget to setup the default behavior as well
        require("mason-nvim-dap").default_setup(config)
      end,
    },

    -- You'll need to check that you have the required things installed
    -- online, please don't ask me how to install them :)
    ensure_installed = {
      -- Update this to ensure that you have the debuggers for the langs you want
      "cppdbg", -- for both C and C++
      "python",
      "codelldb",
    },
  },
}
