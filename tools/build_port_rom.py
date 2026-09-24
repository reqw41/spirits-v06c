#!/usr/bin/env python3
"""Полный образ порта: экран + ввод + звук, врезанные в игру.

  python3 tools/build_port_rom.py        → build/port/spirits-port.rom
  python3 tools/build_port_rom.py DIR    → DIR/spirits-port.rom (временный образ:
                                           замеры звука собирают в build/snd,
                                           чтобы не трогать build/port)
  python3 tools/build_port_rom.py --scheme exolon
                                         → build/port/spirits-port-exolon.rom
                                           (из build/adapter/spirits-exolon.rom)
  python3 tools/build_port_rom.py --no-title
                                         → без заставки (образ 40585 б, как до
                                           2026-09-22: для замеров, которым
                                           заставка только мешает)

Без ключа берётся ОСНОВНАЯ схема «2 + 1» (docs/adapter-requirements.md,
§ 0c): build/adapter/spirits.rom → build/port/spirits-port.rom.

Берёт готовый build/adapter/spirits.rom (игра в раскладке Вектора + адаптер
экрана), добавляет адаптер ввода/звука (build/v06/adapter.bin, org 4A00) и
связку (src/v06/glue.asm, org 4D00), и СТАТИЧЕСКИ врезает вызовы в код игры.

ЗАСТАВКА (docs/adapter-requirements.md § 0b) живёт ТОЛЬКО в полном порте, и
не случайно: ей нужны V_PSG_WR и V_KBD_POLL адаптера ввода/звука, а в
build/adapter/spirits.rom их нет вовсе.  Поэтому build/adapter/spirits.rom
остаётся прежним, и сверки cmp_hero_msx / cmp_color_msx, которые берут
именно его, заставку не видят.  Здесь добавляется:
  * код заставки src/v06/title.asm по 4620 (мёртвые теневые таблицы
    спрайтов игры, docs/v06-memory.md § 13);
  * картинка build/title/title-planes.bin прямо в плоскости A000..FFFF —
    образ становится 65280 б (0100..FFFF) и картинка оказывается на экране
    сразу после загрузки, без распаковщика;
  * перенаправление старта: boot 0100 идёт в заставку, а она — в SCR_INIT.

Каждая врезка сначала сверяет байты, которые ожидает увидеть. Не сошлось —
сборка падает: значит, игра или раскладка изменились, и патчить вслепую
нельзя. Чужие файлы (screen_adapter.asm, adapter.asm) не меняются.
"""
from __future__ import annotations

import os
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASM = Path(os.environ["ZASM"]) if "ZASM" in os.environ else (Path.home() / "projects/kvalley-v06c/tools/bin/sjasm")  # zasm 4.5
BASE = 0x0100
GAME_ENTRY = 0x0489

# --- КАРТА АДРЕСОВ КОДА ИГРЫ (docs/recompilation.md, §2).
# Все врезки ниже названы адресами Z80-раскладки: так их писали, так они
# читаются и так они сверены с дизасмом.  В сборке i8080 код игры пересобран
# ПО МЕТКАМ и переехал — адрес врезки берётся из карты рекомпилятора.
_MAP = {}


def G(a: int) -> int:
    """Адрес Z80-раскладки -> адрес в собираемом образе."""
    if not _MAP:
        return a
    k = "%04X" % a
    if k not in _MAP:
        sys.exit(f"врезка по {k}: этого адреса нет в карте i8080 "
                 f"(рекомпиляция его не собирает)")
    return int(_MAP[k], 16)


def load_map(cpu: str) -> None:
    if cpu == "i8080":
        _MAP.update(json.loads(
            (ROOT / "build/i8080/labels.json").read_text())["map"])


def labels(lst: Path) -> dict[str, int]:
    out = {}
    for m in re.finditer(r"^(\w+)\s+= \$([0-9A-F]{4}) =", lst.read_text(errors="replace"), re.M):
        out[m.group(1)] = int(m.group(2), 16)
    return out


