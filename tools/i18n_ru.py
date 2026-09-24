#!/usr/bin/env python3
"""РУССКИЙ ПЕРЕВОД Spirits — СТАДИЯ СБОРКИ ПОВЕРХ ГОТОВОГО ОБРАЗА.

    python3 tools/i18n_ru.py            # отчёт цифрами, ничего не пишет
    python3 tools/i18n_ru.py --png      # + лист шрифта build/i18n/font-ru.png
    python3 tools/i18n_ru.py --json     # + build/i18n/ru-expect.json для гейтов
    (как стадия сборки — вызывается из tools/build_v06_rom.py --lang ru)

ПОЧЕМУ ИМЕННО СТАДИЯ СБОРКИ, А НЕ ПРАВКА ДИЗАСМА.  Эталон `disasm/`,
`ref/` и гейты round-trip (verify_disasm/verify_orig/verify_v06) держат
равенство «образ Вектора == оригинал MSX, в котором переехали ровно
адресные операнды».  Перевод — ДРУГИЕ байты, и втащить их в эталон значит
сломать это равенство.  Поэтому перевод, как и `tools/repack_banks.py`
этапа E, получает УЖЕ СОБРАННЫЙ образ, СВЕРЯЕТ по каждому адресу байты,
которые ожидает увидеть (испанские), и кладёт на их место русские.  Если
хоть один байт не совпал — сборка падает: значит выше по цепочке что-то
поменялось и патч бьёт мимо.

ЧТО ПАТЧИТСЯ (все адреса — раскладка Вектора, docs/v06-memory.md):

  9F12..9F59   9 глифов кириллицы на месте МЁРТВЫХ кодов 0x67..0x6F
               (альтернативный логотип 1986, docs/i18n-inventory.md § 2.2)
  9F8A..9FF1  13 глифов кириллицы ПРИПИСАНЫ за таблицу шрифта, коды
               0x76..0x82 — адрес глифа у печатника 2:CE36 считается
               циклом `add hl,bc` без верхней границы кода
  9A09..9A93  шесть строк титров (139 б из 153 отведённых)
  18A4..18A9  таблица длин титров 2:CFA4 (6 байт)
  99E0..9A08  экран итога, 41 байт — ДЛИНА ТА ЖЕ, и «00%» осталось на тех
               же смещениях +0x14/+0x15, поэтому `ld hl,TEXT_ES+0x15`
               (153E) и `ld b,0x29` (1555) НЕ ПРАВЯТСЯ
  внутри 9B56..9BD4  три метки панели (5/7/7 знакомест — ширина та же)

БАЗА ШРИФТА НЕ ПЕРЕЕЗЖАЕТ (в этом дереве).  Два места с константой
FONT_BASE (операнды 1737 и 23FE, обе = 9BE2) остаются как есть: 22 новых
глифа нашлись, не двигая таблицу, — 9 в мёртвых кодах и 13 в хвосте
невидимой плоскости 9F89..9FFF (docs/v06-memory.md § 2, свободно 119 б).
Переезд всей таблицы реализован и включается FONT_RU_ADDR (см. ниже): это
понадобится после слияния с этапом E, когда освободится 407E..49FF.

ЭТАП E.  В дереве native-fills теневые таблицы спрайтов ЖИВЫ и лежат в
407E..49FF — класть туда шрифт НЕЛЬЗЯ.  После слияния с этапом E хватит
одной строки: FONT_RU_ADDR = 0x407E в tools/build_v06_rom.py.
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "i18n"

ROM_ORG = 0x0100

# --- АДРЕСА В РАСКЛАДКЕ ВЕКТОРА (docs/i18n-inventory.md § 6; оригинал MSX
# минус 0x1C00 для блока данных 8447..BB88 и минус 0xB700 для резидента).
FONT_BASE_DEFAULT = 0x9BE2      # значение операндов 1737/23FE = HUD_TILES+0x8C
FONT_BASE_SITES = (0x1737, 0x23FE)   # два места с константой базы шрифта
FONT_FIRST_CODE = 0x21
FONT_LAST_CODE_ES = 0x74        # последний код исходной таблицы (84 глифа)

TEXT_ES = 0x99E0                # экран итога, 41 байт
TEXT_TITLE = 0x9A09             # TEXT_ES+0x29 — шесть строк титров
TITLE_ROOM = 153                # B609..B6A1 — сколько байт отведено под них
CFA4 = 0x18A4                   # таблица длин титров (6 байт)
HUD_TILES = 0x9B56              # поток панели, 127 байт
END_LEN_SITE = 0x1555           # `ld b,0x29` — длина экрана итога
PCT_SITE = 0x153E               # `ld hl,TEXT_ES+0x15` — куда пишутся проценты
PCT_OFFS = (0x14, 0x15)         # смещения плейсхолдеров процента в строке

VIS_PLANE_END = 0x9FFF          # хвост невидимой плоскости кончается здесь

# --- ГЕОМЕТРИЯ ПЕЧАТИ (docs/i18n-inventory.md § 1).
SCREEN_COLS = 32
TITLE_START = (17, 8)           # de=0x1108 у 2:CF63 — одна на все шесть строк
TITLE_LABEL_ROW = 17            # метка
TITLE_NAME_ROW = 19             # имя (ряд 18 между ними всегда пуст)
END_START = (8, 8)              # de=0x0808 у 2:CC52, позиция фиксирована
DISSOLVE_SHIFT = 8              # D021 переносит скрытые ряды 16..23 в 8..15


def set_game_map(m: dict) -> None:
    """СБОРКА i8080: код игры пересобран по меткам и переехал, а перевод
    правит операнды ВНУТРИ него.  Адреса берутся из карты рекомпилятора
    (build/i8080/labels.json); адреса в блоке данных 6847..9F88 не меняются.
    """
    global FONT_BASE_SITES, CFA4, END_LEN_SITE, PCT_SITE
    f = lambda a: int(m["%04X" % a], 16)
    FONT_BASE_SITES = tuple(f(a) for a in FONT_BASE_SITES)
    CFA4, END_LEN_SITE, PCT_SITE = f(CFA4), f(END_LEN_SITE), f(PCT_SITE)


# ---------------------------------------------------------------------------
# 1. ШРИФТ: 22 кириллических глифа в стиле игрового шрифта
# ---------------------------------------------------------------------------
# Стиль снят с игровых глифов (`tools/i18n_ru.py --sheet` печатает их рядом):
# поле 7 колонок (биты 6..0, бит 7 всегда пуст), верхняя строка байта пустая,
# штрих 2 пикселя, вертикали слева — биты 6,5, справа — биты 1,0, полная
# перекладина — 0x7F.  Буквы А В Е К М Н О Р С Т Х НЕ рисуются: у них те же
# глифы, что у латинских A B E K M H O P C T X, и те же коды (см. CHAR_CODE).
GLYPHS_RU: dict[str, list[str]] = {
    # Б — В без правой половины верхней дуги
    "Б": ["........",
          ".######.",
          ".##.....",
          ".##.....",
          ".######.",
          ".##...##",
          ".##...##",
          ".######."],
    # Г — F без средней перекладины, засечки и ножка как у F
    "Г": ["........",
          ".#######",
          "..##...#",
          "..##....",
          "..##....",
          "..##....",
          "..##....",
          ".###...."],
    # Д — трапеция, опорная перекладина и две ножки
    "Д": ["........",
          "..#####.",
          "..##.##.",
          "..##.##.",
          "..##.##.",
          "..##.##.",
          ".#######",
          ".##...##"],
    # Ё — Е, сжатая на ряд, с точками в верхней (обычно пустой) строке
    "Ё": ["..##.##.",
          "........",
          ".#######",
          "..##....",
          "..#####.",
          "..##....",
          "..##....",
          ".#######"],
    # Ж — две наклонные и сквозная стойка по колонке 4
    "Ж": ["........",
          ".##.#.##",
          ".##.#.##",
          "..#####.",
          "...##...",
          "..#####.",
          ".##.#.##",
          ".##.#.##"],
    # З — верхняя и нижняя дуги, средняя перемычка справа
    "З": ["........",
          "..#####.",
          ".##...##",
          "......##",
          "...####.",
          "......##",
          ".##...##",
          "..#####."],
    # И — зеркальная N (диагональ снизу вверх)
    "И": ["........",
          ".##...##",
          ".##..###",
          ".##.####",
          ".####.##",
          ".###..##",
          ".##...##",
          ".##...##"],
    # Й — И, сжатая на ряд, с бревисом в верхней строке
    "Й": ["..#####.",
          "........",
          ".##...##",
          ".##..###",
          ".##.####",
          ".####.##",
          ".###..##",
          ".##...##"],
    # Л — правая стойка и наклонная левая ножка
    "Л": ["........",
          "...#####",
          "...##.##",
          "...##.##",
          "...##.##",
          "..###.##",
          "..##..##",
          ".##...##"],
    # П — H с перекладиной наверху вместо середины
    "П": ["........",
          ".#######",
          ".##...##",
          ".##...##",
          ".##...##",
          ".##...##",
          ".##...##",
          ".##...##"],
    # У — сход в хвост влево, хвост тот же, что у игровой J
    "У": ["........",
          ".##...##",
          ".##...##",
          "..##.##.",
          "...####.",
          ".....##.",
          ".##..##.",
          "..####.."],
    # Ф — дуга, рассечённая сквозной стойкой
    "Ф": ["........",
          "...##...",
          ".######.",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".######.",
          "...##..."],
    # Ц — две стойки, опорная перекладина и хвост справа
    "Ц": ["........",
          ".##...##",
          ".##...##",
          ".##...##",
          ".##...##",
          ".##...##",
          ".#######",
          "......##"],
    # Ч — чаша слева, стойка справа
    "Ч": ["........",
          ".##...##",
          ".##...##",
          ".##...##",
          "..######",
          "......##",
          "......##",
          "......##"],
    # Ш — три стойки на общей опоре
    "Ш": ["........",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".#######"],
    # Щ — Ш с хвостом
    "Щ": ["........",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".##.#.##",
          ".#######",
          "......##"],
    # Ъ — выносной элемент слева и дуга справа
    "Ъ": ["........",
          ".###....",
          "..##....",
          "..##....",
          "..#####.",
          "..##..##",
          "..##..##",
          "..#####."],
    # Ы — Ь и I
    "Ы": ["........",
          ".##...##",
          ".##...##",
          ".##...##",
          ".####.##",
          ".##.#.##",
          ".##.#.##",
          ".####.##"],
    # Ь — Б без верхней перекладины
    "Ь": ["........",
          ".##.....",
          ".##.....",
          ".##.....",
          ".######.",
          ".##...##",
          ".##...##",
          ".######."],
    # Э — З с перемычкой слева от правой стойки
    "Э": ["........",
          "..#####.",
          ".##...##",
          "......##",
          "...#####",
          "......##",
          ".##...##",
          "..#####."],
    # Ю — стойка, перемычка и овал
    "Ю": ["........",
          ".##.####",
          ".##.#..#",
          ".####..#",
          ".####..#",
          ".##.#..#",
          ".##.#..#",
          ".##.####"],
    # Я — зеркальная R
    "Я": ["........",
          "..###.##",
          ".##..###",
          ".##...##",
          ".##...##",
          "..######",
          "..##..##",
          ".##...##"],
}

# Коды кириллицы: девять ложатся в МЁРТВЫЕ коды исходной таблицы
# (0x67..0x6F, альт-логотип 1986), тринадцать приписываются за её конец
# (0x76..0x82).  Код 0x75 пропущен намеренно: его глиф лёг бы на 9F82..9F89,
# а 9F82..9F88 — последние семь байт блока данных игры (живые байты файла).
CYR_DEAD_CODES = list(range(0x67, 0x70))        # 9 штук
CYR_EXT_FIRST = 0x76                            # первый приписанный код
CYR_ORDER = "БГДЁЖЗИЙЛ" + "ПУФЦЧШЩЪЫЬЭЮЯ"      # 9 + 13 = 22

# Кириллица, у которой глиф уже есть в латинской части таблицы.
SHARED = {"А": "A", "В": "B", "Е": "E", "К": "K", "М": "M", "Н": "H",
          "О": "O", "Р": "P", "С": "C", "Т": "T", "Х": "X"}


def build_charmap() -> tuple[dict[str, int], dict[str, int]]:
    """{символ: код глифа} и {кириллическая буква: НОВЫЙ код} (только новые)."""
    cmap: dict[str, int] = {}
    for i, ch in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):
        cmap[ch] = 0x21 + i
    for i, ch in enumerate("123456789"):
        cmap[ch] = 0x3B + i
    cmap["0"] = 0x44
    cmap[":"] = 0x72
    cmap[" "] = 0x73
    cmap["%"] = 0x74
    for ru, la in SHARED.items():
        cmap[ru] = cmap[la]
    new: dict[str, int] = {}
    if len(CYR_ORDER) != len(CYR_DEAD_CODES) + 13:
        sys.exit("i18n_ru: список кириллицы разошёлся с раскладкой кодов")
    for i, ch in enumerate(CYR_ORDER):
        code = (CYR_DEAD_CODES[i] if i < len(CYR_DEAD_CODES)
                else CYR_EXT_FIRST + (i - len(CYR_DEAD_CODES)))
        cmap[ch] = code
        new[ch] = code
    return cmap, new


CHAR_CODE, CYR_NEW_CODE = build_charmap()


def glyph_bytes(ch: str) -> bytes:
    rows = GLYPHS_RU[ch]
    if len(rows) != 8 or any(len(r) != 8 for r in rows):
        sys.exit(f"i18n_ru: глиф {ch} не 8x8")
    out = bytearray()
    for r in rows:
        b = 0
        for k, c in enumerate(r):
            if c == "#":
                b |= 0x80 >> k
        out.append(b)
    return bytes(out)


# ---------------------------------------------------------------------------
# 2. ТЕКСТЫ.  Перевод утверждён владельцем 2026-09-22.
# ---------------------------------------------------------------------------
# Титры: пара «метка (скрытый ряд 17) / имя (скрытый ряд 19)», обе с
# колонки 8; между ними — скип-коды, уводящие курсор через весь ряд 18.
# Строка 0 («S P I R I T S») ОСТАЁТСЯ ЛАТИНИЦЕЙ И НЕТРОНУТОЙ.
TITLE_RU: list[tuple[str, str] | None] = [
    None,                                       # 0: SPIRITS — не трогаем
    ("ВЕРСИЯ ВЕКТОР 06Ц:", "БОРИС ЛИХАЧЕВ"),     # 1: CONVERSION: / CARLOS ARIAS
    ("ГРАФИКА:", "МИГЕЛЬ БЛАНКО ВИУ"),          # 2: GRAFICOS: / MIGUEL BLANCO VIU
    ("ПРИ УЧАСТИИ:", "ХАВЬЕР КАНО"),            # 3: COLABORACIONES: / JAVIER CANO
    ("МУЗЫКА:", "АЛЕХАНДРО АНДРЕ"),             # 4: MUSICA: / ALEJANDRO ANDRE
    ("ИЗДАТЕЛЬ:", "TOPO  SOFT"),                # 5: PRODUCCION: / TOPO  SOFT
]
# «TOPO  SOFT» — латиница и ДВА пробела, как в оригинале: имя издателя не
# переводится и не переверстывается.

# Экран итога.  Поля оставлены теми же, что у испанского, — ряд 8 колонки
# 8..25 (18 знакомест) и ряд 12 колонки 8..23 (16): тогда стёртая печатью
# площадь совпадает с оригинальной байт в байт по геометрии, а «00%»
# остаётся на смещениях +0x14/+0x15 и код патча процентов не трогается.
END_RU_TOP = "ПРОЙДЕНО"         # HAS COMPLETADO EL
END_RU_BOT = "ПРИКЛЮЧЕНИЯ"      # DE LA AVENTURA
END_TOP_FIELD = (8, 8, 18)      # ряд, колонка, ширина поля
END_BOT_FIELD = (12, 8, 16)
END_PCT_CELL = (10, 15)         # где стоит «00%» (ряд, колонка) — как в ES

# Панель.  Ширина каждой метки обязана совпасть с испанской (5/7/7), иначе
# поедет рамка справа: длина берётся из самого потока, счётчика длины нет.
HUD_RU = [("VIDAS", "ЖИЗНИ"), ("ENERGIA", "ЭНЕРГИЯ"), ("OBJETOS", "НАХОДКИ")]


def encode(text: str) -> bytes:
    out = bytearray()
    for ch in text:
        if ch not in CHAR_CODE:
            sys.exit(f"i18n_ru: нет глифа для {ch!r} в {text!r}")
        out.append(CHAR_CODE[ch])
    return bytes(out)


def skips(n: int) -> bytes:
    """Скип-коды на n ячеек.  Код < 0x20 = «пропустить N», 0 значило бы 256."""
    if n <= 0:
        sys.exit(f"i18n_ru: скип {n} — строка не помещается в свой ряд")
    out = bytearray()
    while n > 0:
        take = min(n, 0x1F)
        out.append(take)
        n -= take
    return bytes(out)


def title_stream(label: str, name: str) -> bytes:
    """Метка с (17,8), имя с (19,8): скип ровно на 64 − длина метки ячеек."""
    gap = (TITLE_NAME_ROW * SCREEN_COLS + TITLE_START[1]) - \
          (TITLE_LABEL_ROW * SCREEN_COLS + TITLE_START[1] + len(label))
    # Оригинал ставил РОВНО два скип-кода; держим то же число, пока лезет.
    if gap <= 0x1F * 2:
        a = (gap + 1) // 2
        sk = bytes([a, gap - a])
    else:
        sk = skips(gap)
    return encode(label) + sk + encode(name)


def centred(text: str, width: int) -> str:
    if len(text) > width:
        sys.exit(f"i18n_ru: {text!r} шире поля {width}")
    left = (width - len(text) + 1) // 2
    return " " * left + text + " " * (width - len(text) - left)


def end_stream() -> bytes:
    """Экран итога: три ряда, длина 41 байт и позиции процента — как в ES."""
    r0, c0, w0 = END_TOP_FIELD
    r2, c2, w2 = END_BOT_FIELD
    top = encode(centred(END_RU_TOP, w0))
    bot = encode(centred(END_RU_BOT, w2))
    cur = r0 * SCREEN_COLS + c0 + w0
    pct = END_PCT_CELL[0] * SCREEN_COLS + END_PCT_CELL[1]
    s1 = skips(pct - cur)
    mid = encode("00%")
    cur = pct + 3
    s2 = skips(r2 * SCREEN_COLS + c2 - cur)
    return top + s1 + mid + s2 + bot


def hud_patches(rom_at) -> list[tuple[str, int, bytes, bytes]]:
    """Три метки панели — по их месту в потоке 9B56 (ищем испанские коды)."""
    stream = rom_at(HUD_TILES, 127)
    out = []
    for es, ru in HUD_RU:
        if len(ru) != len(es):
            sys.exit(f"i18n_ru: {ru!r} шире {es!r} — поедет рамка панели")
        want = encode(es)
        pos = stream.find(want)
        if pos < 0 or stream.find(want, pos + 1) >= 0:
            sys.exit(f"i18n_ru: метка {es} в потоке панели не одна")
        out.append((f"панель {es} -> {ru}", HUD_TILES + pos, want, encode(ru)))
    return out


# ---------------------------------------------------------------------------
# 3. СБОРКА СПИСКА ПАТЧЕЙ
# ---------------------------------------------------------------------------
class Plan:
    """Что и куда лечь; каждый кусок несёт ОЖИДАЕМЫЕ байты для сверки."""

    def __init__(self, font_addr=None):
        self.font_addr = font_addr     # None = таблица остаётся на месте
        self.patches: list[tuple[str, int, bytes, bytes]] = []
        self.appends: list[tuple[str, int, bytes]] = []
        self.notes: list[str] = []

    def add(self, name, addr, expect, data):
        if len(expect) != len(data):
            sys.exit(f"i18n_ru: {name}: {len(expect)} ожидаемых против "
                     f"{len(data)} новых байт")
        self.patches.append((name, addr, bytes(expect), bytes(data)))

    def zones(self):
        z = [(a, a + len(d) - 1, n) for n, a, _e, d in self.patches]
        z += [(a, a + len(d) - 1, n) for n, a, d in self.appends]
        return sorted(z)


def build_plan(rom: bytes, font_addr: int | None = None) -> Plan:
    """rom — СОБРАННЫЙ образ .rom (грузится с ROM_ORG)."""
    def at(a, n):
        o = a - ROM_ORG
        if o < 0 or o + n > len(rom):
            sys.exit(f"i18n_ru: адрес {a:04X}+{n} вне образа")
        return rom[o:o + n]

    p = Plan(font_addr)

    # --- 3.1 база шрифта.  Сверяем ОБА места с константой (§ 6 описи).
    base = FONT_BASE_DEFAULT
    for site in FONT_BASE_SITES:
        got = struct.unpack("<H", at(site, 2))[0]
        if got != FONT_BASE_DEFAULT:
            sys.exit(f"i18n_ru: по {site:04X} ждали базу шрифта "
                     f"{FONT_BASE_DEFAULT:04X}, в образе {got:04X}")
    if font_addr is not None:
        # Переезд всей таблицы: font_addr — адрес ГЛИФА КОДА 0x21,
        # база = font_addr - 0x100 (печатник считает BASE+(код-1)*8).
        base = font_addr - 0x100
        last = max(CHAR_CODE.values())
        table = bytearray()
        for code in range(FONT_FIRST_CODE, last + 1):
            src = FONT_BASE_DEFAULT + (code - 1) * 8
            if code <= FONT_LAST_CODE_ES:
                table += at(src, 8)
            else:
                table += b"\0" * 8
        p.appends.append(("таблица шрифта (переезд)", font_addr, bytes(table)))
        for site in FONT_BASE_SITES:
            p.add(f"база шрифта {site:04X}", site,
                  struct.pack("<H", FONT_BASE_DEFAULT), struct.pack("<H", base))
        p.notes.append(f"таблица шрифта переехала на {font_addr:04X}, "
                       f"база {base:04X}, {len(table)} б")

    # --- 3.2 глифы кириллицы.
    dead_lo = base + (CYR_DEAD_CODES[0] - 1) * 8
    for ch in CYR_ORDER:
        code = CYR_NEW_CODE[ch]
        addr = base + (code - 1) * 8
        data = glyph_bytes(ch)
        if font_addr is None and code <= FONT_LAST_CODE_ES:
            p.add(f"глиф {ch} (код {code:02X})", addr, at(addr, 8), data)
        elif font_addr is None:
            p.appends.append((f"глиф {ch} (код {code:02X})", addr, data))
        else:
            # при переезде глифы пишутся прямо в новую таблицу
            off = addr - font_addr
            blk = p.appends[0]
            buf = bytearray(blk[2])
            buf[off:off + 8] = data
            p.appends[0] = (blk[0], blk[1], bytes(buf))
    if font_addr is None:
        ext_lo = base + (CYR_EXT_FIRST - 1) * 8
        ext_hi = base + (CYR_NEW_CODE[CYR_ORDER[-1]] - 1) * 8 + 7
        if ext_hi > VIS_PLANE_END:
            sys.exit(f"i18n_ru: приписанные глифы {ext_lo:04X}..{ext_hi:04X} "
                     f"вылезли за хвост невидимой плоскости {VIS_PLANE_END:04X}")
        # Образ кончался на 9F88; до первого приписанного глифа остаётся
        # дырка выравнивания — объявляем её зоной, иначе гейт verify_v06
        # справедливо назовёт её «изменённым байтом вне зон».
        pad_lo = ROM_ORG + len(rom)
        if ext_lo > pad_lo:
            p.appends.append(("дырка до приписанных глифов (нули)", pad_lo,
                              b"\0" * (ext_lo - pad_lo)))
        p.notes.append(f"глифы: 9 на мёртвых кодах {dead_lo:04X}.., "
                       f"13 приписаны {ext_lo:04X}..{ext_hi:04X}")

    # --- 3.3 титры + таблица длин.
    streams, lens = [], []
    for i, tr in enumerate(TITLE_RU):
        old_len = at(CFA4, 6)[i]
        if tr is None:
            streams.append(None)
            lens.append(old_len)
        else:
            s = title_stream(*tr)
            streams.append(s)
            lens.append(len(s))
    total = sum(lens)
    if total > TITLE_ROOM:
        sys.exit(f"i18n_ru: блок титров {total} б > отведённых {TITLE_ROOM}")
    blob, expect, a = bytearray(), bytearray(), TEXT_TITLE
    old_a = TEXT_TITLE
    for i, s in enumerate(streams):
        old = at(old_a, at(CFA4, 6)[i])
        old_a += len(old)
        blob += (old if s is None else s)
        expect += old
    # Испанские строки длиннее: сверяем ровно то, что перекрываем.
    p.add("титры (6 строк)", TEXT_TITLE, bytes(expect[:len(blob)]), bytes(blob))
    p.add("длины титров 2:CFA4", CFA4, at(CFA4, 6), bytes(lens))
    p.notes.append(f"титры: {total} б из {TITLE_ROOM} отведённых, "
                   f"хвост {TEXT_TITLE + total:04X}.."
                   f"{TEXT_TITLE + TITLE_ROOM - 1:04X} не читается")

    # --- 3.4 экран итога.  Длина обязана остаться 0x29, иначе поплывут
    # и `ld b,0x29` (1555), и адреса процентов (153E).
    es_end = at(TEXT_ES, 41)
    ru_end = end_stream()
    if len(ru_end) != 41:
        sys.exit(f"i18n_ru: экран итога {len(ru_end)} б, нужно 41")
    for off in PCT_OFFS:
        if ru_end[off] != CHAR_CODE["0"]:
            sys.exit(f"i18n_ru: по смещению +0x{off:02X} экрана итога не "
                     f"плейсхолдер процента, а {ru_end[off]:02X}")
    if at(END_LEN_SITE, 2) != bytes([0x06, 0x29]):
        sys.exit("i18n_ru: по 1555 не `ld b,0x29`")
    if at(PCT_SITE, 3) != bytes([0x21]) + struct.pack("<H", TEXT_ES + 0x15):
        sys.exit("i18n_ru: по 153E не `ld hl,TEXT_ES+0x15`")
    p.add("экран итога", TEXT_ES, es_end, ru_end)

    # --- 3.5 панель.
    for np_ in hud_patches(at):
        p.add(*np_)
    return p


def apply(rom: bytearray, plan: Plan) -> None:
    """Проверить ожидаемые байты и положить русские.  Падает при расхождении."""
    for name, addr, expect, data in plan.patches:
        o = addr - ROM_ORG
        got = bytes(rom[o:o + len(expect)])
        if got != expect:
            sys.exit(f"i18n_ru: {name} по {addr:04X}: в образе "
                     f"{got.hex()}, ждали {expect.hex()}")
        rom[o:o + len(data)] = data
    for name, addr, data in plan.appends:
        o = addr - ROM_ORG
        if o > len(rom):
            rom.extend(b"\0" * (o - len(rom)))
        rom[o:o + len(data)] = data


# ---------------------------------------------------------------------------
# 4. ОЖИДАЕМАЯ КАРТИНКА ДЛЯ ГЕЙТОВ
# ---------------------------------------------------------------------------
def layout(stream_text: list[tuple[int, str]], row0: int, col0: int):
    """(ряд, колонка, символ) по правилу курсора 2:CDF9/CE19.

    stream_text — список («скип N», текст) в порядке потока; проще передать
    уже разобранную последовательность элементов.
    """
    cells, row, col = [], row0, col0
    for kind, val in stream_text:
        if kind == 0:               # скип
            for _ in range(val if val else 256):
                col += 1
                if col >= SCREEN_COLS:
                    col, row = 0, row + 1
        else:
            for ch in val:
                cells.append((row, col, ch))
                col += 1
                if col >= SCREEN_COLS:
                    col, row = 0, row + 1
    return cells


def expectation(plan: Plan) -> dict:
    """Что ДОЛЖНО оказаться на экране — из русского ТЕКСТА, не из байтов."""
    base = plan.font_addr - 0x100 if plan.font_addr else FONT_BASE_DEFAULT
    title = []
    for i, tr in enumerate(TITLE_RU):
        if tr is None:
            continue
        label, name = tr
        gap = 64 - len(label)
        cells = layout([(1, label), (0, gap), (1, name)],
                       TITLE_LABEL_ROW, TITLE_START[1])
        title.append({
            "index": i, "label": label, "name": name,
            # D021/A_DISSOLVE переносит скрытые ряды на 8 вверх
            "cells": [[r - DISSOLVE_SHIFT, c, ch] for r, c, ch in cells],
        })
    r0, c0, w0 = END_TOP_FIELD
    r2, c2, w2 = END_BOT_FIELD
    top, bot = centred(END_RU_TOP, w0), centred(END_RU_BOT, w2)
    cur = r0 * SCREEN_COLS + c0 + w0
    pct = END_PCT_CELL[0] * SCREEN_COLS + END_PCT_CELL[1]
    end_cells = layout([(1, top), (0, pct - cur), (1, "00%"),
                        (0, r2 * SCREEN_COLS + c2 - (pct + 3)), (1, bot)],
                       r0, c0)
    hud = []
    for es, ru in HUD_RU:
        row = {"VIDAS": 0, "ENERGIA": 7, "OBJETOS": 11}[es]
        hud.append({"es": es, "ru": ru,
                    "cells": [[row, 24 + k, ch] for k, ch in enumerate(ru)]})
    return {
        "font_base": base,
        "charmap": {ch: CHAR_CODE[ch] for ch in sorted(CHAR_CODE)},
        "title": title,
        "end": {"cells": [[r, c, ch] for r, c, ch in end_cells],
                "pct_cells": [[END_PCT_CELL[0], END_PCT_CELL[1]],
                              [END_PCT_CELL[0], END_PCT_CELL[1] + 1]],
                "pct_addrs": [TEXT_ES + PCT_OFFS[0], TEXT_ES + PCT_OFFS[1]]},
        "hud": hud,
        "zones": [[lo, hi, n] for lo, hi, n in plan.zones()],
    }


# ---------------------------------------------------------------------------
# 5. ЛИСТ ШРИФТА
# ---------------------------------------------------------------------------
MINI = {
    "0": ["###", "#.#", "#.#", "#.#", "###"], "1": ["..#", "..#", "..#", "..#", "..#"],
    "2": ["###", "..#", "###", "#..", "###"], "3": ["###", "..#", "###", "..#", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"], "7": ["###", "..#", "..#", "..#", "..#"],
    "8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "###"],
    "A": ["###", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": ["###", "#..", "#..", "#..", "###"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
}


def png_write(path, width, height, get_rgb):
    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            row.extend(get_rgb(x, y))
        rows.append(bytes(row))

    def ch(t, dd):
        return (struct.pack(">I", len(dd)) + t + dd +
                struct.pack(">I", zlib.crc32(t + dd) & 0xFFFFFFFF))
    Path(path).write_bytes(
        b"\x89PNG\r\n\x1a\n" +
        ch(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) +
        ch(b"IDAT", zlib.compress(rows and b"".join(rows))) + ch(b"IEND", b""))


def font_sheet(path, rom: bytes, base: int, cols=12):
    """Лист ВСЕГО русского алфавита: 11 общих с латиницей + 22 новых."""
    alpha = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
    items = []
    for ch in alpha:
        code = CHAR_CODE[ch]
        if ch in GLYPHS_RU:
            items.append((ch, code, glyph_bytes(ch), True))
        else:
            o = base + (code - 1) * 8 - ROM_ORG
            items.append((ch, code, rom[o:o + 8], False))
    rows_n = (len(items) + cols - 1) // cols
    cw, chh = 9, 15
    W, H = cols * cw + 1, rows_n * chh + 1

    def rgb(x, y):
        gx, px = divmod(x, cw)
        gy, py = divmod(y, chh)
        if px == 8 or py == 14:
            return (60, 60, 60)
        idx = gy * cols + gx
        if idx >= len(items):
            return (0, 0, 0)
        _c, code, bm, new = items[idx]
        bg = (10, 40, 10) if new else (10, 10, 40)   # зелёный = дорисован
        if py < 8:
            return (255, 255, 255) if bm[py] & (0x80 >> px) else bg
        label, ly = "%02X" % code, py - 9
        if not (0 <= ly < 5):
            return bg
        ci, lx = divmod(px, 4)
        if ci >= 2 or lx >= 3:
            return bg
        m = MINI.get(label[ci])
        return (255, 255, 0) if m and m[ly][lx] == "#" else bg
    png_write(path, W, H, rgb)
    return len(items)


# ---------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser()
    # ВХОД — ИСПАНСКИЙ образ: стадия сверяет испанские байты, и запускать её
    # на уже переведённом образе бессмысленно (сверка не сойдётся).
    ap.add_argument("--rom", default=str(ROOT / "build/adapter/spirits-es.rom"))
    ap.add_argument("--font-addr", default=None,
                    help="переезд всей таблицы шрифта (адрес глифа кода 0x21)")
    ap.add_argument("--png", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--sheet", action="store_true",
                    help="напечатать новые глифы текстом")
    a = ap.parse_args()
    rom = bytearray(Path(a.rom).read_bytes())
    fa = int(a.font_addr, 0) if a.font_addr else None
    plan = build_plan(bytes(rom), fa)

    print(f"образ {a.rom}  {len(rom)} б")
    for n in plan.notes:
        print("  " + n)
    print("\n--- строки")
    for i, tr in enumerate(TITLE_RU):
        if tr is None:
            print(f"  титры {i}: не трогаем (S P I R I T S, латиница)")
            continue
        s = title_stream(*tr)
        print(f"  титры {i}: {tr[0]!r} / {tr[1]!r}  {len(s)} б  {s.hex()}")
    e = end_stream()
    print(f"  итог   : {len(e)} б  {e.hex()}")
    for es, ru in HUD_RU:
        print(f"  панель : {es} -> {ru} ({len(ru)} знакомест)")
    print("\n--- патчи")
    for n, addr, ex, d in plan.patches:
        print(f"  {addr:04X}..{addr + len(d) - 1:04X}  {len(d):4d} б  {n}"
              f"   ждём {ex[:8].hex()}{'..' if len(ex) > 8 else ''}")
    for n, addr, d in plan.appends:
        print(f"  {addr:04X}..{addr + len(d) - 1:04X}  {len(d):4d} б  {n} (дозапись)")
    if a.sheet:
        print("\n--- новые глифы")
        for ch in CYR_ORDER:
            bm = glyph_bytes(ch)
            print(f"  {ch} код {CYR_NEW_CODE[ch]:02X}  {bm.hex()}")
            for b in bm:
                print("      " + "".join("#" if b & (0x80 >> k) else "."
                                         for k in range(8)))
    apply(rom, plan)
    OUT.mkdir(parents=True, exist_ok=True)
    if a.png:
        n = font_sheet(OUT / "font-ru.png", bytes(rom),
                       plan.font_addr - 0x100 if plan.font_addr else FONT_BASE_DEFAULT)
        print(f"\nлист шрифта: build/i18n/font-ru.png ({n} букв)")
    if a.json:
        (OUT / "ru-expect.json").write_text(
            json.dumps(expectation(plan), ensure_ascii=False, indent=1))
        print("ожидаемая картинка: build/i18n/ru-expect.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
