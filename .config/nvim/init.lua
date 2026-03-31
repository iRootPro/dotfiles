-----------------------
-------- Опции --------
-----------------------
local opt = vim.opt
local g = vim.g

g.mapleader = " " -- Установка лидера
g.loaded_netrw = 1 -- Отключаем netrw
g.loaded_netrwPlugin = 1

opt.number = true -- Нумерация строк
opt.hlsearch = true -- Подсветка найденных совпадений
opt.ignorecase = true -- Игнорируем заглавные буквы при поиске
opt.smartcase = true -- Если в поиске указываем заглвные буквы, то искать будет с учетом регистра
opt.termguicolors = true -- Включаем цвета для терминала

-- Настройка отступов
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Прокрутка начинается за 8 строк до конца
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.updatetime = 50 -- Быстрое обновление lsp
opt.clipboard:append({ "unnamed", "unnamedplus" }) -- Использование системного буфера
opt.undodir = vim.fn.stdpath("cache") .. "/undo" -- Включаем бесконечные undo операции
opt.undofile = true

opt.swapfile = false -- Отключим swapfile
opt.list = true -- Подсвечивать пробелы в конце
opt.listchars = { tab = "  ", trail = "·", extends = ">", precedes = "<" }
opt.cursorline = true -- Показывать подсветку курсора линией
opt.winborder = "rounded" -- Оформление подсказок с закруглениями
opt.pumborder = "rounded" -- Рамка у popup-меню автодополнения (0.12)

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
	{ src = "https://github.com/nvim-tree/nvim-tree.lua" },
	{ src = "https://github.com/ibhagwan/fzf-lua" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" }, -- зависимость neotest
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") }, -- Autocomplete
	{ src = "https://github.com/hedyhli/outline.nvim" },
	{ src = "https://github.com/windwp/nvim-autopairs" },
	-- Git
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	-- Debug
	{ src = "https://github.com/mfussenegger/nvim-dap" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui" },
	{ src = "https://github.com/leoluz/nvim-dap-go" },
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
	-- Test
	{ src = "https://github.com/nvim-neotest/neotest" },
	{ src = "https://github.com/fredrikaverpil/neotest-golang" },
	-- Snippets
	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	-- Navigation
	{ src = "https://github.com/folke/flash.nvim" },
	-- Diagnostics
	{ src = "https://github.com/folke/trouble.nvim" },
	{ src = "https://github.com/folke/todo-comments.nvim" },
	-- Git
	{ src = "https://github.com/sindrets/diffview.nvim" },
	-- UI
	{ src = "https://github.com/folke/which-key.nvim" },
})

-------------------------
-------- Keymaps --------
-------------------------
local keymap = vim.keymap.set
local fzf = require("fzf-lua")

keymap("n", "<ESC>", ":nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })
keymap("n", "<C-s>", ":w!<CR>", { silent = true, desc = "Save buffer" })
keymap("n", "QQ", ":qa!<CR>", { silent = true, desc = "Quit all" })
keymap("n", "<leader>pu", ":lua vim.pack.update()<CR>", { desc = "Update plugins" })
keymap("n", "<leader>r", ":so<CR>", { desc = "Reload config" })
keymap("n", "<leader>lf", vim.lsp.buf.format, { desc = "LSP format" })
keymap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })
keymap("n", "<leader>ne", ":e ~/.config/nvim/init.lua<CR>", { desc = "Edit neovim config" })
keymap("n", "<leader>u", "<cmd>Undotree<CR>", { desc = "Undo tree (0.12)" })

