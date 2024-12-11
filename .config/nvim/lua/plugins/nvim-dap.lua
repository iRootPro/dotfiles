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
      dap.adapters.odin_app = {
        type = "server",
        host = "odin-app.sbmt",
        port = 2345,
      }

      dap.configurations.go = {
        -- {
        --   type = "go",
        --   name = "Debug Webservice",
        --   request = "launch",
        --   showLog = false,
        --   program = "${file}",
        --   dlvToolPath = vim.fn.exepath("dlv"), -- Adjust to where delve is installed
        -- },

        {
          type = "odin_app",
          request = "attach",
          name = "Attach to odin-app.sbmt",
          mode = "remote",
          remotePath = "/go/src/gitlab.sbmt.io/paas/odin",
          -- substitutePath = {
          --   {
          --     from = "${workspaceFolder}",
          --     to = "/go/src/gitlab.sbmt.io/paas/odin",
          --   },
          -- },
        },
        {
          name = "[SBM-CLI] codegen --clients",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "codegen",
            "--clients",
          },
          cwd = "/Users/neupokoev/Documents/Code/assembly",
        },
        {
          name = "[SBM-CLI] codegen --silent [odin]",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "codegen",
            "--silent",
          },
          cwd = "/Users/neupokoev/Documents/Code/odin",
        },
        {
          name = "[SBM-CLI] codegen [odin]",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "codegen",
          },
          cwd = "/Users/neupokoev/Documents/Code/odin",
        },
        {
          name = "[SBM-CLI] codegen --openapi-clients freya=pods",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "codegen",
            "--openapi-clients",
            "freya=pods",
            "--version=1.0.0",
          },
          cwd = "/Users/neupokoev/Documents/Code/ruby-test",
        },
        {
          name = "[SBM-CLI] codegen --openapi-clients freya1",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "codegen",
            "--openapi-clients",
            "freya1",
          },
          cwd = "/Users/neupokoev/Documents/Code/ruby-test",
        },
        {
          name = "[SBM-CLI] dependency add mincer",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "dependency",
            "add",
            "https://gitlab.sbmt.io/paas/platform/mincer/",
            "--branch=master",
            "--grpc=events",
          },
          cwd = "/Users/neupokoev/Documents/Code/ruby-test/",
        },
        {
          name = "[SBM-CLI] inframanifest check",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}/cmd/sbm-cli",
          args = {
            "inframanifest",
            "check",
          },
          cwd = "/Users/neupokoev/Documents/Code/odin",
        },

        {
          name = "[gocover] problem",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}",
          args = {
            "<",
            "go-tests-dispatch_coverage.out",
            ">",
            "coverage.xml",
          },
          cwd = "/Users/neupokoev/Documents/Code/gocover-cobertura",
        },
        {
          name = "[gocover] OK",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}",
          args = {
            "<",
            "testdata_set.txt",
            ">",
            "coverage.xml",
          },
          cwd = "/Users/neupokoev/Documents/Code/gocover-cobertura",
        },

        {
          name = "[k8sdiff] run",
          type = "go",
          request = "launch",
          program = "${workspaceFolder}",
          cwd = "/Users/neupokoev/Documents/Code/k8sdiff",
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
        {
          name = "odin",
          type = "go",
          request = "attach",
          mode = "remote",
          remotePath = "/go/src/gitlab.sbmt.io/paas/odin",
          connect = { port = 2345, host = "odin-app.sbmt" },
        },
      }
    end,
  },
}
