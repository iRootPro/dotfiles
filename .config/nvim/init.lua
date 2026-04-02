-----------------------
-------- Опции --------
-----------------------
local opt = vim.opt
local g = vim.g

g.mapleader = " "  -- Установка лидера

opt.number = true        -- Нумерация строк
opt.hlsearch = true      -- Подсветка найденных совпадений
opt.ignorecase = true    -- Игнорируем заглавные буквы при поиске
opt.smartcase = true     -- Если в поиске указываем заглвные буквы, то искать будет с учетом регистра
-- termguicolors включён по умолчанию в 0.12

-- Настройка отступов
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Прокрутка начинается за 8 строк до конца
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.updatetime = 50                                -- Быстрое обновление lsp
opt.clipboard:append({ "unnamed", "unnamedplus" }) -- Использование системного буфера
opt.undodir = vim.fn.stdpath("cache") .. "/undo"   -- Включаем бесконечные undo операции
opt.undofile = true

opt.swapfile = false      -- Отключим swapfile
opt.list = true           -- Подсвечивать пробелы в конце
opt.listchars = { tab = "  ", trail = "·", extends = ">", precedes = "<" }
opt.cursorline = true     -- Показывать подсветку курсора линией
opt.winborder = "rounded" -- Оформление подсказок с закруглениями

-- включение выделение парных кавычек и скобок
opt.showmatch = true
opt.matchtime = 2
opt.signcolumn = "yes" -- Всегда показывать колонку знаков, чтобы не дергалось окно при появлении значков

-------------------------
-------- Plugins --------
-------------------------
vim.pack.add({
  { src = "https://github.com/rebelot/kanagawa.nvim" }, -- Colorscheme
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/saghen/blink.cmp",               version = vim.version.range("^1") }, -- Autocomplete
  { src = "https://github.com/hedyhli/outline.nvim" },
  { src = "https://github.com/windwp/nvim-autopairs" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/leoluz/nvim-dap-go" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio" }, -- зависимость dap-ui
})

-------------------------
-------- Keymaps --------
-------------------------
local keymap = vim.keymap.set
keymap("n", "<ESC>", ":nohlsearch<CR>", { silent = true, desc = "Clear search" })
keymap("n", "<C-w>", ":w!<CR>", { silent = true, desc = "Save buffer" })
keymap("n", "QQ", ":qa!<CR>", { silent = true, desc = "Force quit" })
keymap("n", "<leader>pu", ':lua vim.pack.update()<CR>', { desc = "Update plugins" })
keymap("n", "<leader>r", ':so<CR>', { desc = "Reload config" })
keymap("n", "<leader>lf", function()
  require("conform").format({ async = false, lsp_format = "fallback" })
end, { desc = "Format buffer" })
keymap("n", "<leader>e", function() Snacks.explorer() end, { desc = "File explorer" })
keymap("n", "<leader><leader>", function() Snacks.picker.files() end, { desc = "Find files" })
keymap("n", "<leader>/", function() Snacks.picker.grep() end, { desc = "Live grep" })
keymap("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
keymap("n", "<leader>fh", function() Snacks.picker.help() end, { desc = "Help tags" })
keymap("n", "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics" })
keymap("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
keymap("n", "<leader>ne", ":e ~/.config/nvim/init.lua<CR>", { desc = "Edit config" })

keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
keymap("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
keymap('n', '<leader>ld', vim.diagnostic.open_float, { desc = 'Show diagnostic' })
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Quickfix diagnostics' })

-- Документация (dotfiles docs через Snacks.win)
local dotfiles = vim.fn.expand("~/Downloads/dotfiles")
local function open_doc(file, title)
  Snacks.win({
    file = dotfiles .. "/" .. file,
    width = 0.7,
    height = 0.8,
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    enter = true,
    ft = "markdown",
    keys = { q = "close", ["<ESC>"] = "close" },
    wo = {
      wrap = true,
      linebreak = true,
      conceallevel = 2,
      spell = false,
      signcolumn = "no",
      statuscolumn = " ",
      cursorline = true,
    },
  })
end
keymap("n", "<leader>?", function() open_doc("README.md", "Dotfiles README") end, { desc = "README dotfiles" })
keymap("n", "<leader>?n", function() open_doc("nvim.md", "Neovim Docs") end, { desc = "Neovim docs" })
keymap("n", "<leader>?z", function() open_doc("zsh.md", "Zsh Docs") end, { desc = "Zsh docs" })
keymap("n", "<leader>?k", function() open_doc("kitty.md", "Kitty Docs") end, { desc = "Kitty docs" })

-- Go (через терминал, без go.nvim)
keymap("n", "<leader>gg", ":!go generate ./...<CR>", { desc = "Go generate" })
keymap("n", "<leader>gt", ":!go test ./...<CR>", { desc = "Go test" })
keymap("n", "<leader>gf", function()
  local func = vim.fn.expand("<cword>")
  vim.cmd("!go test -run " .. func .. " ./...")
end, { desc = "Go test function" })
keymap("n", "<leader>gs", function() vim.lsp.buf.code_action() end, { desc = "Go fill struct (code action)" })

-- Debug (DAP)
keymap("n", "<leader>db", function() require("dap").toggle_breakpoint() end, { desc = "Toggle breakpoint" })
keymap("n", "<leader>dt", function() require("dap-go").debug_test() end, { desc = "Debug nearest test" })
keymap("n", "<leader>dl", function() require("dap-go").debug_last_test() end, { desc = "Debug last test" })
keymap("n", "<leader>du", function() require("dapui").toggle() end, { desc = "Toggle DAP UI" })
keymap("n", "<leader>dx", function() require("dap").terminate() end, { desc = "Terminate debug" })
-- Outline symbols
keymap("n", "<leader>o", ":Outline<CR>", { silent = true, desc = "Toggle outline" })

-- Навигация между сплитами
keymap('n', '<C-h>', '<C-w>h', { desc = 'Go to left window' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Go to bottom window' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Go to top window' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Go to right window' })

-- Работа со сплитами
keymap('n', '<Leader>vs', '<C-w>v', { desc = 'Vertical split' })
keymap('n', '<Leader>hs', '<C-w>s', { desc = 'Horizontal split' })
keymap('n', '<Leader>wt', function()
  if vim.g.window_maximized then
    vim.cmd('wincmd =')
    vim.g.window_maximized = false
  else
    vim.cmd('wincmd _ | wincmd |')
    vim.g.window_maximized = true
  end
end, { desc = 'Toggle maximize window' })

-- Закрытие окон
keymap('n', '<Leader>wc', '<C-w>c', { desc = 'Close window' })
keymap('n', '<Leader>wo', '<C-w>o', { desc = 'Close other windows' })

---------------------
-------- LSP --------
---------------------
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      diagnostics = { globals = { "vim", "Snacks" } },
    },
  },
})

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gosum", "gotmpl" },
  root_markers = { "go.mod", "go.work", ".git" },
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
      gofumpt = true,
      semanticTokens = false,
    },
  },
})

vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = { "compile_commands.json", ".clangd", ".git" },
})

vim.lsp.config("yamlls", {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose" },
  root_markers = { ".git" },
})

vim.lsp.enable({ "lua_ls", "gopls", "clangd", "yamlls" })

require("snacks").setup({
  picker = {
    enabled = true,
    sources = {
      explorer = {
        diagnostics = false,
        git_status = true,
        layout = {
          preset = "sidebar",
          preview = false,
          hidden = { "input" },
          layout = { position = "left", width = 30, border = "none" },
        },
        icons = {
          tree = { vertical = "  ", middle = "  ", last = "  " },
        },
        win = {
          list = {
            wo = {
              winhighlight = "NormalFloat:Normal,CursorLine:CursorLine,FloatBorder:Normal",
              winbar = "",
            },
          },
        },
      },
    },
  },
  explorer = { enabled = true },
})

require("outline").setup({})
require("nvim-autopairs").setup({})

-- nvim-treesitter 0.12: новый API (branch main, не master)
require("nvim-treesitter").setup({})
require("nvim-treesitter").install({
  "c", "cpp", "lua", "vim", "vimdoc", "query",
  "go", "gomod", "gowork", "gosum", "python", "bash", "yaml", "json",
})

-- Treesitter подсветка и indent через нативный API (0.12)
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})


require('blink.cmp').setup({
  keymap = { preset = 'enter' },
})