-- Flash (быстрая навигация)
keymap({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash jump" })
keymap({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash treesitter" })

-- FZF keymaps
keymap("n", "<leader><leader>", fzf.files, { desc = "Find files" })
keymap("n", "<leader>/", fzf.live_grep, { desc = "Live grep" })
keymap("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
keymap("n", "<leader>fh", fzf.helptags, { desc = "Help tags" })
keymap("n", "gr", fzf.lsp_references, { desc = "LSP references" })
keymap("n", "sd", fzf.diagnostics_document, { desc = "Search diagnostics" })
keymap("n", "gI", fzf.lsp_implementations, { desc = "Go to implementations" })
keymap("n", "gd", fzf.lsp_definitions, { desc = "Go to definition" })
keymap("n", "gD", fzf.lsp_typedefs, { desc = "Go to type definition" })

keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
keymap("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
keymap("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Quickfix diagnostics" })
keymap("n", "K", vim.lsp.buf.hover, { desc = "Show documentation" })

-- Git
keymap("n", "<leader>gg", function()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.98)
	local height = math.floor(vim.o.lines * 0.98)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	})
	vim.fn.termopen("lazygit", {
		on_exit = function()
			vim.api.nvim_buf_delete(buf, { force = true })
		end,
	})
	vim.cmd("startinsert")
end, { desc = "Lazygit" })

-- Go
keymap("n", "<leader>gG", function()
	vim.cmd("botright vsplit | terminal go generate ./...")
	vim.cmd("startinsert")
end, { desc = "Go generate" })
keymap("n", "<leader>gs", vim.lsp.buf.code_action, { desc = "Go fill struct (code action)" })
keymap("n", "<leader>gi", function()
	local type_name = vim.fn.input("Type: ")
	if type_name == "" then return end
	local iface = vim.fn.input("Interface: ")
	if iface == "" then return end
	local result = vim.fn.system("impl '" .. type_name .. "' " .. iface)
	if vim.v.shell_error ~= 0 then
		vim.notify("impl error: " .. result, vim.log.levels.ERROR)
		return
	end
	local pos = vim.api.nvim_win_get_cursor(0)
	local lines = vim.split(result, "\n")
	vim.api.nvim_buf_set_lines(0, pos[1], pos[1], false, lines)
end, { desc = "Go implement interface" })

-- Debug (DAP)
local dap = require("dap")
local dapui = require("dapui")
keymap("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
keymap("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional breakpoint" })
keymap("n", "<leader>dc", dap.continue, { desc = "Continue / Start" })
keymap("n", "<leader>di", dap.step_into, { desc = "Step into" })
keymap("n", "<leader>do", dap.step_over, { desc = "Step over" })
keymap("n", "<leader>dO", dap.step_out, { desc = "Step out" })
keymap("n", "<leader>dx", dap.terminate, { desc = "Terminate" })
keymap("n", "<leader>du", function() dapui.toggle() end, { desc = "Toggle DAP UI" })

-- Test (Neotest)
local neotest = require("neotest")
keymap("n", "<leader>tt", function() neotest.run.run() end, { desc = "Run nearest test" })
keymap("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "Run file tests" })
keymap("n", "<leader>ts", function() neotest.summary.toggle() end, { desc = "Toggle test summary" })
keymap("n", "<leader>to", function() neotest.output_panel.toggle() end, { desc = "Toggle test output" })
keymap("n", "<leader>td", function() neotest.run.run({ strategy = "dap" }) end, { desc = "Debug nearest test" })

-- Trouble (diagnostics)
keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics (project)" })
keymap("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Diagnostics (buffer)" })
keymap("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", { desc = "Location list" })
keymap("n", "<leader>xq", "<cmd>Trouble qflist toggle<CR>", { desc = "Quickfix list" })
keymap("n", "<leader>xt", "<cmd>Trouble todo toggle<CR>", { desc = "TODOs" })

-- Todo-comments
keymap("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next TODO" })
keymap("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Previous TODO" })
keymap("n", "<leader>ft", "<cmd>TodoFzfLua<CR>", { desc = "Search TODOs" })

-- Diffview
keymap("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Git diff" })
keymap("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "File git history" })
keymap("n", "<leader>gH", "<cmd>DiffviewFileHistory<CR>", { desc = "Branch git history" })
keymap("n", "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" })

