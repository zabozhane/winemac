# winemac

Минимальный CLI-лаунчер (zsh) для Windows-игр на Mac с Apple Silicon через бесплатный Wine.
Первая цель — Windows-клиент Lineage 2 Interlude. Одна изолированная «бутылка» Wine на каждое приложение.

## Быстрый старт

```zsh
git clone https://github.com/zabozhane/winemac.git ~/winemac
~/winemac/bin/winemac setup
~/winemac/bin/winemac create l2
~/winemac/bin/winemac deps l2                      # d3dx9 vcrun2005 vcrun2008
~/winemac/bin/winemac import l2 /path/to/Interlude system/l2.exe
~/winemac/bin/winemac run l2
~/winemac/bin/winemac audit                        # что изменилось в $HOME вне ~/winemac
```

Скрипт сам ничего не прописывает в `~/.zshrc`. Если нужен короткий вызов, добавь алиас вручную:
`alias winemac=~/winemac/bin/winemac` (это будет единственный файл вне `~/winemac`, и он твой).

## Команды

| Команда | Что делает |
|---|---|
| `setup` | Проверяет Apple Silicon, ставит Rosetta 2, через Homebrew ставит `winetricks` (тянет `cabextract`, `p7zip`), скачивает закреплённую сборку Wine и проверяет её SHA-256 |
| `doctor` | Проверяет систему и каждую бутылку: нет ссылок в `$HOME`, нет диска `Z:`, `winemenubuilder` отключён, exe импортирован |
| `create <bottle>` | `wineboot --init`, отключение `winemenubuilder` в реестре, `winetricks sandbox` |
| `deps <bottle> [verbs]` | `winetricks -q`, по умолчанию `d3dx9 vcrun2005 vcrun2008` |
| `import <bottle> <dir> <exe>` | Копирует папку игры в `drive_c/Games/<имя папки>` и запоминает путь к exe |
| `run <bottle> [args]` | Запускает exe из его каталога, лог в `logs/<bottle>.log` |
| `stop <bottle>` | `wineserver -k` для бутылки |
| `list` | Список бутылок и их exe |
| `audit` | Файлы в `$HOME`, изменённые после последнего `run`, вне `~/winemac` |
| `uninstall` | Показывает всё, что будет удалено (с размерами), спрашивает подтверждение, удаляет |

## Приложение WineMac.app

Тонкая SwiftUI-оболочка над `bin/winemac`: каждая кнопка вызывает команду CLI, логика остаётся в скрипте.

```zsh
~/winemac/app/build-app.sh        # нужен Swift 5.9+ (Command Line Tools); собирает ~/winemac/WineMac.app
open ~/winemac/WineMac.app
```

| В приложении | Команда |
|---|---|
| Список игр | `list` |
| Состояние | `doctor` |
| Добавить игру | `create` (если бутылки нет) → `deps` → `import` |
| Играть / Стоп | `run` / `stop` |
| Рендер OpenGL / Vulkan | `renderer` |
| Проверить изоляцию | `audit` |
| Удалить всё | `uninstall` (список берётся из вывода CLI, ответ на `[y/N]` уходит в stdin) |

Приложение ищет `bin/winemac` рядом с собой, поэтому `.app` лежит в корне `~/winemac`. Кэши SwiftPM при сборке тоже пишутся в `cache/swiftpm`. Настройки и сохранённое состояние окон, которые macOS пишет за любое приложение в `~/Library`, перенаправлены в `state/app-home` через `CFFIXED_USER_HOME` (проверка: `winemac audit` после запуска приложения). Тесты разбора вывода CLI: `swift test --package-path ~/winemac/app`.

## Структура

```
~/winemac/
  bin/winemac                    the launcher (this repo)
  runtime/Wine Stable.app/       pinned Wine build, never touches /Applications
  bottles/<name>/prefix/         WINEPREFIX of the bottle
  bottles/<name>/exe             exe path relative to drive_c
  cache/xdg/                     XDG_CACHE_HOME (winetricks downloads)
  cache/homebrew/                HOMEBREW_CACHE
  state/xdg-config, xdg-data/    XDG_CONFIG_HOME, XDG_DATA_HOME
  state/brew-installed.txt       formulae added by setup (uninstall removes only these)
  state/last-run.marker          reference point for audit
  logs/                          per-bottle logs, HOMEBREW_LOGS
  app/                           SwiftUI app sources (this repo)
  WineMac.app/                   built by app/build-app.sh
```

Всё, кроме `bin/`, `app/`, `README.md` и `.gitignore`, создаётся скриптами и лежит в `.gitignore`.

## Изоляция

- `WINEPREFIX` — свой на каждую бутылку, `~/.wine` не создаётся.
- `winemenubuilder` отключён дважды: через `WINEDLLOVERRIDES` при каждом вызове и в реестре бутылки (на случай запуска Wine в обход winemac). Иначе Wine создаёт ярлыки и ассоциации файлов вне префикса.
- Пользовательские папки: при создании префикса Wine делает `drive_c/users/<user>/{Desktop,Documents,Downloads,...}` симлинками на настоящий `$HOME`. Verb `winetricks sandbox` заменяет их обычными папками и убирает диск `Z:` (весь корень Mac). Он же пишет `disable` в `.update-timestamp`, чтобы Wine не восстановил ссылки при обновлении префикса.
- Кэши: `XDG_*`, `HOMEBREW_CACHE`, `HOMEBREW_LOGS` указывают внутрь `~/winemac`. На macOS winetricks иначе писал бы в `~/Library/Caches/winetricks`.
- Проверка критерия «в домашней папке не появилось файлов вне `~/winemac`» — команда `audit`. macOS сама постоянно пишет в `~/Library`, поэтому в выводе будет шум; смотреть нужно на пути, связанные с Wine/winetricks.

### Что остаётся вне ~/winemac (осознанно)

- **Rosetta 2** — системный компонент; сборка Wine x86_64. Удалить её штатно нельзя.
- **Homebrew** (`/opt/homebrew`) — не ставится скриптом автоматически; если его нет, `setup` печатает официальную команду установки. `uninstall` удаляет только те формулы, которые добавил `setup`.
- **GStreamer.framework** не ставится: он нужен Wine только для мультимедиа и ставится в `/Library/Frameworks`. Если клиенту понадобится видео, вернёмся к этому.

## Почему Wine не через Homebrew-cask

Казки `wine-stable`, `wine@staging`, `wine@devel` отключены в Homebrew с 2026-09-01 (`fails_gatekeeper_check`), а возможность обходить карантин в Homebrew 5 убирают. Поэтому `setup` скачивает ту же upstream-сборку напрямую с
[Gcenx/macOS_Wine_builds](https://github.com/Gcenx/macOS_Wine_builds/releases) (`wine-stable-11.0_1-osx64.tar.xz`) и сверяет хеш. Сборка WoW64: 32-битный клиент Interlude работает без 32-битных библиотек хоста; wine-mono и wine-gecko уже внутри, в `$HOME` ничего не докачивается.

## Критерий готовности этапа 1

Клиент Interlude доходит до экрана логина, `winemac doctor` проходит без `[FAIL]`, а `winemac audit` после запуска не показывает файлов Wine/winetricks вне `~/winemac`.

## Удаление

```zsh
~/winemac/bin/winemac uninstall
```
