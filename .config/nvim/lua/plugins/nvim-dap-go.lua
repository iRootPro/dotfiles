return {
  { import = "lazyvim.plugins.extras.dap.core" },

  {
    "leoluz/nvim-dap-go",

    -- stylua: ignore
    keys = {
      -- remap dt and move terminate to dT
      -- TODO: this works 50% of the time -- race condition?
      --{ "<leader>dt", function() require('dap-go').debug_test() end, desc = "Debug Test" },
      --{ "<leader>dT", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dT", function() require('dap-go').debug_test() end, desc = "Debug Test" },
      { "<leader>dbc", function() require('dap').clear_breakpoints() end, desc = "Clear Breakpoints" },
    },
  },
}