-- Outline symbols
keymap({ "n" }, "<leader>o", ":Outline<CR>", { silent = true, desc = "Toggle outline" })

-- Навигация между сплитами
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to bottom window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to top window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Работа со сплитами
keymap("n", "<Leader>vs", "<C-w>v", { desc = "Vertical split" })
keymap("n", "<Leader>hs", "<C-w>s", { desc = "Horizontal split" })
keymap("n", "<Leader>wt", function()
	if vim.g.window_maximized then
		vim.cmd("wincmd =")
		vim.g.window_maximized = false
	else
		vim.cmd("wincmd _ | wincmd |")
		vim.g.window_maximized = true
	end
end, { desc = "Toggle maximize window" })

-- Закрытие окон
keymap("n", "<Leader>wc", "<C-w>c", { desc = "Close window" })
keymap("n", "<Leader>wo", "<C-w>o", { desc = "Close other windows" })

---------------------
-------- LSP --------
---------------------
vim.lsp.config("gopls", {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gosum" },
	root_markers = { "go.mod", "go.work", ".git" },
	settings = {
		gopls = {
			gofumpt = true,
			analyses = {
				unusedparams = true,
				shadow = true,
			},
			staticcheck = true,
		},
	},
})

vim.lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
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

require("nvim-tree").setup({
	update_focused_file = {
		enable = true, -- автоматически выделять текущий файл
		update_cwd = true, -- обновлять рабочую директорию
	},
	renderer = {
		root_folder_label = ":t", -- показывает только имя текущей директории
	},
})

require("outline").setup({})
require("nvim-autopairs").setup({})

require("nvim-treesitter").setup({})

-- Установка парсеров (если ещё не установлены)
local parsers_to_install = {
	"c", "cpp", "lua", "vim", "vimdoc", "query",
	"go", "gomod", "gowork", "gosum",
	"python", "bash", "yaml", "json",
}
local to_install = vim.tbl_filter(function(p)
	return not pcall(vim.treesitter.language.inspect, p)
end, parsers_to_install)
if #to_install > 0 then
	vim.treesitter.install(to_install)
end

require("blink.cmp").setup({
	keymap = { preset = "enter" },
	snippets = { preset = "default" },
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
})

require("gitsigns").setup({})
require("which-key").setup({})
require("flash").setup({})
require("trouble").setup({})
require("todo-comments").setup({})

-- DAP
require("dap-go").setup()
require("nvim-dap-virtual-text").setup({})
local dapui = require("dapui")
dapui.setup({})
-- Автоматически открывать/закрывать DAP UI при старте/остановке отладки
local dap = require("dap")
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- Neotest
require("neotest").setup({
	adapters = {
		require("neotest-golang"),
	},
})

-- Snippets (friendly-snippets загружаются автоматически через blink.cmp)
vim.g.blink_cmp_snippets = true

------------------------------
-------- Color scheme --------
------------------------------
require("kanagawa").setup({})
vim.cmd.colorscheme("kanagawa")

-------------------------------
-------- AUTO COMMANDS --------
-------------------------------
-- lsp и триситтер конфликтуют, поэтому триситер включаем после lsp
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then return end

		-- Подсветка переменной под курсором во всех местах использования
		if client:supports_method("textDocument/documentHighlight") then
			local buf = args.buf
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = buf,
				callback = vim.lsp.buf.clear_references,
			})
		end

		if client.name == "gopls" then
			-- Отключаем семантические токены
			client.server_capabilities.semanticTokensProvider = nil
			-- Принудительно включаем treesitter
			vim.schedule(function()
				pcall(vim.treesitter.start)
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
	pattern = { "*.go" },
	callback = function()
		-- Организация импортов через gopls
		local params = vim.lsp.util.make_range_params(0, "utf-16")
		params.context = { only = { "source.organizeImports" } }
		local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
		for _, res in pairs(result or {}) do
			for _, action in pairs(res.result or {}) do
				if action.edit then
					vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
				end
			end
		end
		vim.lsp.buf.format({ async = false })
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.c", "*.lua", "*.py", "*.rs", "*.js", "*.ts", "*.json", "*.yaml", "*.yml" },
	callback = function()
		vim.lsp.buf.format({ async = false })
	end,
})

