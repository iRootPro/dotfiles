# Neovim Configuration

Конфиг: `~/.config/nvim/init.lua` | Тема: kanagawa | Менеджер плагинов: vim.pack | Neovim 0.12+

## Плагины

| Плагин | Назначение |
|--------|-----------|
| kanagawa.nvim | Цветовая схема |
| nvim-treesitter | Установка и управление парсерами |
| snacks.nvim | Picker (файлы, grep, буферы), Explorer (дерево файлов) |
| blink.cmp | Автодополнение (Enter для выбора) |
| outline.nvim | Панель символов (функции, структуры) |
| nvim-autopairs | Автозакрытие скобок и кавычек |
| gitsigns.nvim | Git-знаки в gutter, навигация по hunkам, blame |
| conform.nvim | Форматирование при сохранении (goimports, stylua, prettier...) |
| oil.nvim | Редактирование файловой системы как буфер |
| which-key.nvim | Popup с описаниями хоткеев при нажатии Leader |
| nvim-web-devicons | Иконки для файлов |
| nvim-dap | Debug Adapter Protocol — клиент для дебаггеров |
| nvim-dap-go | Автоконфигурация DAP для Go (delve) |
| nvim-dap-ui | Визуальный UI для дебага (переменные, стек, breakpoints) |
| nvim-nio | Async IO библиотека (зависимость dap-ui) |

## Хоткеи

### Основные

| Хоткей | Действие |
|--------|----------|
| `Space` | Leader |
| `Ctrl+W` | Сохранить |
| `QQ` | Выйти без сохранения |
| `ESC` | Убрать подсветку поиска |
| `K` | Документация по символу (hover) — встроенный |
| `Leader r` | Перезагрузить конфиг |
| `Leader ne` | Открыть конфиг neovim для редактирования |
| `Leader pu` | Обновить плагины |

### Файлы и поиск (snacks.nvim)

| Хоткей | Действие |
|--------|----------|
| `Leader Leader` | Поиск файлов |
| `Leader /` | Поиск по содержимому (live grep) |
| `Leader fb` | Открытые буферы |
| `Leader fh` | Поиск по справке |
| `Leader sd` | Поиск по диагностике |
| `Leader e` | Открыть/закрыть дерево файлов (explorer) |
| `-` | Открыть родительскую директорию (oil.nvim) |
| `Leader o` | Открыть/закрыть панель символов |

### LSP и код (встроенные 0.12 + кастомные)

| Хоткей | Действие | Источник |
|--------|----------|----------|
| `gd` | Перейти к определению | кастомный |
| `gD` | Перейти к объявлению | кастомный |
| `grr` | Показать все ссылки | встроенный 0.12 |
| `gri` | Показать реализации интерфейса | встроенный 0.12 |
| `grt` | Перейти к определению типа | встроенный 0.12 |
| `grn` | Переименовать символ | встроенный 0.12 |
| `gra` | Code action | встроенный 0.12 |
| `grx` | Запуск code lens | встроенный 0.12 |
| `gO` | Символы документа | встроенный 0.12 |
| `Ctrl+S` (insert) | Signature help | встроенный 0.12 |
| `Leader lf` | Форматировать файл (conform) | кастомный |
| `Leader ld` | Показать диагностику в popup | кастомный |
| `Leader q` | Диагностика в quickfix | кастомный |

### Git (gitsigns)

| Хоткей | Действие |
|--------|----------|
| `]c` | Следующий hunk |
| `[c` | Предыдущий hunk |
| `Leader hs` | Stage hunk |
| `Leader hr` | Reset hunk |
| `Leader hu` | Undo stage hunk |
| `Leader hp` | Preview hunk |
| `Leader hb` | Blame line |

### Go-разработка

| Хоткей | Действие |
|--------|----------|
| `Leader gg` | go generate |
| `Leader gt` | go test |
| `Leader gf` | Тест текущей функции |
| `Leader gi` | Имплементировать интерфейс |
| `Leader gs` | Заполнить struct |

### Дебаг (nvim-dap + delve)

Требуется: `go install github.com/go-delve/delve/cmd/dlv@latest`

| Хоткей | Действие |
|--------|----------|
| `Leader db` | Поставить/убрать breakpoint |
| `Leader dt` | Дебаг ближайшего теста |
| `Leader dl` | Дебаг последнего теста |
| `Leader du` | Показать/скрыть DAP UI |
| `Leader dx` | Остановить дебаг |

Во время активной дебаг-сессии включаются однокнопочные кейбинды:

| Клавиша | Действие |
|---------|----------|
| `n` | Step over (следующая строка) |
| `s` | Step into (войти в функцию) |
| `o` | Step out (выйти из функции) |
| `c` | Continue (до следующего breakpoint) |
| `x` | Terminate (завершить сессию) |

При завершении дебага кейбинды автоматически снимаются.

### Выделение (встроенные 0.12)

| Хоткей | Режим | Действие |
|--------|-------|----------|
| `an` | Visual | Расширить выделение (treesitter node) |
| `in` | Visual | Сузить выделение (treesitter node) |

### Окна и сплиты

| Хоткей | Действие |
|--------|----------|
| `Ctrl+H/J/K/L` | Навигация между сплитами |
| `Leader vs` | Вертикальный сплит |
| `Leader hs` | Горизонтальный сплит |
| `Leader wt` | Развернуть/свернуть окно |
| `Leader wc` | Закрыть окно |
| `Leader wo` | Закрыть все остальные окна |

### Документация

| Хоткей | Действие |
|--------|----------|
| `Leader ?` | README dotfiles |
| `Leader ?n` | Документация Neovim |
| `Leader ?z` | Документация Zsh |
| `Leader ?k` | Документация Kitty |

## LSP-серверы

Настроены через `vim.lsp.config()` + `vim.lsp.enable()` (без nvim-lspconfig):

| Сервер | Язык | Особенности |
|--------|------|-------------|
| gopls | Go | gofumpt, staticcheck, analyses (unusedparams, shadow), semantic tokens отключены |
| lua_ls | Lua | LuaJIT runtime, workspace = neovim runtime files |
| clangd | C/C++ | |
| yamlls | YAML | |

## Форматирование (conform.nvim)

Автоформат при сохранении. Если нет форматтера — fallback на LSP.

| Язык | Форматтер |
|------|-----------|
| Go | goimports + gofmt |
| Lua | stylua |
| Python | ruff (fallback: black) |
| C/C++ | clang-format |
| JS/TS | prettier |
| JSON/YAML | prettier |
| Rust | rustfmt |

## Настройки

| Параметр | Значение |
|----------|----------|
| Отступы | 2 пробела |
| Нумерация строк | Да |
| Системный буфер обмена | Да |
| Undo | Бесконечный (между сессиями) |
| Swap-файлы | Отключены |
| Прокрутка | Отступ 8 строк от края |
| Подсветка курсора | Линия |
| Бордеры окон | Закруглённые |
| Пробелы в конце строк | `·` |

## Treesitter

Парсеры: C, C++, Lua, Vim, Vimdoc, Query, Go (go/gomod/gowork/gosum), Python, Bash, YAML, JSON.
Подсветка через нативный `vim.treesitter.start()` (FileType autocmd).

## Statusline

Кастомный (без lualine), глобальный (`laststatus = 3`):

```
[OS] MODE | filename [+] [git branch] [ERR N] [WARN N]          ICON FILETYPE
```

Git-ветка через `vim.b.gitsigns_head` (без subprocess).
