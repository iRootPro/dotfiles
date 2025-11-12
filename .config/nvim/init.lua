-----------------------
-------- Опции --------
-----------------------
local opt = vim.opt
local g = vim.g

g.mapleader = " "  -- Установка лидера
g.loaded_netrw = 1 -- Отключаем netrw
g.loaded_netrwPlugin = 1

opt.number = true        -- Нумерация строк
opt.hlsearch = true      -- Подсветка найденных совпадений
opt.ignorecase = true    -- Игнорируем заглавные буквы при поиске
opt.smartcase = true     -- Если в поиске указываем заглвные буквы, то искать будет с учетом регистра
opt.termguicolors = true -- Включаем цвета для терминала

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
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/saghen/blink.cmp",               version = vim.version.range("^1") }, -- Autocomplete
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  { src = "https://github.com/hedyhli/outline.nvim" },
  { src = "https://github.com/windwp/nvim-autopairs" },
  -- Golang
  { src = "https://github.com/ray-x/go.nvim" },
  { src = "https://github.com/ray-x/guihua.lua" },
})

-------------------------
-------- Keymaps --------
-------------------------
local keymap = vim.keymap.set
local s = { silent = true }
local builtin = require('telescope.builtin')

keymap("n", "<ESC>", ":nohlsearch<CR>", s)                  -- Отмена выделения после поиска
keymap("n", "<C-w>", ":w!<CR>", s)                          -- Сохранение буфера
keymap("n", "QQ", ":qa!<CR>", s)                            -- Выход
keymap("n", "<leader>pu", ':lua vim.pack.update()<CR>')     -- Обновление плагинов
keymap("n", "<leader>r", ':so<CR>')                         -- Перезагрузить конфиг
keymap("n", "<leader>lf", vim.lsp.buf.format)               -- Форматирование с помощью lsp
keymap("n", "<leader>ca", vim.lsp.buf.code_action)          -- Форматирование с помощью lsp
keymap("n", "<leader>e", ":NvimTreeToggle<CR>")             -- Toggle NeoTree
keymap("n", "<leader>ne", ":e ~/.config/nvim/init.lua<CR>") -- Редактировать конфиг neovim

-- Telescope keymaps
keymap({ "n" }, '<leader><leader>', builtin.find_files, { desc = 'Telescope find files' })
keymap({ "n" }, '<leader>/', builtin.live_grep, { desc = 'Telescope live grep' })
keymap({ "n" }, '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
keymap({ "n" }, '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
keymap({ "n" }, "gr", builtin.lsp_references)
keymap({ "n" }, "sd", builtin.diagnostics)
keymap({ "n" }, "gi", builtin.lsp_implementations)
keymap({ "n" }, "gd", builtin.lsp_type_definitions)

keymap('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
keymap('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic' })
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Quickfix diagnostics' })
keymap('n', 'K', vim.lsp.buf.hover, { desc = 'Show documentation' })

-- Go
vim.keymap.set('n', '<leader>gg', ':GoGenerate<CR>')
vim.keymap.set('n', '<leader>gt', ':GoTest<CR>')
vim.keymap.set('n', '<leader>gf', ':GoTestFunc<CR>')
vim.keymap.set('n', '<leader>gi', ':GoImpl<CR>')
vim.keymap.set('n', '<leader>gs', ':GoFillStruct<CR>')

-- Outline symbols
keymap({ "n" }, "<leader>o", ":Outline<CR>", s)

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
vim.lsp.enable({ "lua_ls", "gopls", "clangd", "yamlls" })

require("nvim-tree").setup({
  update_focused_file = {
    enable = true,     -- автоматически выделять текущий файл
    update_cwd = true, -- обновлять рабочую директорию
  },
  renderer = {
    root_folder_label = ":t", -- показывает только имя текущей директории
  },
})

require("outline").setup({})
require("nvim-autopairs").setup({})

require("nvim-treesitter").setup({
  ensure_installed = {
    "c", "cpp", "lua", "vim", "vimdoc", "query",
    "go", "gomod", "gowork", "gosum", "python", "bash", "yaml", "json"
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = { enable = true },
  auto_install = true, -- автоматическая установка парсеров
})

require("go").setup({
  gofmt = 'gopls',
  goimport = 'gopls',
  fillstruct = 'gopls',
})

require('blink.cmp').setup({
  keymap = { preset = 'enter' },
})

------------------------------
-------- Color scheme --------
------------------------------
require("kanagawa").setup({})
vim.cmd.colorscheme("kanagawa")

-------------------------------
-------- AUTO COMMANDS --------
-------------------------------
-- lsp и триситтер конфликтуют, поэтому триситер включаем после lsp
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'gopls' then
      -- Отключаем семантические токены
      client.server_capabilities.semanticTokensProvider = nil
      -- Принудительно включаем treesitter
      vim.schedule(function()
        vim.treesitter.start()
      end)
    end
  end,
})

-- Автоматическое создание директории для undo файлов
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local undo_dir = vim.fn.stdpath("cache") .. "/undo"
    if vim.fn.isdirectory(undo_dir) == 0 then
      vim.fn.mkdir(undo_dir, "p")
    end
  end,
})

-- Автоформатирование при сохранении буфера
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.c", "*.go", "*.lua", "*.py", "*.rs", "*.js", "*.ts", "*.json", "*.yaml", "*.yml" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Установить для LineNr и SignColumn тот же фон что у Normal
-- Почти одинаковый фон с легким отличием
vim.api.nvim_set_hl(0, "LineNr", { bg = "#1f1f28", fg = "#666666" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "#1f1f28", fg = "#938aa9" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "#252530", fg = "#dcd7ba" }) -- легкое выделение


-- Сначала объявим функции
local function git_branch()
  local handle = io.popen("git branch --show-current 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    result = result:gsub("\n", "")
    if result ~= "" then
      return "   " .. result .. " "
    end
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

vim.opt.statusline = "%!v:lua.get_statusline_components()"
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