-- Подсветка текущего семантического блока при задержке курсора
local scope_ns = vim.api.nvim_create_namespace("scope_highlight")
local scope_types = {
	function_declaration = true, method_declaration = true, func_literal = true,
	if_statement = true, for_statement = true, short_var_declaration = true,
	type_declaration = true, type_spec = true,
	-- общие для многих языков
	function_definition = true, if_expression = true, for_expression = true,
}

vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.api.nvim_buf_clear_namespace(0, scope_ns, 0, -1)
		local ok, node = pcall(vim.treesitter.get_node)
		if not ok or not node then return end
		while node do
			if scope_types[node:type()] then
				local sr, _, er, _ = node:range()
				for line = sr, er do
					vim.api.nvim_buf_add_highlight(0, scope_ns, "ScopeHighlight", line, 0, -1)
				end
				break
			end
			node = node:parent()
		end
	end,
})

vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
	callback = function()
		vim.api.nvim_buf_clear_namespace(0, scope_ns, 0, -1)
	end,
})

-- Установить для LineNr и SignColumn тот же фон что у Normal
-- Почти одинаковый фон с легким отличием
vim.api.nvim_set_hl(0, "LineNr", { bg = "#1f1f28", fg = "#666666" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "#1f1f28", fg = "#938aa9" })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "#252530", fg = "#dcd7ba" }) -- легкое выделение
vim.api.nvim_set_hl(0, "ScopeHighlight", { bg = "#252530" }) -- подсветка семантического блока

-- Сначала объявим функции
local function git_branch()
	local branch = vim.b.gitsigns_head
	if branch and branch ~= "" then
		return "   " .. branch .. " "
	end
	return ""
end

local function lsp_diagnostics()
	local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })

	local result = ""
	if errors > 0 then
		result = result .. " [ERR " .. errors .. "] "
	end
	if warnings > 0 then
		result = result .. " [WARN " .. warnings .. "] "
	end

	return result
end

local function lsp_progress()
	local status = vim.ui.progress_status()
	if status and status ~= "" then
		return "  " .. status .. " "
	end
	return ""
end

local function filetype_info()
	local ft = vim.bo.filetype
	if ft == "" then
		return ""
	end

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

	local icon = icons[ft] or "" -- файл по умолчанию
	return icon .. " " .. ft:upper()
end

local function os_logo()
	if vim.fn.has("mac") == 1 then
		return " "
	elseif vim.fn.has("unix") == 1 then
		return " "
	elseif vim.fn.has("win32") == 1 then
		return " "
	elseif vim.fn.has("bsd") == 1 then
		return " "
	else
		return " "
	end
end

vim.opt.statusline = "%!v:lua.get_statusline_components()"
-- Делаем функции глобальными для доступа из statusline
_G.git_branch = git_branch
_G.lsp_diagnostics = lsp_diagnostics
_G.lsp_progress = lsp_progress
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
	.. "%{v:lua.lsp_progress()}" -- прогресс LSP (0.12)
	.. " %=" -- выравнивание вправо
	.. "%#StatusLine#" -- правая часть
	.. " %{v:lua.filetype_info()} "
	.. "%#StatusLineNC#" -- разделитель
-- Цвета
vim.api.nvim_set_hl(0, "StatusLine", { bg = "#1f1f28", fg = "#dcd7ba" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#1f1f28", fg = "#727169" })

-- Экспериментальный UI для сообщений и командной строки (0.12)
-- Убирает "Press ENTER", пейджер как буфер, подсветка командной строки
pcall(function() require("vim._core.ui2").enable() end)
