return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "gomodifytags", "impl", "gofumpt", "goimports-reviser", "delve" })
        end,
      },
      {
        "leoluz/nvim-dap-go",
        config = true,
      },
    },
    opts = function()
      local dap = require("dap")

      dap.adapters.delve = {
        type = "server",
        port = "${port}",
        executable = {
          command = "dlv",
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }
      -- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
      dap.configurations.go = {
        {
          name = "[SBM-CLI] service up",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "service",
            "up",
          },
          cwd = "/Users/sasha/Documents/Code/odin",
          -- cwd = "/Users/sasha/Documents/Code/stock",
        },
        {
          type = "delve",
          name = "Debug",
          request = "launch",
          program = "${file}",
        },
        {
          type = "delve",
          name = "Debug test", -- configuration for debugging test files
          request = "launch",
          mode = "test",
          program = "${file}",
        },
        -- works with go.mod packages and sub packages
        {
          type = "delve",
          name = "Debug test (go.mod)",
          request = "launch",
          mode = "test",
          program = "./${relativeFileDirname}",
        },
        {
          type = "go",
          name = "Debug Package",
          request = "launch",
          program = "${fileDirname}",
        },
        {
          type = "go",
          name = "Attach",
          mode = "local",
          request = "attach",
        },
        {
          type = "delve",
          name = "sbm-cli",
          request = "launch",
          program = "/Users/sasha/Documents/Code/sbm-cli/bin/sbm-cli/sbm-cli service up",
          cwd = "/Users/sasha/Documents/Code/mincer",
        },
      }
    end,
  },
}
