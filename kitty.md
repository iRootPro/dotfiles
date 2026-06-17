# Kitty Configuration

Конфиг: `~/.config/kitty/kitty.conf` | Тема: Catppuccin Mocha (`current-theme.conf`)

Kitty используется как быстрый терминал, а окна/сессии управляются через tmux. Большинство `Cmd`-хоткеев отправляют tmux prefix (`Ctrl+B`) и команду.

## Хоткеи

### Табы

| Хоткей | Действие |
|--------|----------|
| `Cmd+T` | Новое окно tmux в текущей директории |
| `Cmd+W` | Smart close: pane → window → session |
| `Cmd+N` | Новая tmux-сессия |
| `Cmd+K` | Выбор tmux/sesh-сессии |
| `Cmd+O` | Выбор tmux/sesh-сессии |
| `Cmd+P` | Выбор tmux-окна |
| `Cmd+Shift+P` | Command palette: список tmux/dotfiles/opencode действий |
| `Cmd+Y` | Запустить opencode-сессию для текущей директории |
| `Cmd+U` | Список opencode-сессий |
| `Cmd+1-9` | Перейти на tmux-окно по номеру |
| `Cmd+0` | Перейти на tmux-окно 10 |
| `Cmd+]` / `Cmd+[` | Следующее / предыдущее tmux-окно |
| `Cmd+Shift+]` / `Cmd+Shift+[` | Переместить tmux-окно вправо / влево |

Command palette: `Enter` запускает выбранное действие, `Esc` / `q` / `Ctrl-C` закрывают без действия. Для long-running команд popup сохраняет полный лог и после выполнения автоматически открывает его в `less`; скролль для просмотра, `q` закрывает popup.

### Сплиты

| Хоткей | Действие |
|--------|----------|
| `Cmd+E` | Горизонтальный tmux-сплит (снизу) |
| `Cmd+Shift+E` | Вертикальный tmux-сплит (справа) |
| `Cmd+H` | Перейти влево |
| `Cmd+J` | Перейти вниз |
| `Cmd+L` | Перейти вправо |

### Редактор

| Хоткей | Действие |
|--------|----------|
| `Cmd+S` | Сохранить в Neovim (отправляет `:write`) |
| `Shift+Enter` | Alt+Enter (для TUI-приложений) |

### Стандартные (встроенные)

| Хоткей | Действие |
|--------|----------|
| `Cmd+C` | Копировать |
| `Cmd+V` | Вставить |
| `Cmd+N` | Новое окно |
| `Cmd+Q` | Выйти |
| `Cmd+Ctrl+F5` | Перезагрузить конфиг |
| `Cmd++` / `Cmd+-` | Увеличить / уменьшить шрифт |
| `Cmd+0` (без табов) | Сбросить размер шрифта |

## Настройки

| Параметр | Значение | Зачем |
|----------|----------|-------|
| Shell | `fish` | Запускает fish вместо дефолтного шелла |
| Шрифт | MesloLGLDZ Nerd Font Mono, 14pt | Nerd Font для иконок в starship/nvim |
| Курсор | Block | Блочный курсор |
| Декорации окна | Скрыты | Чистый вид без titlebar |
| Padding | 4px | Отступ контента от краёв |
| Option as Alt | Да | Option работает как Alt в терминале |
| Scrollback | 10 000 строк | История прокрутки |
| Звук | Выключен | Без звуковых уведомлений |
| Remote control | socket-only | Доступ через `kitty @` только по unix-сокету |
| Clipboard | OSC 52 no-append | Корректная синхронизация буфера из tmux |

## Табы

Нативные kitty-табы скрыты через высокий `tab_bar_min_tabs`: рабочая модель построена вокруг tmux windows/sessions, чтобы не было двух конкурирующих tab bars.

## Тема

Catppuccin Mocha подключается через `current-theme.conf`. Это же семейство используется в tmux, starship и Neovim.

Сменить тему:
```
include current-theme.conf
```

## Remote control

Позволяет управлять kitty из скриптов через `kitty @`:

```bash
kitty @ set-font-size 16
kitty @ new-tab
kitty @ send-text "hello"
```

Работает только через unix-сокет (`/tmp/kitty-{pid}`), внешние процессы без доступа к сокету управлять не могут.