TITLE_ORG = 0x4620
# Потолок заставки: MIRBUF экранного адаптера (4864..488B) заставка делит с
# ним во времени, а таблицы банков BKP с 488C — уже чужие данные.
MIRBUF = 0x4864
BKP_TABLES = 0x488C
# СТРАНИЦА СПРАВКИ (docs/help-page-ru.md, tools/mk_help.py): дорисованные
# знаки препинания и поток текста.  Место — НАЧАЛО мёртвых теневых таблиц
# спрайтов игры (407E..43FF, docs/v06-memory.md § 12/§ 13): этап E выбросил
# обе чистки в D0F2, и за 3000 кадров код игры не прочитал и не записал там
# ни байта (счётчик SHADOW в tools/trap_stale_v06js.js).  Дальше, с 4400,
# идут списки объектов SPRL/SPRO — туда лезть нельзя.
# 2026-09-23: справка УЕХАЛА с 407E.  По 407E..42F2 лежит БАЙТ-КОД ХОДА
# бродячих объектов (tools/mk_scripts.py, docs/known-issues-ballview.md),
# и он нужен ВСЮ ИГРУ, а справка — только до её старта.  Поэтому справка
# переехала туда, где память свободна ДО игры:
#   знаки препинания -> 3BB9 (рабочая RAM игры, до старта пуста);
#   поток текста     -> 43CF (хвост дырки перед SPRL + сами SPRL/SPRO,
#                             их адаптер наполняет только с первого витка).
# Замер: за игру (playthrough full/sphere, allrooms, экран итога) по
# 407E..42F2 — 0 чтений и 0 записей, по 43C6..461F до SCR_INIT — тоже.
HELP_PUNCT_ORG = 0x3BB9
HELP_TEXT_ORG = 0x43CF
HELP_LIMIT = 0x4620                  # код заставки — первый чужой байт
# Что лежит в этой зоне ДО правки: байты рабочей области игры из образа
# (build/v06/v06-low.bin).  Они мертвы, но не случайны, поэтому врезка
# сверяет их хэш — как и все прочие врезки сверяют ожидаемые байты.
HELP_DEAD_SHA = None                 # зоны теперь разные, сторож ниже — по нулям
# СВЯЗКА.  org опущен с 4E00 до 4DD8 (2026-09-23): 40 байт дырки за
# адаптером ввода (V_END..4DFF) понадобились под перенос головы блока
# сценариев в V_START.  Потолок — таблица звуковых эффектов 4EAA.
GLUE_ORG = 0x4DE8
SCR_INIT = 0x5000
# ЧИТЫ (docs/cheats.md, решение владельца 2026-09-22).  Модуль src/v06/cheat.asm
# кладётся в ничейную дырку 4F3E..4FFF (194 б, docs/v06-memory.md): в адаптер
# ввода/звука он уже не влезает (тот после скана читов дошёл до 4DD7, до связки
# 40 б), а собрать его ВМЕСТЕ с адаптером нельзя — образ адаптера кладётся в
# память одним куском с 4A00, и дырка затёрла бы таблицу эффектов 4EAA..4F21.
CHEAT_ORG = 0x4F3E
# Потолок модуля читов.  В сборке Z80 дырка 4F3E..4FFF ничья, и потолок —
# тело адаптера экрана (5000).  В сборке i8080 с 4FD8 лежат ЯЧЕЙКИ РАНТАЙМА
# рекомпилятора (z80_ix, z80_iy, il_f, z80_af_alt…, RT_VARS в
# tools/recompile_i8080.py): ещё один байт читов молча затёр бы IX/IY, и
# образ улетал бы в пустую память на пятом витке (воспроизведено стендом).
CHEAT_LIMIT_Z80 = 0x5000
CHEAT_LIMIT_I8080 = 0x4FD8           # = RT_VARS рекомпилятора
# Процедуры и ячейки ИГРЫ, которыми пользуется модуль читов (адреса Вектора;
# канон = адрес + 0xB700 для кода игры, docs/v06-memory.md).  Всё, что чит
# зовёт, — штатный код игры: своей отрисовки у него нет.
CHEAT_GAME = [
    ("GM_EDGE",    0x0C2C, "C32C: герой ушёл за край -> сменить комнату"),
    ("GM_LEAVE",   0x0C6F, "C36F: уход из комнаты, показанной в нижнем окне"),
    ("GM_TAIL",    0x1F19, "D619: хвост перехода (атрибуты + C647), кончается ret"),
    ("GM_NB",      0x1D08, "D408: соседи комнаты [верх][низ][лево][право]"),
    ("GV_Y",       0x0AF4, "GAME_VARS+0xA: Y героя"),
    ("GV_X",       0x0AF5, "GAME_VARS+0xB: X героя"),
    ("GV_ROOM",    0x0AF6, "GAME_VARS+0xC: номер ВЕРХНЕЙ (игровой) комнаты"),
    ("GM_LOWROOM", 0x167B, "LEVEL_VARS+0: комната НИЖНЕГО (смотрового) окна"),
    ("GM_ENERCNT", 0x122D, "C92D: счётчик энергии (операнд `ld a,0x13`)"),
    ("GM_ENERGO",  0x1233, "C933: продолжение списания энергии"),
    ("GM_DEADF",   0x0838, "BF38: флаг смерти — операнд `ld a,0x00` по BF37"),
]
# ПЛАМЯ В КОТЛЕ — кадров на один кадр пламени (решение владельца «как на
# MSX», 2026-09-22).  На MSX образ 0x24/0x25 переключается раз за виток
# игрового цикла, а виток там 4.78 кадра — 96 мс, 10.5 смен в секунду.
# Пять кадров = 100 мс, 10 смен в секунду.  Ячейку ведёт V_ISR связки.
FLAME_DIV = 5
T_TEMPO = 10                 # кадров на тик мелодии (CPC: замер 10.156)
T_NOTES = 0x25C5             # база таблицы нот трека 1 (канон DCC5, индекс 30)
T_SCORE_A = 0x2651           # голос A трека 1, 225 б (канон DD51)
T_SCORE_B = 0x2732           # голос B трека 1, 225 б (канон DE32)


def add_help(mem, out, done) -> dict:
    """Страница справки: знаки препинания и поток текста.

    Возвращает equ-адреса для title.asm.  Текст — ДАННЫЕ: он собирается из
    docs/help-page-ru.md каждой сборкой, и поменять страницу можно, не
    трогая ни одной строки кода.  Адреса — HELP_PUNCT_ORG/HELP_TEXT_ORG
    (см. комментарий там же): обе зоны свободны ДО старта игры, а после
    старта первую переиспользует игра, вторую — списки объектов SPRL/SPRO.
    """
    sys.path.insert(0, str(ROOT / "tools"))
    import mk_help                                   # noqa: E402
    blob, expect, rep = mk_help.build()
    npunct = expect["stream_offset"]
    punct, stream = blob[:npunct], blob[npunct:]
    tend = HELP_TEXT_ORG + len(stream) - 1
    if tend >= HELP_LIMIT:
        sys.exit(f"справка: поток {HELP_TEXT_ORG:04X}..{tend:04X} вылез на"
                 f" заставку ({HELP_LIMIT:04X})")
    # Зона потока обязана быть ПУСТОЙ: туда ещё никто ничего не клал.
    if any(mem[HELP_TEXT_ORG:tend + 1]):
        sys.exit(f"справка: зона потока {HELP_TEXT_ORG:04X}..{tend:04X}"
                 f" не пуста — проверьте раскладку")
    mem[HELP_PUNCT_ORG:HELP_PUNCT_ORG + npunct] = punct
    mem[HELP_TEXT_ORG:HELP_TEXT_ORG + len(stream)] = stream
    mk_help.OUT.mkdir(parents=True, exist_ok=True)
    (mk_help.OUT / "help.bin").write_bytes(blob)
    (mk_help.OUT / "help-expect.json").write_text(
        json.dumps(expect | {"punct_addr": HELP_PUNCT_ORG,
                             "text_addr": HELP_TEXT_ORG},
                   ensure_ascii=False), encoding="utf-8")
    done.append((HELP_PUNCT_ORG, f"справка: знаки {HELP_PUNCT_ORG:04X}.."
                 f"{HELP_PUNCT_ORG + npunct - 1:04X} ({npunct} б), поток"
                 f" {HELP_TEXT_ORG:04X}..{tend:04X} ({len(stream)} б;"
                 f" свободно до заставки {HELP_LIMIT - 1 - tend})"))
    return {"HELP_PUNCT": HELP_PUNCT_ORG, "HELP_TEXT": HELP_TEXT_ORG}


def scripts_plan() -> dict:
    """Раскладка БАЙТ-КОДА ХОДА бродячих объектов (tools/mk_scripts.py).

    Считается ДО сборки связки: ей нужны equ SCR_SRC/SCR_DST/SCR_LEN —
    откуда и куда V_START переносит голову блока.
    """
    sys.path.insert(0, str(ROOT / "tools"))
    import mk_scripts                                # noqa: E402
    return mk_scripts.build()


