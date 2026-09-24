import os
#!/usr/bin/env python3
"""Собрать .rom Вектора-06Ц: блоки игры (build/v06) + адаптер экрана.

  python3 tools/build_v06_rom.py                  -> build/adapter/spirits.rom
                                                     (ОСНОВНАЯ схема «2 + 1»)
  python3 tools/build_v06_rom.py --scheme exolon  -> build/adapter/spirits-exolon.rom

СХЕМА ЦВЕТА выбирается ключом --scheme и передаётся ассемблеру ЕДИНСТВЕННЫМ
способом, который у zasm есть, — через генерируемый include src/v06/scheme.inc
(ключа -D у zasm 4.5.0 нет).  ОСНОВНАЯ схема — «2 + 1» (cpc21), решение
владельца 2026-09-22 (docs/adapter-requirements.md, § 0c); «Exolon» осталась
переключателем и кладётся в отдельные файлы с суффиксом -exolon, чтобы
листинг одной схемы не затирал листинг другой.

Образ .rom грузится с 0x0100 и с 0x0100 же стартует.  Раскладка —
docs/v06-memory.md:
    0100..029F  стартовый код порта   (src/v06/boot.asm)
    02A0..43C5  блок игры             (build/v06/v06-low.bin)
    43C6..49FF  РАБОЧАЯ ОБЛАСТЬ ИГРЫ: теневые таблицы спрайтов и заворот,
                класть сюда ничего нельзя (docs/v06-memory.md, § 8)
    4A00..4C92  адаптер ввода и звука (src/v06/adapter.asm, отдельно)
    4E00..4E54  связка                (src/v06/glue.asm, отдельно)
    4EAA..4F21  таблица звуковых эффектов (build/v06/v06-sfx.bin)
    4864..49FF  MIRBUF, таблицы адресов записей банков и таблички слияния
                (этап E; уехали с 6320 при слиянии стирания и рисования)
    5000..6425  адаптер экрана        (src/v06/screen_adapter.asm)
    6426..64FF  стек, вершина 6500
    6500..67FF  КАРТА ЧЕРНИЛ (нули в образе), 6800..6845 — переменные
    6847..9F88  данные игры; хвост 8000..9F88 — НЕВИДИМАЯ плоскость
    9F8A..9FF1  ТОЛЬКО --lang ru: 13 приписанных глифов кириллицы
    A000..FFFF  три ВИДИМЫЕ плоскости: в «2 + 1» C000/E000 — тайлы, A000 —
                подвижные объекты; в «Exolon» тайлы во всех трёх

ЯЗЫК выбирается ключом --lang (по умолчанию ru).  Русский — СТАДИЯ СБОРКИ
поверх собранного образа (tools/i18n_ru.py, docs/i18n-ru.md), как
перепаковка банков: она сверяет испанские байты по каждому адресу и кладёт
русские.  --lang es не делает НИЧЕГО и даёт прежний образ байт в байт.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import repack_banks

# Куда лечь таблице шрифта при ПЕРЕЕЗДЕ (адрес глифа кода 0x21).  None —
# таблица остаётся на месте (9CE2), кириллица садится в мёртвые коды и в
# хвост невидимой плоскости; два места с константой FONT_BASE (1737, 23FE)
# не трогаются.  0x407E — переезд всей таблицы в мёртвую после этапа E зону
# теневых таблиц спрайтов (docs/i18n-ru.md, § 2).
FONT_RU_ADDR = None

ROOT = Path(__file__).resolve().parent.parent
ASM = Path(os.environ["ZASM"]) if "ZASM" in os.environ else (Path.home() / "projects/kvalley-v06c/tools/bin/sjasm")  # zasm 4.5.0
OUTDIR = ROOT / "build" / "adapter"

ROM_ORG = 0x0100
PARTS = [
    ("boot", 0x0100, ROOT / "src/v06/boot.asm"),
    ("low", 0x02A0, ROOT / "build/v06/v06-low.bin"),
    ("sfx", 0x4EAA, ROOT / "build/v06/v06-sfx.bin"),
    ("adapter", 0x5000, ROOT / "src/v06/screen_adapter.asm"),
    ("data",  0x6847, ROOT / "build/v06/v06-plane.bin"),
]


def assemble(src: Path, tag: str = "") -> bytes:
    """Собрать и ОСТАВИТЬ ЛИСТИНГ: его требует гейт tools/check_i8080.py.

    Ключи -u -w — те же, что у гейта в tools/build_adapter.sh: байты кода в
    листинге и список меток.  Схемы кладутся в разные файлы, иначе листинг
    одной затирал бы листинг другой, и гейт проверял бы чужой образ.
    """
    out = OUTDIR / (src.stem + tag + ".bin")
    lst = OUTDIR / (src.stem + tag + ".lst")
    r = subprocess.run([str(ASM), "-b", "-w", "-u", str(src),
                        str(lst), str(out)], capture_output=True, text=True)
    if "no errors" not in (r.stdout + r.stderr) or not out.exists():
        sys.exit(f"zasm {src.name}:\n{r.stdout}\n{r.stderr}")
    return out.read_bytes()


CPU_INC = ROOT / "src/v06/cpu.inc"
LABELS_INC = ROOT / "src/v06/game_labels.inc"
# Где искать имена G_xxxx, под которые генерируется карта адресов.
LABEL_USERS = ["src/v06/screen_adapter.asm", "src/v06/adapter.asm",
               "src/v06/glue.asm", "src/v06/cheat.asm", "src/v06/title.asm",
               "src/v06/boot.asm"]


def write_cpu_inc(cpu: str) -> None:
    CPU_INC.write_text(
        "; СГЕНЕРИРОВАНО tools/build_v06_rom.py --cpu ... — правки вносить ТУДА.\n"
        "CPU_I8080       equ     %d\n" % (1 if cpu == "i8080" else 0))


def write_game_labels(cpu: str) -> None:
    """КАРТА АДРЕСОВ КОДА ИГРЫ: G_<адрес Z80> -> адрес в собираемом образе.

    Сборка Z80 — тождество: код игры лежит там же, где лежал.  Сборка i8080
    берёт карту у рекомпилятора (build/i8080/labels.json): код пересобран по
    меткам и переехал.  Имена собираются ИЗ ИСХОДНИКОВ, чтобы в include не
    висело семь тысяч лишних equ.
    """
    import re as _re
    names = set()
    for f in LABEL_USERS:
        pth = ROOT / f
        if pth.is_file():
            names |= set(_re.findall(r"G_([0-9A-F]{4})", pth.read_text()))
    out = ["; СГЕНЕРИРОВАНО tools/build_v06_rom.py --cpu %s — правки вносить ТУДА." % cpu,
           "; Адрес кода игры Z80 -> адрес в этом образе (docs/recompilation.md, §2)."]
    if cpu == "z80":
        for n in sorted(names):
            out.append("G_%s:\tequ\t0x%s" % (n, n))
    else:
        m = json.loads((ROOT / "build/i8080/labels.json").read_text())["map"]
        miss = sorted(n for n in names if n not in m)
        for n in sorted(names):
            if n in m:
                out.append("G_%s:\tequ\t0x%s" % (n, m[n]))
        if miss:
            out.append("; НЕТ В КАРТЕ (эти адреса рекомпиляция не собирает; "
                       "обращения к ним обязаны стоять под #if CPU_I8080 == 0):")
            out += ["; G_%s" % n for n in miss]
    LABELS_INC.write_text("\n".join(out) + "\n")


SCHEME_INC = ROOT / "src/v06/scheme.inc"
SCHEME_NAME = {"exolon": "SCH_EXOLON", "cpc21": "SCH_CPC21"}


def write_scheme(scheme: str) -> None:
    """Положить выбор схемы в include, который читает screen_adapter.asm."""
    SCHEME_INC.write_text(
        "; СГЕНЕРИРОВАНО tools/build_v06_rom.py --scheme ... — правки вносить ТУДА.\n"
        "SCHEME          equ     %s\n" % SCHEME_NAME[scheme])


BANK_INC = ROOT / "src/v06/bank_ptr.inc"


def write_bank_tables() -> None:
    """ЭТАП E: таблицы адресов записей банков -> src/v06/bank_ptr.inc.

    Разбор банков делается ДО ассемблирования (адаптеру нужны таблицы), а
    сама перестановка байтов — ПОСЛЕ сборки образа: перепакованный банк это
    ДРУГИЕ байты, и класть их в эталон нельзя (round-trip-гейты сверяют образ
    с дизасмом и кассетой).  Границы записей от перепаковки не меняются,
    поэтому таблица одна и та же до и после.
    """
    mem = bytearray(0x10000)
    for _name, org, src in PARTS:
        if src.suffix != ".asm":
            b = src.read_bytes()
            mem[org:org + len(b)] = b
    tabs = repack_banks.scan(mem, 0)
    BANK_INC.write_text(repack_banks.inc_text(tabs))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--scheme", choices=("cpc21", "exolon"), default="cpc21")
    ap.add_argument("--cpu", choices=("z80", "i8080"), default="z80")
    ap.add_argument("--lang", choices=("ru", "es"), default="ru")
    ap.add_argument("-o", dest="out")
    a = ap.parse_args()
    if a.cpu == "i8080" and a.scheme != "cpc21":
        # Рекомпиляция считала мёртвый код и зоны врезок по таблицам
        # SCR_PATCH ОСНОВНОЙ схемы; в «Exolon» они другие (1B1D, 1C20, 1C28),
        # и список вырезанного разошёлся бы с образом молча.
        sys.exit("--cpu i8080 собран только для схемы «2 + 1» (cpc21): "
                 "мёртвый код и зоны врезок считаны по её таблицам SCR_PATCH "
                 "(docs/recompilation.md, §6)")
    write_scheme(a.scheme)
    write_cpu_inc(a.cpu)
    write_game_labels(a.cpu)
    write_bank_tables()

    OUTDIR.mkdir(parents=True, exist_ok=True)
    rom = bytearray()
    placed = []
    tag = "" if a.scheme == "cpc21" else "-" + a.scheme
    tagc = tag + ("-i8080" if a.cpu == "i8080" else "")
    for name, org, src in PARTS:
        if name == "low" and a.cpu == "i8080":
            # КОД ИГРЫ ПЕРЕКОМПИЛИРОВАН (tools/recompile_i8080.py): он лежит
            # не одним куском, а по занятым кускам карты, плюс рантайм в
            # дырке 0107..029F под стартовым кодом.  Всё, что НИЖЕ 294B и НЕ
            # занято им, — нули; с 294B и выше (банк спрайтов и рабочая RAM)
            # байты берутся из эталонного блока Z80 без изменений.
            L = json.loads((ROOT / "build/i8080/labels.json").read_text())
            g = (ROOT / "build/i8080/game.bin").read_bytes()
            glo = 0x0107                  # org собранного game.bin
            lowb = bytearray(src.read_bytes())          # 02A0..43C5
            for lo in range(0x02A0, 0x294B):
                lowb[lo - 0x02A0] = 0
            for a1, a2 in L["used"]:
                lo, hi = int(a1, 16), int(a2, 16)
                if lo < 0x02A0:
                    continue              # рантайм кладётся ниже, отдельно
                lowb[lo - 0x02A0:hi - 0x02A0 + 1] = g[lo - glo:hi - glo + 1]
            data = bytes(lowb)
        else:
            data = assemble(src, tagc) if src.suffix == ".asm" \
                else src.read_bytes()
        off = org - ROM_ORG
        if off < len(rom):
            sys.exit(f"{name}: перекрытие в {org:04X}")
        rom.extend(b"\x00" * (off - len(rom)))
        rom.extend(data)
        placed.append((name, org, len(data)))
    if a.cpu == "i8080":
        # рантайм рекомпиляции — в дырку под стартовым кодом порта
        L = json.loads((ROOT / "build/i8080/labels.json").read_text())
        g = (ROOT / "build/i8080/game.bin").read_bytes()
        for a1, a2 in L["used"]:
            lo, hi = int(a1, 16), int(a2, 16)
            if lo >= 0x02A0:
                continue
            if lo < 0x0107:
                sys.exit("рантайм залез на стартовый код 0100..0106")
            rom[lo - ROM_ORG:hi - ROM_ORG + 1] = g[lo - 0x0107:hi - 0x0107 + 1]
            placed.append(("рантайм", lo, hi - lo + 1))
    # --- ЭТАП E: ПЕРЕПАКОВКА БАНКОВ ПО СТОЛБЦАМ (tools/repack_banks.py).
    # Стадия сборки, а не правка эталона: программа сверяет, что банк
    # разбирается на записи и кончается ровно там, где обещает раскладка, и
    # только потом переставляет байты ВНУТРИ записей.  Длина не меняется.
    print("  перепаковка банков по столбцам:")
    if a.cpu == "i8080":
        # объявления банков уехали вместе с кодом — адреса из карты
        m = json.loads((ROOT / "build/i8080/labels.json").read_text())["map"]
        repack_banks.set_decl([int(m["1B53"], 16), int(m["1B59"], 16)])
    tabs = repack_banks.repack(rom, ROM_ORG)
    tb = repack_banks.tab_bytes(tabs)
    o = repack_banks.BKP_ORG - ROM_ORG
    if any(rom[o:o + len(tb)]):
        sys.exit(f"таблицы адресов записей: {repack_banks.BKP_ORG:04X} занято")
    rom[o:o + len(tb)] = tb
    print(f"  таблицы адресов записей банков {repack_banks.BKP_ORG:04X}.."
          f"{repack_banks.BKP_END:04X}  {len(tb)} б")
    # --- СТАДИЯ ПЕРЕВОДА.  Идёт ПОСЛЕ перепаковки банков: банки (декорации
    # 8E76..993F, подвижные объекты 294B..3AA7) и зоны перевода (99E0 и выше)
    # не пересекаются, но перевод по построению работает поверх ГОТОВОГО
    # образа и сверяет по каждому адресу байты, которые ожидает увидеть:
    # если выше по цепочке что-то поменялось, сборка падает, а не кладёт
    # патч мимо.
    tail = ""
    if a.lang == "ru":
        sys.path.insert(0, str(ROOT / "tools"))
        import i18n_ru
        if a.cpu == "i8080":
            i18n_ru.set_game_map(json.loads(
                (ROOT / "build/i8080/labels.json").read_text())["map"])
        plan = i18n_ru.build_plan(bytes(rom), FONT_RU_ADDR)
        i18n_ru.apply(rom, plan)
        # Ожидаемая картинка для гейтов и лист шрифта — из ТОГО ЖЕ плана,
        # что лёг в образ, иначе гейт сверял бы образ с чужим планом.
        i18n_ru.OUT.mkdir(parents=True, exist_ok=True)
        (i18n_ru.OUT / "ru-expect.json").write_text(
            json.dumps(i18n_ru.expectation(plan), ensure_ascii=False, indent=1))
        i18n_ru.font_sheet(i18n_ru.OUT / "font-ru.png", bytes(rom),
                           plan.font_addr - 0x100 if plan.font_addr
                           else i18n_ru.FONT_BASE_DEFAULT)
        zn = plan.zones()
        tail = "  [ru: %d зон, %d б]" % (
            len(zn), sum(hi - lo + 1 for lo, hi, _n in zn))
    stem = "spirits" if a.scheme == "cpc21" else "spirits-%s" % a.scheme
    if a.cpu == "i8080":
        stem += "-i8080"
    out = OUTDIR / (stem + ".rom")
    if a.lang == "es":
        out = out.with_name(out.stem + "-es.rom")
    if a.out:
        out = Path(a.out)
    out.write_bytes(rom)
    for name, org, n in placed:
        print(f"  {name:8s} {org:04X}..{org + n - 1:04X}  {n:6d} б")
    print(f"{out}  {len(rom)} байт  ({ROM_ORG:04X}..{ROM_ORG + len(rom) - 1:04X})"
          f"  язык {a.lang}{tail}")


if __name__ == "__main__":
    main()
