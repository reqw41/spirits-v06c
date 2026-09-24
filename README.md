# Spirits — порт на Вектор-06Ц

Игра [Spirits](https://www.msx.org/software/games/adventure/spirits)
(Topo Soft / Erbe, 1987, MSX) на ванильном **Векторе-06Ц** (КР580ВМ80А /
i8080). Без Z80-переходника.

Этот репозиторий — **только сборка порта**: исходники адаптера, дизасм
MSX с комментариями, рекомпилятор Z80→i8080 и скрипты, которые собирают
ROM. Исследовательские журналы, стенды сверки с MSX и прочие порты сюда
не входят.

## Что внутри

```
disasm/msx/orig/   дизасм оригинала MSX (с комментариями)
disasm/msx/v06/    тот же код в раскладке Вектора (вход рекомпилятора)
src/v06/           адаптер экрана, ввода, звука, заставка, читы
src/i8080/         рекомпилированный код игры + runtime-хелперы
ref/msx/orig/      payload кассеты (для round-trip)
ref/title/         картинка заставки
tools/             сборка и рекомпиляция
docs/              геймплей, читы, справка, рекомпиляция
```

Готовый образ: `build/port/spirits-port-i8080.rom`.

## Зависимости

- Python 3
- **zasm 4.5** с ключом `--8080`

Путь к ассемблеру — переменная `ZASM` (по умолчанию
`~/projects/kvalley-v06c/tools/bin/sjasm`, это zasm под другим именем):

```sh
export ZASM=/path/to/zasm   # или sjasm
```

## Сборка

Из корня:

```sh
# 1. блоки игры в раскладке Вектора
python3 tools/verify_v06.py --write

# 2. адаптер ввода/звука
sh tools/build_adapter.sh

# 3. заставка
python3 tools/mk_title.py

# 4. Z80 → i8080 (нужен build/analysis/prof-z80.json — уже в репо)
python3 tools/i8080_dead.py --write
python3 tools/recompile_i8080.py

# 5. образ адаптера + полный порт
python3 tools/build_v06_rom.py  --cpu i8080
python3 tools/build_port_rom.py --cpu i8080
```

Без `--cpu` собирается эталон Z80 (для сравнения). Подробности метода —
[`docs/recompilation.md`](docs/recompilation.md).

## Документация

| файл | о чём |
|------|--------|
| [docs/gameplay.md](docs/gameplay.md) | как играть |
| [docs/cheats.md](docs/cheats.md) | чит-коды |
| [docs/help-page-ru.md](docs/help-page-ru.md) | текст справки в ROM |
| [docs/v06-input-sound.md](docs/v06-input-sound.md) | клавиатура и звук |
| [docs/recompilation.md](docs/recompilation.md) | Z80 → i8080 |
| [docs/known-issues.md](docs/known-issues.md) | известные отличия |
| [docs/RESOURCES.md](docs/RESOURCES.md) | откуда бинарники |

## Лицензия

Код порта и инструментов — см. [LICENSE](LICENSE). Оригинальная игра
Spirits принадлежит правообладателям Topo Soft / Erbe; см. [NOTICE](NOTICE).