def add_scripts(mem, plan, done, out) -> None:
    """Уложить куски байт-кода в образ и поправить стартовые указатели.

    Стартовых указателей три: в заготовке OBJ_ARRAY_INIT (CBE6, её ldir
    кладёт в массив на старте уровня) и в самом массиве OBJ_ARRAY_CBBF
    (CBBF) — чтобы образ был согласован и до первого уровня.
    """
    # СТОРОЖ МЕСТА — ПО ДИАПАЗОНАМ, А НЕ ПО СОДЕРЖИМОМУ.  Куски ложатся в
    # мёртвую рабочую RAM игры, где в образе лежат её собственные байты, так
    # что «непусто» здесь ничего не значит (проверено: проверка на нули
    # падала на штатной раскладке).  Пересечься куски могут только с тем,
    # что порт кладёт туда же, — со страницей справки; её адреса рядом, в
    # этом же файле, поэтому сверяем именно их.  Наезд на всё остальное
    # ловит tools/verify_v06.py, который берёт зоны из этого модуля.
    import mk_help                                   # noqa: E402
    hblob, hexp, _ = mk_help.build()
    npunct = hexp["stream_offset"]
    help_zones = ((HELP_PUNCT_ORG, HELP_PUNCT_ORG + npunct - 1, "знаки"),
                  (HELP_TEXT_ORG, HELP_TEXT_ORG + len(hblob) - npunct - 1, "поток"))
    for addr, blob in plan["blobs"]:
        lo, hi = addr, addr + len(blob) - 1
        for hlo, hhi, what in help_zones:
            if lo <= hhi and hlo <= hi:
                sys.exit(f"сценарии хода: кусок {lo:04X}..{hi:04X} наехал на"
                         f" справку ({what} {hlo:04X}..{hhi:04X})"
                         f" — проверьте раскладку")
    for addr, blob in plan["blobs"]:
        mem[addr:addr + len(blob)] = blob
    for base in (G(0x14E6), G(0x14BF)):
        for k, new in enumerate(plan["starts"]):
            off = base + k * 13 + 1
            mem[off] = new & 0xFF
            mem[off + 1] = new >> 8
    src, dst, ln = plan["copy"]
    # Зоны для стендов и гейтов: где в образе лежит байт-код хода.  Голова
    # (кусок по src) помечена отдельно — она живёт там только до V_START.
    zones = [{"lo": a, "hi": a + len(b) - 1, "stage": a == src}
             for a, b in plan["blobs"]]
    zones.append({"lo": dst, "hi": dst + ln - 1, "stage": False})
    (Path(out) / "scripts-zones.json").write_text(
        json.dumps({"zones": zones, "copy": {"src": src, "dst": dst, "len": ln},
                    "starts": plan["starts"], "place": plan["place"]}),
        encoding="utf-8")
    done.append((plan["blobs"][0][0],
                 f"сценарии хода: {sum(len(b) for _, b in plan['blobs'])} б в"
                 f" {len(plan['blobs'])} кусках, переходов дописано"
                 f" {plan['jumps']}, копия в V_START {ln} б {src:04X}->{dst:04X}"))


def check_8080(binf: Path, lstf: Path) -> None:
    """Сторож чистоты i8080 для того, что собрала ЭТА сборка.

    tools/build_adapter.sh гоняет check_i8080 по adapter.bin, а связка и
    модуль читов собираются здесь — значит и сторож им нужен здесь, иначе
    опкод Z80 в них не увидит никто.
    """
    r = subprocess.run([sys.executable, str(ROOT / "tools/check_i8080.py"),
                        str(binf), str(lstf)], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"{binf.name}: НЕ подмножество i8080\n{r.stdout}{r.stderr}")


def build_cheat(out, L) -> tuple[bytes, dict[str, int]]:
    """Модуль читов src/v06/cheat.asm (org 4F3E) — отдельный прогон zasm.

    Адреса ячеек читов приходят из листинга АДАПТЕРА (их ведёт V_KBD_POLL),
    адреса процедур игры — константами отсюда: раскладка Вектора у игры
    фиксирована, и все они сверяются врезками ниже по ожидаемым байтам.
    """
    equs = "".join(f"{n}:\tequ\t0x{L[n]:04X}\n"
                   for n in ("v_cheat", "v_god", "v_cpend"))
    for n, v, what in CHEAT_GAME:
        equs += f"{n}:\tequ\t0x{G(v):04X}\t; {what}\n"
    casm = out / "cheat_full.asm"
    casm.write_text(equs + (ROOT / "src/v06/cheat.asm").read_text())
    r = subprocess.run([str(ASM), "--8080", "-b", "-w", "-u", str(casm),
                        str(out / "cheat.lst"), str(out / "cheat.bin")],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"zasm (--8080) не собрал модуль читов:\n{r.stdout}\n{r.stderr}")
    check_8080(out / "cheat.bin", out / "cheat.lst")
    return (out / "cheat.bin").read_bytes(), labels(out / "cheat.lst")