require("gitsigns").setup({
  signs = {
    add          = { text = "┃" },
    change       = { text = "┃" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
    untracked    = { text = "┆" },
  },
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end
    map("n", "]c", function()
      if vim.wo.diff then vim.cmd.normal({ "]c", bang = true })
      else gs.nav_hunk("next") end
    end, { desc = "Next hunk" })
    map("n", "[c", function()
      if vim.wo.diff then vim.cmd.normal({ "[c", bang = true })
      else gs.nav_hunk("prev") end
    end, { desc = "Previous hunk" })
    map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
    map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
    map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
    map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
  end,
})

require("conform").setup({
  formatters_by_ft = {
    go = { "goimports", "gofmt" },
    lua = { "stylua" },
    python = { "ruff_format", "black", stop_after_first = true },
    c = { "clang-format" },
    cpp = { "clang-format" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    rust = { "rustfmt" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

require("oil").setup({
  view_options = {
    show_hidden = true,
  },
})

require("render-markdown").setup({
  file_types = { "markdown" },
})

-- DAP (Debug Adapter Protocol)
local dap, dapui = require("dap"), require("dapui")
require("dap-go").setup()
dapui.setup()

-- Быстрые кейбинды для навигации в дебаге (активны только во время сессии)
local function dap_map(key, fn, desc)
  vim.keymap.set("n", key, fn, { desc = "DAP: " .. desc })
end
local dap_keys = { "n", "s", "o", "c", "x" }

local function set_dap_keys()
  dap_map("n", dap.step_over, "step over (next)")
  dap_map("s", dap.step_into, "step into")
  dap_map("o", dap.step_out, "step out")
  dap_map("c", dap.continue, "continue")
  dap_map("x", dap.terminate, "terminate")
end

local function unset_dap_keys()
  for _, key in ipairs(dap_keys) do
    pcall(vim.keymap.del, "n", key)
  end
end

-- Автоматически открывать/закрывать UI и кейбинды при старте/завершении дебага
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
  set_dap_keys()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
  unset_dap_keys()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
  unset_dap_keys()
end

-- Иконки для брейкпоинтов
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

require("which-key").setup()
require("which-key").add({
  { "<leader>f", group = "find" },
  { "<leader>h", group = "git hunks" },
  { "<leader>g", group = "go" },
  { "<leader>w", group = "windows" },
  { "<leader>l", group = "lsp" },
  { "<leader>s", group = "search" },
  { "<leader>p", group = "plugins" },
  { "<leader>?", group = "docs" },
  { "<leader>d", group = "debug" },
})

------------------------------
-------- Color scheme --------
------------------------------
require("kanagawa").setup({
  overrides = function(colors)
    return {
      NormalFloat = { bg = colors.palette.sumiInk3 }, -- тот же фон что у Normal
    }
  end,
})
vim.cmd.colorscheme("kanagawa")

-------------------------------
-------- AUTO COMMANDS --------
-------------------------------
-- Автоматическое создание директории для undo файлов
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local undo_dir = vim.fn.stdpath("cache") .. "/undo"
    if vim.fn.isdirectory(undo_dir) == 0 then
      vim.fn.mkdir(undo_dir, "p")
    end
  end,
})

-- Установить для LineNr и SignColumn тот же фон что у Normal
-- Почти одинаковый фон с легким отличием
vim.api.nvim_set_hl(0, "LineNr", { bg = "#1f1f28", fg = "#666666" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "#1f1f28", fg = "#938aa9" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "#252530", fg = "#dcd7ba" }) -- легкое выделение


-- Сначала объявим функции
local function git_branch()
  local head = vim.b.gitsigns_head
  if head and head ~= "" then
    return "   " .. head .. " "
  end
  return ""
end

local function lsp_diagnostics()
  local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })

  local result = ""
  if errors > 0 then result = result .. " [ERR " .. errors .. "] " end
  if warnings > 0 then result = result .. " [WARN " .. warnings .. "] " end

  return result
end

local function filetype_info()
  local ft = vim.bo.filetype
  if ft == "" then return "" end

  local icons = {
    go = "",
    lua = "",
    python = "",
    javascript = "",
    typescript = "",
    rust = "",
    c = "",
    cpp = "",
    java = "",
    html = "",
    css = "",
    json = "",
    markdown = "",
    vim = "",
    bash = "",
    yaml = "󰈔",
    toml = "󰈔",
    xml = "󰈔",
    dockerfile = "",
    sql = "",
  }

  local icon = icons[ft] or "" -- файл по умолчанию:w
  return icon .. " " .. ft:upper()
end

local function os_logo()
  if vim.fn.has('mac') == 1 then
    return " "
  elseif vim.fn.has('unix') == 1 then
    return " "
  elseif vim.fn.has('win32') == 1 then
    return " "
  elseif vim.fn.has('bsd') == 1 then
    return " "
  else
    return " "
  end
end

-- Делаем функции глобальными для доступа из statusline
_G.git_branch = git_branch
_G.lsp_diagnostics = lsp_diagnostics
_G.filetype_info = filetype_info
_G.os_logo = os_logo

vim.opt.laststatus = 3

vim.opt.statusline = ""
    .. "%#StatusLine#" -- основной цвет
    .. " %{v:lua.os_logo()}" -- логотип ОС
    .. "%{toupper(mode())}" -- режим VIM
    .. "%#StatusLineNC#" -- цвет разделителя
    .. " ┃ " -- строгий разделитель
    .. "%#StatusLine#" -- снова основной
    .. " %f" -- имя файла
    .. "%m%r" -- модификаторы
    .. "%#StatusLineNC#" -- для git/diagnostics
    .. "%{v:lua.git_branch()}" -- git ветка
    .. "%{v:lua.lsp_diagnostics()}" -- диагностика LSP
    .. " "
    .. " %=" -- выравнивание вправо
    .. "%#StatusLine#" -- правая часть
    .. " %{v:lua.filetype_info()} "
    .. "%#StatusLineNC#" -- разделитель
-- Цвета
vim.api.nvim_set_hl(0, "StatusLine", { bg = "#1f1f28", fg = "#dcd7ba" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#1f1f28", fg = "#727169" })
