# no-slop + pstack для Claude Code

Набор правил, чтобы агенты Claude Code писали меньше кода, но лучше, и сами доказывали, что результат работает.

- **pstack** — плагин Lauren Tan ([cursor/plugins/pstack](https://github.com/cursor/plugins/tree/main/pstack), MIT): 58 скиллов и 2 агента. Основа — её доклад [«All Code Is Slop (Except Mine)»](https://ai.engineer/talks/O_zcc6Xl12g-all-code-is-slop-except-mine). Скиллы на английском, есть официальный адаптер для Claude Code.
- **no-slop** — короткий русский слой поверх pstack. В нём 10 правил, которые действуют всегда, таблица «задача → скилл pstack», запреты и поправки `unslop` для русских текстов. Пересказа pstack в нём нет: источник правды — сам pstack.

## Установка

Нужен Claude Code 2.1 или новее. На macOS с Homebrew достаточно одной команды:

```bash
git clone https://github.com/ensrationis/no-slop.git && ./no-slop/install.sh --claude-md
```

Установщик можно запускать повторно: то, что уже стоит, он не трогает. Он делает следующее:

1. Добавляет маркетплейс `cursor/plugins` и ставит `pstack@cursor-plugins`.
2. Копирует скилл в `~/.claude/skills/no-slop`. Если там была другая версия, она переезжает в `~/.claude/skills-backup/`: копия внутри `skills/` загрузилась бы как второй скилл.
3. Ставит `mise` и `bun` через brew, если их нет. Через `mise` скилл `statechart` сам скачивает Java и TLC, на `bun` работают `watch-pr` и скрипты `poteto-mode`.
4. С флагом `--claude-md` добавляет в `~/.claude/CLAUDE.md` правило из `claude-md-snippet.md`: применять no-slop и pstack в каждой многошаговой задаче. Перед этим делает резервную копию файла.

Флаги: `--check` только показывает, что стоит и чего нет, `--no-deps` пропускает `mise` и `bun`.

Без установщика то же делается вручную, в сессии Claude Code:

```
/plugin marketplace add cursor/plugins
/plugin install pstack@cursor-plugins
```

Затем скопировать `skill/` в `~/.claude/skills/no-slop` и вставить `claude-md-snippet.md` в `~/.claude/CLAUDE.md`.

## Использование

Если правило есть в `CLAUDE.md`, агент сам читает no-slop в начале задачи и выбирает скилл pstack по таблице. Команды можно вызывать и вручную, с префиксом `/pstack:`:

| Когда | Команда |
|---|---|
| Любая нетривиальная работа с кодом: баг, фича, рефакторинг, исследование | `/pstack:poteto-mode` |
| Сначала типы и структура модулей, потом код | `/pstack:architect` |
| Несколько вариантов параллельно, выбрать и срастить лучшее | `/pstack:arena` |
| Агент повторяет ошибку: превратить поправку в механизм | `/pstack:correct` |
| «Это точно безопасно?» | `/pstack:blast-radius` |
| Перед любыми цифрами производительности | `/pstack:benchmark-checklist` |
| Научить агента проверять своё приложение | `/pstack:create-verification-skill` |
| Гонки, повторы, машины состояний: проверка моделью TLA+ | `/pstack:statechart` |
| Долгий автономный прогон с журналом решений | `/pstack:figure-it-out`, `/pstack:show-me-your-work` |
| Попросить оппонентов сломать изменение | `/pstack:interrogate` |
| Объяснить, как устроено и почему так | `/pstack:how`, `/pstack:why`, `/pstack:teach` |
| Углубить задачу перед стартом | `/pstack:sharpen` |
| Разобрать сессию и превратить выводы в правки скиллов | `/pstack:reflect` |
| Выбрать модели под роли pstack | `/pstack:setup-pstack` |

Полный список: `claude plugin details pstack@cursor-plugins`.

## Как проверить, что всё работает

```bash
./install.sh --check
```

```bash
claude -p "/pstack:sharpen Add a retry to the HTTP client"
```

Вторая команда должна вернуть разбор задачи из четырёх пунктов. Проверка `statechart`: на примере из комплекта он должен вернуть код 0, на примере с ошибкой — код 1 и кратчайший путь к нарушению.

```bash
S=$(ls -d ~/.claude/plugins/cache/cursor-plugins/pstack/*/skills/statechart | tail -1); D=$(mktemp -d); cp $S/scripts/test/corpus/MediaPlayer/* $D/ && cd $D && $S/scripts/statechart MediaPlayer.tla; echo "exit=$?"
```

## Обновление

```bash
claude plugin update pstack@cursor-plugins
```

```bash
git -C no-slop pull && ./no-slop/install.sh
```

## Что не работает в Claude Code

Шаги, которым нужны Cursor Automations, Bugbot или облачные агенты Cursor, скиллы пропускают и пишут об этом одной строкой. Как остальные имена Cursor переводятся на Claude Code, описано в адаптере pstack `docs/harness/claude-code.md`.