def add_title(mem, out, L, inp, patch, done) -> int:
    """Заставка: код по 4620, картинка в плоскости A000..FFFF, старт через неё.

    Возвращает новый конец образа (0x10000).  Всё, на что заставка ссылается
    внутри игры, СВЕРЯЕТСЯ здесь же: не сошлось — сборка падает, потому что
    играть мусором из чужих адресов хуже, чем не собраться.
    """
    planes = ROOT / "build/title/title-planes.bin"
    pal = ROOT / "build/title/title-pal.inc"
    if not planes.exists() or not pal.exists():
        sys.exit("нет build/title/* — сперва python3 tools/mk_title.py")
    img = planes.read_bytes()
    assert len(img) == 0x6000, f"картинка {len(img)} б, а плоскости A000..FFFF — 24576"

    # --- сверка данных мелодии, на которые смотрит плеер заставки
    period30 = int.from_bytes(mem[G(T_NOTES):G(T_NOTES) + 2], "little")
    if period30 != 0x025C:
        sys.exit(f"{T_NOTES:04X}: база таблицы нот должна начинаться периодом "
                 f"025C (F#3, индекс 30), а там {period30:04X}")
    for addr, what in ((G(T_SCORE_A), "голос A"), (G(T_SCORE_B), "голос B")):
        body = mem[addr:addr + 225]
        if body[-1] != 0xFE or 0xFE in body[:-1]:
            sys.exit(f"{addr:04X}: {what} трека 1 — не 225 байт, кончающихся FE")
        codes = [b for b in body if b not in (0xFE, 0xFF)]
        if codes and max(codes) > 0x7F:
            sys.exit(f"{addr:04X}: код ноты {max(codes)} — `add a,a` плеера "
                     f"заставки рассчитан на коды < 128")

    # --- сборка title.asm: адреса адаптера и данных мелодии идут через equ
    help_equ = add_help(mem, out, done)
    need = ["V_PSG_WR", "V_KBD_POLL", "V_KBD_INIT", "V_SND_INIT",
            "v_msxrow", "v_scroll"]
    miss = [n for n in need if n not in L]
    if miss:
        sys.exit(f"в листинге адаптера нет меток: {miss}")
    scroll_game = inp[L["v_scroll"] - 0x4A00]   # значение игры — из самого образа
    equs = "".join(f"{n}:\tequ\t0x{L[n]:04X}\n" for n in need)
    equs += (f"SCR_INIT:\tequ\t0x{SCR_INIT:04X}\n"
             f"SCROLL_GAME:\tequ\t0x{scroll_game:02X}\n"
             f"T_TEMPO:\tequ\t{T_TEMPO}\n"
             f"T_NOTES:\tequ\t0x{G(T_NOTES):04X}\n"
             f"T_SCORE_A:\tequ\t0x{G(T_SCORE_A):04X}\n"
             f"T_SCORE_B:\tequ\t0x{G(T_SCORE_B):04X}\n"
             f"GM_FONTPTR:\tequ\t0x{G(0x1737):04X}\n")
    equs += "".join(f"{n}:\tequ\t0x{v:04X}\n" for n, v in help_equ.items())
    (out / "title-pal.inc").write_text(pal.read_text())   # рядом с .asm: .include
    tasm = out / "title_full.asm"
    tasm.write_text(equs + (ROOT / "src/v06/title.asm").read_text())
    r = subprocess.run([str(ASM), "--8080", "-b", "-w", "-u", str(tasm),
                        str(out / "title.lst"), str(out / "title.bin")],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"zasm (--8080) не собрал заставку:\n{r.stdout}\n{r.stderr}")
    code = (out / "title.bin").read_bytes()
    T = labels(out / "title.lst")
    # ПОТОЛОК ЗАСТАВКИ — НЕ 4A00, А 488C (правка 2026-09-23).  Выше заставки
    # лежат чужие куски экранного адаптера: MIRBUF 4864..488B (буфер
    # зеркального столбца, в образе — 40 НУЛЕЙ) и таблицы адресов записей
    # банков BKP 488C..4969 (НАСТОЯЩИЕ ДАННЫЕ, screen_adapter.asm,
    # bank_ptr.inc).  С MIRBUF заставка делит место ЗАКОННО: обе зоны
    # временные и НЕ ПЕРЕСЕКАЮТСЯ ВО ВРЕМЕНИ — заставка кончается до
    # SCR_INIT, а MIRBUF пишет только блиттер игры, то есть после него
    # (замер: tools/pal_writes_v06js.js, раздел «MIRBUF и заставка»).
    # А вот на BKP лезть нельзя ни байтом — там данные, которые нужны игре.
    assert TITLE_ORG + len(code) <= BKP_TABLES, \
        (f"заставка {TITLE_ORG:04X}..{TITLE_ORG + len(code) - 1:04X} вылезла"
         f" на таблицы банков BKP ({BKP_TABLES:04X}) — это НЕ слак, а данные")
    mem[TITLE_ORG:TITLE_ORG + len(code)] = code
    mem[0xA000:0x10000] = img

    # старт: boot 0100 шёл прямо в SCR_INIT, теперь — в заставку
    patch(0x0104, f"C3 {SCR_INIT & 255:02X} {SCR_INIT >> 8:02X}",
          bytes([0xC3, T["TITLE"] & 255, T["TITLE"] >> 8]),
          f"boot -> заставка {T['TITLE']:04X}")
    over = TITLE_ORG + len(code) - MIRBUF
    done.append((TITLE_ORG, f"заставка {TITLE_ORG:04X}..{TITLE_ORG + len(code) - 1:04X}"
                            f"  {len(code)} б (код {T['T_CODE_END'] - TITLE_ORG} б,"
                            f" данные {len(code) - (T['T_CODE_END'] - TITLE_ORG)} б)"
                            + (f"; последние {over} б делят место с MIRBUF"
                               f" {MIRBUF:04X}..488B, до данных BKP"
                               f" {BKP_TABLES - (TITLE_ORG + len(code))} б"
                               if over > 0 else
                               f"; до MIRBUF {MIRBUF:04X} ещё {-over} б")))
    done.append((0xA000, f"картинка заставки A000..FFFF  {len(img)} б"))
    return 0x10000


