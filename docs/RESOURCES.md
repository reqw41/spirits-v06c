# Карта ресурсов и исходников

Назначение каталогов и ключевых файлов. Шапки модулей в `src/v06/*.asm`
описывают контракт каждого адаптера; здесь — где что искать с порога.

---

## `src/` — код порта

### `src/v06/` — пишется руками, подмножество i8080

В шапках файлов — контракт и карта. Ориентиры:

| Файл | Роль | Где смотреть «что где» |
|---|---|---|
| `boot.asm` | Точка входа ROM `0x0100` → экранный адаптер | весь файл (9 строк) |
| `screen_adapter.asm` | Экран и спрайты | **КАРТА ФАЙЛА** в шапке; `SCR_INIT`, `A_ROOMDRAW`, `A_HERO` |
| `adapter.asm` | Ввод и звук: includes + ячейки ОЗУ | список `.include` у `org 4A00` |
| `kbd.asm` | Клавиатура → тень MSX | фазы `(1)..(6)` в `V_KBD_POLL` |
| `joy.asm` | Джойстик порт `0x0E` | таблица битов у `V_JOY_RD` |
| `snd.asm` | AY → ВИ53 | шапка + `V_PSG_WR` / `V_SND_TICK` |
| `glue.asm` | Старт партии и IRQ 50 Гц | `V_START`, `V_ISR`, `V_JOY_PACE` |
| `title.asm` | Заставка и справка | `T_HELP`, `T_WAITKEY` |
| `cheat.asm` | Читы (потребители фронтов) | `V_CHEAT_MOVE` / `ENER` / `DEATH` |
| `room_pal*.inc`, `bank_ptr.inc` | Палитры / указатели банков | генерируются tools |
| `scheme.inc`, `cpu.inc`, `game_labels.inc` | Схема цвета и метки игры | сборка (в `.gitignore`) |

Сборка адаптера: `tools/build_v06_rom.py`, полного порта —
`tools/build_port_rom.py`.

### `src/i8080/` — GENERATED

| Файл | Роль |
|---|---|
| `game.asm` | Вся игра после `tools/recompile_i8080.py` (не править руками) |
| `rt.asm` | Копия рантайм-хелперов для чтения; карта `il_*` в шапке; в образе они внутри `game.asm` |

Метод — [`recompilation.md`](recompilation.md).

---

## `disasm/msx/` — дизассемблер игры

| Путь | Раскладка |
|---|---|
| `spirits1.asm`, `spirits2.asm`, `resident.asm`, `himem.asm` | Канон `+0x100` |
| `orig/` | Оригинал `9000` / `82A0` / `D000` / `E04B` — **база порта** |
| `v06/` | Раскладка Вектора (`02A0` / `0489` / …) — вход рекомпилятора |
| `reshift/` | Обратная сборка на `+0x100` только для проверки |

Генератор: `tools/disasm_msx.py`. Round-trip: `tools/verify_disasm.py`,
`verify_orig.py`, `verify_v06.py`.

---

## `tools/` — конвейер

| Группа | Примеры |
|---|---|
| Сборка ROM | `build_v06_rom.py`, `build_port_rom.py`, `build_adapter.sh` |
| Рекомпиляция | `recompile_i8080.py`, `i8080_dead.py`, `check_i8080.py`, `verify_i8080.py` |
| Дизасм / аудит | `disasm_msx.py`, `verify_*.py`, `relocation_audit.py`, `entries.json` |
| Гейты Вектора | `block_equiv_v06js.js`, `playthrough_v06js.js`, `allrooms_v06js.js`, `prof_pc_v06js.js` |
| Сверка с MSX | `cmp_hero_msx.py`, `cmp_allrooms_msx.py`, `cmp_color_msx.py`, `openmsx/` |
| Картинка / звук | `title_native_v06js.js`, `objetos_v06js.js`, `shot_lustra_v06js.js`, `snd_*.py` |
| Прочее | `mk_title.py`, `mk_help.py`, `i18n_ru.py`, `emu80_run.sh`, `mister_run.sh` |

Каталог `build/` coздаётся инструментами и **не коммитится**.

---

## `ref/` — эталоны оригинала

| Путь | Содержимое |
|---|---|
| `ref/msx/SPIRITS.*.payload` | Канон с диска (`+0x100`) |
| `ref/msx/orig/` | Восстановленный оригинал без стухших адресов |
| `ref/msx/Spirits-1987-TopoSoft-ES.tsx` | Кассета — эталон сверки |
| `ref/msx/spirits.dsk`, `files/` | Диск и файлы BLOAD |
| `ref/msx/rom/` | Картриджные образы для сверок (если есть) |
| `ref/zx/`, `ref/cpc/` | Spectrum / CPC для поведения и таблиц |
| `ref/manual/web/` | Тексты инструкции и обзоров |
| `ref/manual/SOURCE.md` | Откуда взяты тексты; сканы TIFF **не в git** |
| `ref/title/` | Референсы заставки |

Дампы нужны для воспроизводимой сборки и гейтов; правовой статус —
[NOTICE](../NOTICE).

---

## `docs/`, `data/`

- `docs/` — записки порта; индекс [README.md](README.md).
- `data/object-marks.json` — разметка объектов для инструментов анализа.

---

## Что не в git

| Путь | Почему |
|---|---|
| `build/` | Артефакты сборки и снимки стендов |
| `ref/manual/**/*.tif` | Тяжёлые сканы обложки/кассеты (~30 МБ) |
| `ref/msx/scans-*.rar` | Архив сканов издания |
| `*.lst`, `src/v06/{scheme,cpu,game_labels}.inc` | Выход ассемблера / генераторов |
| `/lustra/`, `/native/`, `/ru/`, … | Локальные worktree веток (см. `.gitignore`) |