def main() -> int:
    args = sys.argv[1:]
    scheme = "cpc21"
    cpu = "z80"
    if "--cpu" in args:
        i = args.index("--cpu")
        cpu = args[i + 1]
        del args[i:i + 2]
        assert cpu in ("z80", "i8080"), cpu
    if cpu == "i8080" and scheme != "cpc21":
        sys.exit("--cpu i8080 собран только для схемы «2 + 1» (cpc21)")
    load_map(cpu)
    title = True
    if "--no-title" in args:
        title = False
        args.remove("--no-title")
    if "--scheme" in args:
        i = args.index("--scheme")
        scheme = args[i + 1]
        del args[i:i + 2]
        assert scheme in ("exolon", "cpc21"), scheme
    tag = ("" if scheme == "cpc21" else "-" + scheme) \
        + ("-i8080" if cpu == "i8080" else "")
    out = ROOT / (args[0] if args else "build/port")
    out.mkdir(parents=True, exist_ok=True)
    # СТОРОЖ СВЕЖЕСТИ АДАПТЕРА.  Эта сборка берёт ГОТОВЫЙ образ адаптера и
    # сама его не пересобирает.  Без проверки правка в src/v06/*.asm молча не
    # попадает в порт: так после слияния ветки звука образ собрался со СТАРЫМ
    # snd.asm, и сторож звука покраснел тремя строками, хотя исходник был
    # правильный (2026-09-23). Сверяем время: любой исходник новее образа —
    # падаем и говорим, чем пересобрать.
    adapter_rom = ROOT / f"build/adapter/spirits{tag}.rom"
    if not adapter_rom.is_file():
        sys.exit(f"нет {adapter_rom.relative_to(ROOT)} — сперва"
                 f" sh tools/build_adapter.sh")
    # Сверяем с build/v06/adapter.bin: именно он собран из src/v06/*.asm
    # (tools/build_adapter.sh), а build/adapter/spirits.rom несёт игру с
    # экранным адаптером и живёт своей жизнью.
    adapter_bin = ROOT / "build/v06/adapter.bin"
    if not adapter_bin.is_file():
        sys.exit("нет build/v06/adapter.bin — сперва sh tools/build_adapter.sh")
    # Только то, что ВХОДИТ в adapter.bin: adapter.asm и три его .include.
    # glue/cheat/title эта же сборка ассемблирует сама на каждом прогоне, и
    # включать их в проверку — ложная тревога (наступил 2026-09-23: правка
    # glue.asm роняла сборку с советом пересобрать адаптер, который тут ни
    # при чём). boot/screen_adapter собирает tools/build_v06_rom.py.
    ADAPTER_SRC = ("adapter.asm", "snd.asm", "kbd.asm", "joy.asm")
    stale = [p for p in (ROOT / "src/v06" / n for n in ADAPTER_SRC)
             if p.is_file() and p.stat().st_mtime > adapter_bin.stat().st_mtime]
    if stale and os.environ.get("STALE_OK") != "1":
        sys.exit("адаптер СТАРШЕ своих исходников, порт собрался бы без их"
                 " правок:\n  " + "\n  ".join(str(p.relative_to(ROOT))
                                              for p in stale)
                 + "\n  пересобрать:  sh tools/build_adapter.sh"
                 + "\n  собрать как есть:  STALE_OK=1")
    rom = bytearray(adapter_rom.read_bytes())
    inp = (ROOT / "build/v06/adapter.bin").read_bytes()
    L = labels(ROOT / "build/v06/adapter.lst")
    # v_carm и V_CHEAT_WIN нужны связке: срок бессрочному окну читов ставит
    # ПЕРВЫЙ ВИТОК игрового цикла (V_JOY_PACE), а не V_CHEAT_ARM (docs/cheats.md).
    need = ["V_PSG_WR", "V_KBD_ROW", "V_KBD_SCAN", "V_KBD_POLL", "V_KBD_INIT",
            "V_SND_TICK", "V_SND_INIT", "V_JOY_RD", "V_CHEAT_ARM",
            "v_cheat", "v_god", "v_cpend", "v_carm", "V_CHEAT_WIN", "V_END"]
    miss = [n for n in need if n not in L]
    if miss:
        print("в листинге адаптера нет меток:", miss)
        return 2

    # --- БАЙТ-КОД ХОДА бродячих объектов: раскладка считается ЗДЕСЬ,
    # потому что связке нужны её адреса; в образ куски лягут ниже.
    scr_plan = scripts_plan()
    scr_equ = {"SCR_SRC": scr_plan["copy"][0], "SCR_DST": scr_plan["copy"][1],
               "SCR_LEN": scr_plan["copy"][2]}

    # связка: подставляем адреса через equ
    glue_src = (ROOT / "src/v06/glue.asm").read_text()
    equs = "".join(f"{n}:\tequ\t0x{L[n]:04X}\n" for n in need[:-1])
    equs += "".join(f"{n}:\tequ\t0x{v:04X}\n" for n, v in scr_equ.items())
    equs += f"GAME_ENTRY:\tequ\t0x{G(GAME_ENTRY):04X}\n"
    equs += f"MUS_TEMPO:\tequ\t0x{G(0x2581):04X}\n"       # темп плеера (D_256F+0x12)
    equs += f"GAME_ITER:\tequ\t0x{G(0x0834):04X}\n"   # тело витка BF34 (пейсер)
    equs += f"GAME_SPRFLUSH:\tequ\t0x{G(0x1F64):04X}\n"   # D664 выгрузка спрайтов
    equs += f"GAME_LIST_DRAW:\tequ\t0x{G(0x1F55):04X}\n"   # D655 цикл дорисовки
    equs += "GAME_LIST_TAIL:\tequ\t0x40FD\n"               # F7FD хвост списка (данные, не переезжают)
    equs += f"MUS_AFTER_WAIT:\tequ\t0x{G(0x2478):04X}\n"  # плеер после задержки
    equs += f"MUS_KEY_EXIT:\tequ\t0x{G(0x255C):04X}\n"    # выход по клавише
    equs += f"V_FLAME_DIV:\tequ\t{FLAME_DIV}\n"  # кадров на кадр пламени
    gasm = out / "glue_full.asm"
    gasm.write_text(equs + glue_src)
    r = subprocess.run([str(ASM), "--8080", "-b", "-w", "-u", str(gasm),
                        str(out / "glue.lst"), str(out / "glue.bin")],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print("zasm (--8080) не собрал связку:\n", r.stdout, r.stderr)
        return 2
    check_8080(out / "glue.bin", out / "glue.lst")
    glue = (out / "glue.bin").read_bytes()
    G_ = labels(out / "glue.lst")

    mem = bytearray(0x10000)
    mem[BASE:BASE + len(rom)] = rom
    end = BASE + len(rom)

    def put(addr: int, data: bytes, what: str):
        for k in range(len(data)):
            if mem[addr + k] not in (0x00, 0xA5, 0xFF) and what.startswith("блок"):
                pass
        mem[addr:addr + len(data)] = data

    assert L["V_END"] <= GLUE_ORG, "адаптер ввода вылез на связку"
    # Потолок связки — ТАБЛИЦА ЗВУКОВЫХ ЭФФЕКТОВ (4EAA..4F21), а не 4F22:
    # прежняя граница пустила бы связку прямо на таблицу, и 120 байт
    # дескрипторов молча стали бы кодом (найдено при врезке читов).
    assert GLUE_ORG + len(glue) <= 0x4EAA, \
        f"связка вылезла на таблицу эффектов 4EAA (конец {GLUE_ORG + len(glue):04X})"
    put(0x4A00, inp, "блок ввод/звук")
    put(GLUE_ORG, glue, "блок связка")
    cheat, C = build_cheat(out, L)
    cheat_limit = CHEAT_LIMIT_I8080 if cpu == "i8080" else CHEAT_LIMIT_Z80
    assert CHEAT_ORG + len(cheat) <= cheat_limit, \
        f"модуль читов вылез на адаптер экрана ({CHEAT_ORG + len(cheat):04X})"
    put(CHEAT_ORG, cheat, "блок читы")

    done = []
    # БАЙТ-КОД ХОДА в образ — до заставки и до врезок: справка теперь стоит
    # в местах, которые он освободил, а врезка D648 опирается на его границы.
    add_scripts(mem, scr_plan, done, out)

    def patch(addr: int, expect: str, new: bytes, what: str, reloc=()):
        """reloc — смещения 16-битных АДРЕСОВ КОДА ИГРЫ в ожидаемых байтах:
        в сборке i8080 они переехали вместе с кодом, и ждать там прежнее
        значение нельзя (адрес самой врезки уже переведён через G())."""
        addr = G(addr)
        exp = bytearray(bytes.fromhex(expect))
        for o in reloc:
            v = G(exp[o] | (exp[o + 1] << 8))
            exp[o], exp[o + 1] = v & 255, v >> 8
        exp = bytes(exp)
        got = bytes(mem[addr:addr + len(exp)])
        if got != exp:
            print(f"ВРЕЗКА НЕ СОШЛАСЬ {addr:04X} ({what}): ждали {exp.hex(' ')}, "
                  f"в образе {got.hex(' ')}")
            sys.exit(1)
        assert len(new) <= len(exp)
        mem[addr:addr + len(exp)] = new + b"\x00" * (len(exp) - len(new))
        done.append((addr, what))

    def patch_raw(addr, expect, new, what):
        """Врезка по АДРЕСУ ОБРАЗА (адаптер, не код игры) — без карты."""
        exp = bytes.fromhex(expect)
        got = bytes(mem[addr:addr + len(exp)])
        if got != exp:
            sys.exit(f"ВРЕЗКА НЕ СОШЛАСЬ {addr:04X} ({what}): ждали "
                     f"{exp.hex(' ')}, в образе {got.hex(' ')}")
        mem[addr:addr + len(exp)] = new + b"\x00" * (len(exp) - len(new))
        done.append((addr, what))

    def call(a): return bytes([0xCD, a & 255, a >> 8])
    def jp(a): return bytes([0xC3, a & 255, a >> 8])

    # звук
    patch(0x2569, "D3 A0 79 D3 A1 C9", jp(L["V_PSG_WR"]), "PSG_WR -> V_PSG_WR")
    patch(0x03FC, "D3 A0 79 D3 A1", call(L["V_PSG_WR"]), "прямая запись в PSG")
    # ДЛИНА ДВУХ ЗВУКОВ ЗАДАНА ПУСТЫМ ЦИКЛОМ, А НЕ ОГИБАЮЩЕЙ — и уезжает
    # вместе с частотой процессора.
    #
    #   D6FB `ld hl,1388` — 5000 итераций между каждым из 25 повторов 64D7
    #                       («механизм»: рычаг открывает проход, C547/C594);
    #   DB27 `ld bc,2710` — 10000 итераций после 64E6 (потеря жизни, C685).
    #
    # Оба цикла — `dec hl / ld a,h / or l / jr nz`, то есть чистые такты.  На
    # MSX Z80 идёт на 3.5795 МГц, на Векторе процессор 2.9952 МГц, а у i8080
    # ещё и цена итерации другая: машинные циклы Вектора кратны четырём
    # тактам, поэтому команда в 5 состояний стоит 8, и виток выходит 32 такта
    # против 26 у Z80.  ЗАМЕР (tools/snd_sfx_msx.tcl против
    # tools/snd_sfx_v06js.js): «механизм» на MSX 1053.2 мс, у нас с прежней
    # константой 1149.6 (Z80, +9.2 %) и 1427.4 (i8080, +35.5 %); пауза после
    # потери жизни 84.0 мс против 90.6 и 112.3.
    #
    # Числа итераций подобраны ЗАМЕРОМ, а не формулой (кадровое прерывание
    # тоже съедает время): по две пробы на образ, линейная подгонка, проверка
    # третьей пробой.  Подбор повторяется knobs SND_N25/SND_NDB стенда.
    n25, ndb = (0x11D7, 0x2423) if cpu == "z80" else (0x0E43, 0x1D21)
    patch(0x1FFB, "21 88 13", bytes([0x21, n25 & 255, n25 >> 8]),
          f"пауза внутри 64D7 x25: {n25} итераций вместо 5000 (темп MSX)")
    patch(0x2427, "01 10 27", bytes([0x01, ndb & 255, ndb >> 8]),
          f"пауза после 64E6: {ndb} итераций вместо 10000 (темп MSX)")
    # клавиатура
    patch(0x1CDF, "C5 79 E6 07", jp(L["V_KBD_SCAN"]), "KBD_SCAN -> V_KBD_SCAN")
    row = call(L["V_KBD_ROW"])
    patch(0x1F86, "D3 AA DB A9", row, "KBD_CHK, пауза (H)")
    patch(0x088E, "D3 AA 00 DB A9", row, "выбор персонажа 1..5")
    patch(0x12BC, "D3 AA 00 DB A9", row, "SHIFT")
    patch(0x155F, "D3 AA DB A9", row, "пауза, ожидание")
    patch(0x156A, "D3 AA 00 DB A9", row, "любая клавиша")
    patch(0x18B4, "D3 AA DB A9", row, "любая клавиша")
    if cpu == "z80":
        # ТЕЛО ЦИКЛА ЗАДЕРЖКИ ПЛЕЕРА (245F..2477) в сборке i8080 НЕ СОБИРАЕТСЯ
        # вовсе: вход 245C заменён на `jp V_MUS_WAIT`, и опрос клавиши внутри
        # цикла делает уже связка (tools/i8080_dead.py считает это тело мёртвым).
        patch(0x2466, "D3 AA DB A9", row, "любая клавиша в задержке плеера")
    # джойстик: R7=FF / R14 / in A2 — 14 байт
    # ВНИМАНИЕ: запись R7=FF здесь — НЕ мусор. На MSX опрос джойстика пишет в
    # микшер FF, чтобы настроить порт ввода PSG, и побочно ГАСИТ ВСЕ КАНАЛЫ на
    # каждом витке игрового цикла (замер на живом MSX: `R7 = FF pc=C9E7` каждые
    # 90 мс). Любой эффект в оригинале живёт только до следующего опроса —
    # поэтому звуки там короткие и прерывистые. Первая версия врезки эту запись
    # выбросила («настоящего PSG нет»), и эффекты тянулись до конца своего
    # срока — владелец на слух: «в оригинале короче и прерывистее».
    # bc сохраняем: оригинал его не трогал, а V_PSG_WR берёт значение из c.
    patch(0x12E1, "3E 07 D3 A0 3E FF D3 A1 3E 0E D3 A0 DB A2",
          bytes([0xC5, 0x3E, 0x07, 0x0E, 0xFF]) + call(L["V_PSG_WR"])
          + bytes([0xC1]) + call(L["V_JOY_RD"]),
          "джойстик: R7=FF (гасит звук, как на MSX) + V_JOY_RD")
    # ТЕМП ИГРЫ — НА ГОЛОВЕ ГЛАВНОГО ЦИКЛА BB8F (0489+6 = 048F).  Через опрос
    # джойстика (12E1) проходят НЕ ВСЕ витки: прыжок (C425) и падение (C3EF)
    # уходят на свои ветки в C185/C18C до вызова CC7B — они шли без пейсера, и
    # прыжок летел втрое быстрее положенного (замер tools/jump_pace_probe.js:
    # 1.51 кадра на виток против 4 при ходьбе; на живом MSX 4.50 против 4.81).
    # BB8F исполняется ровно раз за виток на всех витках замера.
    patch(0x048F, "CD 34 08", call(G_["V_LOOP_PACE"]),
          "темп: пейсер на КАЖДЫЙ виток (голова главного цикла BB8F)",
          reloc=(1,))
    # ЧИСТКА F58D..F77D УКОРОЧЕНА (docs/known-issues-ballview.md § 8.3).
    # D63F зануляет 0x1F0 байт с F58D (порт 3E8D); в порту дальше F654
    # (порт 3F54) лежит БАЙТ-КОД ХОДА бродячих объектов, а саму зону никто
    # не читает: за playthrough full/sphere, allrooms и экран итога на обоих
    # образах по 3F55..407D 0 чтений и 0 записей, а D63F не исполнился ни
    # разу.  Оставляем чистку ровно того куска, который и так пишет D4EF.
    patch(0x1F48, "01 F0 01", bytes([0x01, 0xC8, 0x00]),
          "D648: чистить F58D..F654, дальше — сценарии хода объектов")
    # ПУСТОЙ СПИСОК НИЖНЕГО ОКНА — djnz на 256 (docs/jump-geometry.md § 9).
    # Очередь записей в VDP заменил адаптер, заполнитель D352 не исполняется,
    # список всегда пуст и b = 0 — цикл D655 уезжал на 1024 байта вниз, в
    # теневой буфер атрибутов, и портил проходимость КОМНАТЫ ШАРА.
    patch(0x1A39, "45 1B 21 FD 40 C3 55 1F", jp(G_["V_LIST_GUARD"]),
          "пустой список нижнего окна: не крутить djnz 256 раз",
          reloc=(6,))
    # ---- ЧИТЫ (docs/cheats.md).  Три врезки, все — на штатных путях игры.
    # 1. ХВОСТ ХОДА ГЕРОЯ.  0B45 (канон C245) — точка, куда игра возвращается
    #    после любого движения (C260 кладёт 0B45 на стек), и первым делом
    #    зовёт C32C «не ушёл ли герой за край».  Врезка не заменяет проверку,
    #    а надставляет: V_CHEAT_MOVE сам зовёт C32C первой командой.
    patch(0x0B45, "CD 2C 0C", call(C["V_CHEAT_MOVE"]),
          f"читы: переход по UHJNK -> V_CHEAT_MOVE ({C['V_CHEAT_MOVE']:04X})",
          reloc=(1,))
    # 2. ЭНЕРГИЯ.  Врезка начинается с 122E, а НЕ с 122C: байт 122D —
    #    самомодифицируемый операнд `ld a,0x13`, то есть сам счётчик энергии
    #    (пишут 1230 и 1325, читают 0AC8 и 0F1E).  Три байта `jp` по 122C
    #    затёрли бы его.  Заменяются `dec a / push af / ld (122D),a` — их
    #    повторяет V_CHEAT_ENER и уходит на 1233.
    patch(0x122E, "3D F5 32 2D 12", jp(C["V_CHEAT_ENER"]), reloc=(3,),
          what=f"читы: god mode — энергия не убывает ({C['V_CHEAT_ENER']:04X})")
    # 3. СМЕРТЬ.  Вся смерть в игре — одна запись флага BF38: C625 кладёт 1
    #    (орёл, плита, тёмная комната 56), C92C через C627 кладёт 2 (энергия
    #    кончилась).  Обе ветки сходятся на `ld (0838),a / ret` по 0F27, и
    #    вызывающие ждут за этим ret'ом только возврата.  Хвостовой C9
    #    оставлен на месте: 0F2A больше не исполняется, но пусть там будет
    #    команда, а не ноль.
    patch(0x0F27, "32 38 08 C9", jp(C["V_CHEAT_DEATH"]) + bytes([0xC9]),
          f"читы: god mode — смерть не срабатывает ({C['V_CHEAT_DEATH']:04X})",
          reloc=(1,))
    # ПЛАМЯ В КОТЛЕ — КАДР ПО КАДРАМ, А НЕ ПО ВИТКАМ («как на MSX», решение
    # владельца 2026-09-22).  Оригинал (BC86..BC98, у нас 0586..0598) берёт
    # фазу из таблицы BCBA (у нас 05BA, три записи «комната, X, фаза») и
    # переключает её `xor 1` НА КАЖДОМ ВИЗОВЕ, то есть на каждом витке
    # игрового цикла.  На MSX виток 4.78 кадра (96 мс, 10.5 смен в секунду),
    # а у нас темп ZX — 3.5 кадра, и пламя мигало бы в 1.4 раза быстрее.
    # Врезка меняет ИСТОЧНИК фазы, а не логику вывода: вместо
    #   ld a,(iy+2) / xor 1 / ld (iy+2),a     (FD 7E 02  EE 01  FD 77 02)
    # стоит
    #   ld a,(v_flame) / ld (iy+2),a / nop nop
    # Дальше всё как в оригинале: `add a,0x24` даёт образ 0x24 или 0x25 и
    # `call D0A0` рисует его.  Запись в (iy+2) оставлена, чтобы фаза в
    # таблице не расходилась с тем, что нарисовано.  Ячейку v_flame ведёт
    # V_ISR связки — делитель на FLAME_DIV кадров.
    # ТОЛЬКО В ПОЛНОМ ПОРТЕ: в build/adapter/spirits.rom связки нет, и
    # пламя там остаётся по виткам (docs/known-issues.md).
    # В сборке i8080 `ld a,(iy+2) / xor 1 / ld (iy+2),a` развёрнуто в
    # `call il_iy_lda / db 2 / xor 1 / call il_iy_sta / db 2` (10 байт), и
    # замена ставит `ld a,(v_flame)` перед тем же хелпером записи.
    if cpu == "i8080":
        IL = labels(ROOT / "build/i8080/game.lst")
        patch(0x058E,
              "CD %02X %02X 02 EE 01 CD %02X %02X 02"
              % (IL["il_iy_lda"] & 255, IL["il_iy_lda"] >> 8,
                 IL["il_iy_sta"] & 255, IL["il_iy_sta"] >> 8),
              bytes([0x3A, G_["v_flame"] & 255, G_["v_flame"] >> 8])
              + call(IL["il_iy_sta"]) + bytes([0x02]),
              f"пламя: фаза из v_flame ({G_['v_flame']:04X}), смена раз в"
              f" {FLAME_DIV} кадров (было `xor 1` на каждом витке)")
    else:
        patch(0x058E, "FD 7E 02 EE 01 FD 77 02",
              bytes([0x3A, G_["v_flame"] & 255, G_["v_flame"] >> 8,
                     0xFD, 0x77, 0x02]),
              f"пламя: фаза из v_flame ({G_['v_flame']:04X}), смена раз в"
              f" {FLAME_DIV} кадров (было `xor 1` на каждом витке)")
    # УКАЗАТЕЛЬ ТРЕТЬЕГО ГОЛОСА МЕЛОДИИ — НЕПЕРЕЕХАВШИЙ АДРЕС.
    # В переменных плеера (D_256F+0x18 = 2587) лежит начальный указатель
    # голоса C. В оригинале MSX это DFE5 — заглушка `FF FE` («пауза,
    # повтор»), и голос C корректно молчит (docs/cpc-sound.md §2.3: на CPC
    # ровно то же самое, `AB54..AB55 = FF FE`). При переезде на Вектор слово
    # осталось прежним: оно лежит внутри db-области дизасма, а там операнды
    # не переезжают, и tools/find_unrelocated.py его не видит — он ищет
    # только опкоды jp/call. В раскладке Вектора DFE5 — ВИДИМАЯ ЭКРАННАЯ
    # ПЛОСКОСТЬ, и плеер каждый тик читает оттуда чужой байт.
    # ЗАМЕР (tools/snd_v06_probe.js, принудительный пуск мелодии): голос C
    # читал 0x00, то есть ноту по индексу 0 от базы 25C5 = период 0x025C, и
    # каждый тик писал R4=5C R5=02. На MSX (openMSX, картридж [4397],
    # build/snd/msx_track1.log) записей в R4/R5 НЕТ НИ ОДНОЙ.
    # Слышно этого не было только из-за порога громкости 6 (R10 = 0); со
    # снятым порогом счётчик 2 гудел F#3 185 Гц под всю мелодию — тоже замер.
    # Правка: 2 байта, DFE5 -> 28E5 (тот же `FF FE` в раскладке Вектора).
    a87, a8E5 = G(0x2587), G(0x28E5)
    p3 = bytes(mem[a87:a87 + 2])
    want = bytes([a8E5 & 255, a8E5 >> 8])
    if p3 == bytes([0xE5, 0xDF]):
        assert bytes(mem[a8E5:a8E5 + 2]) == b"\xFF\xFE", "нет заглушки FF FE"
        mem[a87:a87 + 2] = want
        done.append((a87, "указатель 3-го голоса DFE5 -> %04X (непереехавший"
                          " адрес)" % a8E5))
    elif p3 != want:
        print(f"{a87:04X}: ждали указатель голоса C E5 DF или {want.hex(' ')},"
              f" в образе {p3.hex(' ')}")
        return 1
    # ОТЛИЧИЕ ОТ ОРИГИНАЛА (решение владельца, 2026-09-23): патрульный № 0
    # (горбун, маршрут комнаты 00 X=09 .. 03 X=39) на MSX стартует В СТАРТОВОЙ
    # комнате героя (00, X=99) и сразу идёт на него. Здесь он стартует с
    # середины маршрута — комната 02, X=50, направление вправо (бит 7 = 0 ->
    # add 3, к пределу A), и возвращается в комнату 00 только пройдя 03.
    # Таблица OBJ_TABLE_B6A2 (Вектор 9AA2, блок данных) правится в самой игре
    # на ходу и при новой партии НЕ сбрасывается (CE6A трогает только рычаги
    # и LEVEL_VARS) — ровно как на MSX; меняется только исходное состояние.
    # Только в ПОРТЕ: образ адаптера остаётся эталонным для сверок с MSX.
    patch_raw(0x9AA2, "50 99 00 91 00 03 39 00 09",
              bytes([0x50, 0x50, 0x02, 0x91, 0x00, 0x03, 0x39, 0x00, 0x09]),
              "патрульный 0 стартует в комнате 02 (X=50), а не в стартовой")
    # ТЕМП МЕЛОДИЙ — ПО КАДРАМ (src/v06/glue.asm, V_MUS_WAIT). Шаг мелодии на
    # MSX = tempo итераций по 667 тактов при 3.579545 МГц = 186.3 мкс. Переводим
    # в кадры 50 Гц и кладём в ту же ячейку вместо числа итераций.
    STEP = 667 / 3579545.0
    for addr, tempo, what in ((0x28F3, 0x0480, "темп мелодии 1"),
                              (0x2925, 0x04FF, "темп мелодии 2")):
        fr = max(1, round(tempo * STEP * 50))
        patch(addr, f"21 {tempo & 255:02X} {tempo >> 8:02X}", bytes([0x21, fr, 0]),
              f"{what}: {tempo} итераций = {tempo * STEP * 1000:.0f} мс -> {fr} кадров")
    # цикл задержки 245C..2477 -> ожидание по кадрам
    if cpu == "i8080":
        # `ld bc,(MUS_TEMPO)` стало `push hl / ld hl,(nn) / ld b,h / ld c,l /
        # pop hl`; врезке нужны только первые три байта под jp.
        t = G(0x2581)
        patch(0x245C, "E5 2A %02X %02X 44" % (t & 255, t >> 8),
              jp(G_["V_MUS_WAIT"]) + bytes([0x00, 0x00]),
              "цикл задержки плеера -> V_MUS_WAIT")
    else:
        patch(0x245C, "ED 4B 81 25 C5 06 09 0E F0", jp(G_["V_MUS_WAIT"]),
              "цикл задержки плеера -> V_MUS_WAIT")
    # старт: последний переход SCR_INIT (ei / jp GAME_ENTRY) -> V_START
    ge = G(GAME_ENTRY)
    sig = bytes([0xFB, 0xC3, ge & 255, ge >> 8])
    hits = [a for a in range(0x5000, 0x5100) if bytes(mem[a:a + 4]) == sig]
    if len(hits) != 1:
        print(f"не нашёл единственный `ei / jp GAME_ENTRY` в SCR_INIT: {hits}")
        return 1
    patch_raw(hits[0] + 1, f"C3 {ge & 255:02X} {ge >> 8:02X}",
              jp(G_["V_START"]), "SCR_INIT -> V_START")

    if title:
        end = add_title(mem, out, L, inp, patch_raw, done)

    (out / f"spirits-port{tag}.rom").write_bytes(bytes(mem[BASE:end]))
    print(f"ввод/звук  4A00..{0x4A00 + len(inp) - 1:04X}  {len(inp)} б")
    print(f"связка     {GLUE_ORG:04X}..{GLUE_ORG + len(glue) - 1:04X}  {len(glue)} б "
          f"(V_START {G_['V_START']:04X}, V_ISR {G_['V_ISR']:04X})")
    for a, w in done:
        print(f"  врезка {a:04X}  {w}")
    print(f"{out / ('spirits-port%s.rom' % tag)}  {end - BASE} байт")
    return 0


if __name__ == "__main__":
    sys.exit(main())
