#!/usr/bin/env python3
"""Палитра на комнату: считает раздачу кодов по 87 комнатам.

    python3 tools/mk_room_pal.py                   -> src/v06/room_pal.inc
    python3 tools/mk_room_pal.py --scheme cpc21    -> src/v06/room_pal_cpc21.inc
    python3 tools/mk_room_pal.py --stats           -> только статистика

Схем две, и они НЕ смешиваются: `--scheme exolon` (по умолчанию) — та, что
описана ниже; `--scheme cpc21` — раскраска CPC (2 тайловые плоскости + 1
спрайтовая), её отдельное описание — у функции `cpc21()`.

ЗАЧЕМ.  На Векторе видимы три плоскости, то есть восемь кодов цвета
(docs/adapter-requirements.md, § 0a).  Раздача:

    код 0  — пусто/чёрный (пикселя нет);
    код 4  — БЕЛЫЙ: цвет всех подвижных объектов и белых чернил HUD.
             Спрайты кладутся XOR-ом в плоскость A000 (вес 4), поэтому над
             чёрным спрайт читается ровно как код 4;
    код 3  — «СКРЫТЫЙ ЧЁРНЫЙ»: чернила MSX 1 (чёрное на чёрном).  Пиксели
             ХРАНЯТСЯ (в плоскости C000+E000), но цвет чёрный.  Без этого
             кода пропадают титры (текст печатается в скрытые строки 17..19 и
             только потом переносится в видимые 9..11 процедурой D021) и
             панель HUD (её рисуют ДО того, как CF07 задаст цвет);
    коды 1, 2, 5, 6, 7 — пять СЛОТОВ чернил.

ПОЧЕМУ СЛОТОВ ПЯТЬ, А ЧЕРНИЛ ШЕСТЬ.  Кодов всего восемь, и один обязан
остаться под «скрытый чёрный» — иначе ломаются титры и HUD (см. выше).
Поэтому две чернила сливаются в один слот.  Слиты КРАСНЫЙ 8 и ПУРПУРНЫЙ 13 —
самая дешёвая пара: на CPC (docs/cpc-render.md § 3.3) ровно эта пара стоит
120 знакомест из 9473 (1.3 %), тогда как {2,7} стоит 1090, а {10,14} — 637.
Цвет слитого слота выбирается ПО КОМНАТЕ: те чернила из пары, которых в ней
больше.

ПОЧЕМУ «СКРЫТЫЙ ЧЁРНЫЙ» — КОД 3, А НЕ 7.  Спрайт над тайлом кода c даёт
c xor 4.  Если чёрным сделать 7, то спрайт над кодом 3 становится чёрным,
то есть НЕВИДИМЫМ, а код 3 — один из самых частых.  При чёрном 3 невидимым
становится спрайт над кодом 7, и код 7 отдаётся САМОМУ РЕДКОМУ слоту.

РАЗДАЧА КОДОВ ПО КОМНАТЕ.  Слоты сортируются по числу знакомест в комнате;
самый частый получает код 1, дальше 2, 5, 6, 7.  Коды 1 и 2 не содержат
бита 4, то есть эти чернила НЕ ЛОЖАТСЯ в плоскость A000 — ту же, куда XOR-ом
идут подвижные объекты.  § 0a просил под это три кода (1,2,3), но код 3 ушёл
под скрытый чёрный, поэтому их два.

ЦВЕТ НЕЗАНЯТЫХ СЛОТОВ.  § 0a предлагал отдать свободные коды под цвет
спрайта (белый).  Здесь они получают СВОИ цвета: на экране всегда ДВЕ
комнаты, а палитру задаёт только верхняя (как на CPC, docs/cpc-render.md
§ 1.3), и чернила нижней комнаты в раздаче не участвуют.  Отдав их код под
белый, мы покрасили бы половину экрана белым.

Формат таблицы (2 байта на комнату, 174 байта на все 87):
    байт 0: бит 7..4 = код слота 0 (| 8, если слитый слот показывает КРАСНЫЙ)
            бит 3..0 = код слота 1
    байт 1: бит 7..4 = код слота 2, бит 3..0 = код слота 3
    код слота 4 = 21 - (код0 + код1 + код2 + код3)   (1+2+5+6+7 = 21)
"""
from __future__ import annotations

import argparse
import collections
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD = ROOT / "ref/msx/orig/SPIRITS.2.orig.payload"
OUT = ROOT / "src/v06/room_pal.inc"

BASE = 0x82A0
ROOM_MAPS_M1 = 0x8446          # база списка комнат: ROOM_MAPS - 1
COLOR_BANK = 0xA79C            # 85 записей [высота][ширина][байты]

# палитра TMS9918 (RGB) — та же таблица, что в tools/marker/extract.py
TMS = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]

# чернила MSX -> слот; 8 и 13 слиты в слот 4
SLOT_OF_INK = {10: 0, 2: 1, 7: 2, 14: 3, 8: 4, 13: 4}
SLOT_INK = [10, 2, 7, 14, 13]          # представитель слота (у 4 — по комнате)
CODES = [1, 2, 5, 6, 7]                # коды по убыванию частоты слота


def v06_color(rgb) -> int:
    """RGB -> байт палитры Вектора BBGGGRRR."""
    r, g, b = rgb
    return ((b >> 6) << 6) | ((g >> 5) << 3) | (r >> 5)


# ---------------------------------------------------------------------------
#  СХЕМА «2 + 1»: раскраска CPC
# ---------------------------------------------------------------------------
CPC_RAM = ROOT / "build/cpc/ram.bin"       # дамп ОЗУ CPC (docs/cpc-render.md § 0.2)
OUT21 = ROOT / "src/v06/room_pal_cpc21.inc"
CPC_ROOM_MAPS_M1 = 0x2142                  # база списка комнат CPC
CPC_COLOR_BANK = 0x459D                    # он же конец списка

# Аппаратный код цвета Gate Array -> RGB.  ЗАМЕРЕНО в MAME по кайме
# (tools/cpc/probe_hwcolours.lua -> build/cpc/hwcolours.txt): 27 различных
# цветов на 32 кода, пять кодов — дубли (01=00, 08=05, 09=03, 10=04, 11=02),
# уровни 0 / 96 / 255.  Все 14 кодов, независимо измеренные по заставке
# (build/cpc/title/title_palette.txt), совпали.  Таблица HW в
# tools/cpc/io_analyze.py для кодов >= 0x10 НЕВЕРНА — ею не пользоваться.
CPC_HW = [
    (96, 96, 96), (96, 96, 96), (0, 255, 96), (255, 255, 96),
    (0, 0, 96), (255, 0, 96), (0, 96, 96), (255, 96, 96),
    (255, 0, 96), (255, 255, 96), (255, 255, 0), (255, 255, 255),
    (255, 0, 0), (255, 0, 255), (255, 96, 0), (255, 96, 255),
    (0, 0, 96), (0, 255, 96), (0, 255, 0), (0, 255, 255),
    (0, 0, 0), (0, 0, 255), (0, 96, 0), (0, 96, 255),
    (96, 0, 96), (96, 255, 96), (96, 255, 0), (96, 255, 255),
    (96, 0, 0), (96, 0, 255), (96, 96, 0), (96, 96, 255),
]

# Чернила MSX -> код цвета Вектора в схеме «2 + 1».
# Основа — таблица слияния CPC (docs/cpc-render.md § 3.2), доказанная
# побайтовой сверкой банков цвета MSX A79C и CPC 459D:
#     чернила 10, 14 -> перо 1 (всегда белое)
#     чернила  2,  7 -> перо 2 (цвет комнаты)
#     чернила  8, 13 -> перо 3 (цвет комнаты)
#     чернила      1 -> перо 0 (чёрный)
# Отличие от CPC одно:
#   * чернила панели HUD, которых в комнатах нет (3, 4, 5, 6, 9, 11, 12, 15),
#     разложены по ближайшему перу так же, как в схеме «Exolon»
#     (docs/render-paths.md, C.5): 11 -> к 10, 12 и 3 -> к 2, 4/5 -> к 7,
#     6/9 -> к 8, 15 (белый) -> перо 1, оно и так белое.
# ЧЕРНИЛА 1 — «чёрное на чёрном», ими игра ПРЯЧЕТ уже нарисованное (титры,
# панель HUD, значки OBJETOS).  С 2026-09-22 они дают код 0: пикселей в
# знакоместе нет вовсе.  Прежде код был 1 (белый), и спрятанное было видно —
# вторая копия строк титров и значки OBJETOS до подбора.  «Хранить, но не
# показывать» в схеме «2 + 1» не выражается, поэтому спрятанное теперь не
# рисуется, а рисуется заново в момент показа: титры — нативным
# растворением (A_DISSOLVE), панель — перестановкой «цвет раньше образа»
# (CF07 вызывается до DAE9), значки — при подборе (A_ICONCOL).
# Цвет подвижных объектов в схеме «2 + 1» — байт палитры Вектора.
# Светло-серый: r = 6/7, g = 6/7, b = 2/3.  Не белый: перо 1 (самый частый
# фон) белое, и белый герой на нём был бы невидим.
RP21_SPR = 0xB6

CPC21_INK2CODE = [
    0,  # 0  прозрачный: пикселя нет
    0,  # 1  ЧЁРНЫЙ НА ЧЁРНОМ -> кода нет, пикселей нет (2026-09-22)
    2,  # 2  зелёный
    2,  # 3  светло-зелёный (HUD) -> к зелёному
    2,  # 4  тёмно-синий  (HUD)   -> к циану
    2,  # 5  светло-синий (HUD)   -> к циану
    3,  # 6  тёмно-красный (HUD)  -> к красному
    2,  # 7  циан
    3,  # 8  красный
    3,  # 9  светло-красный (HUD) -> к красному
    1,  # 10 тёмно-жёлтый
    1,  # 11 светло-жёлтый (HUD)  -> к тёмно-жёлтому
    2,  # 12 тёмно-зелёный (HUD)  -> к зелёному
    3,  # 13 пурпурный
    1,  # 14 серый
    1,  # 15 белый
]


def cpc_rooms(ram: bytes):
    """Список комнат CPC: (адрес записи, число элементов).

    Индексатор комнат CPC 9296 шагает на 7, а не на 4, как MSX (D16C):
    впереди четвёрки соседей стоят 3 байта аппаратных кодов цвета перьев
    1, 2, 3 (docs/cpc-render.md § 1.3).  Отсюда шаг записи 9 + 4*n.
    """
    rooms, b = [], CPC_ROOM_MAPS_M1
    while b < CPC_COLOR_BANK:
        cnt = ram[b + 7]
        rooms.append((b, cnt))
        b += 9 + 4 * cnt
    assert b == CPC_COLOR_BANK, f"список комнат CPC кончился на {b:04X}"
    return rooms


def cpc21(stats: bool) -> int:
    """Палитра на комнату по данным CPC: код 1 белый, коды 2 и 3 — перья комнаты.

    Комнаты MSX и CPC сверяются поэлементно: у порта нет отдельного номера
    «комнаты CPC», он берёт запись с тем же номером, и это надо доказать, а
    не предположить.
    """
    ram = CPC_RAM.read_bytes()
    buf = PAYLOAD.read_bytes()
    rd = lambda addr: buf[addr - BASE]

    # список комнат MSX — тем же разбором, что у схемы «Exolon»
    msx, base = [], ROOM_MAPS_M1
    while base < COLOR_BANK:
        cnt = rd(base + 4)
        msx.append((base, cnt))
        base += 6 + 4 * cnt
    cpc = cpc_rooms(ram)
    assert len(msx) == len(cpc) == 87, f"комнат MSX {len(msx)}, CPC {len(cpc)}"

    # ДОКАЗАТЕЛЬСТВО соответствия: элементы комнат обязаны совпасть байт в байт
    diff = 0
    elems = 0
    for (mb, mc), (cb, cc) in zip(msx, cpc):
        if mc != cc:
            diff += 1
            continue
        for e in range(mc):
            elems += 1
            if [rd(mb + 6 + 4 * e + k) for k in range(4)] != \
                    list(ram[cb + 9 + 4 * e:cb + 9 + 4 * e + 4]):
                diff += 1
    assert diff == 0, f"комнаты MSX и CPC разошлись в {diff} местах"

    pens = [tuple(ram[b:b + 3]) for b, _ in cpc]
    bad1 = [i for i, p in enumerate(pens) if p[0] != 0x0B]
    assert not bad1, f"перо 1 не 0B в комнатах {bad1}"

    tab = bytearray()
    for p in pens:
        tab += bytes((v06_color(CPC_HW[p[1] & 0x1F]),
                      v06_color(CPC_HW[p[2] & 0x1F])))

    white = v06_color(CPC_HW[0x0B])
    print(f"комнат {len(cpc)}, элементов сверено {elems}, расхождений 0")
    print(f"перо 1 = 0B (белый {white:02X}) во всех {len(cpc)} комнатах")
    used2 = collections.Counter(p[1] for p in pens)
    used3 = collections.Counter(p[2] for p in pens)
    print("перо 2, коды:", " ".join(f"{k:02X}×{v}" for k, v in sorted(used2.items())))
    print("перо 3, коды:", " ".join(f"{k:02X}×{v}" for k, v in sorted(used3.items())))
    print("первые 5 комнат (перо2/перо3 -> байт Вектора):")
    for i in range(5):
        print(f"  {i:2d}  {pens[i][1]:02X}/{pens[i][2]:02X}  RGB"
              f" {CPC_HW[pens[i][1]]}/{CPC_HW[pens[i][2]]}"
              f"  -> {tab[2 * i]:02X}/{tab[2 * i + 1]:02X}")
    print(f"таблица {len(tab)} байт")
    if stats:
        return 0

    L = ["; СГЕНЕРИРОВАНО tools/mk_room_pal.py --scheme cpc21 — правки ТУДА.",
         "; Схема «2 + 1»: тайлы кодами 1..3 (плоскости C000 и E000),",
         "; подвижные объекты кодом 4 (плоскость A000).  Палитра комнаты —",
         "; из записи комнаты CPC (docs/cpc-render.md § 1.3): перо 1 всегда",
         "; белое (аппаратный код 0B), перья 2 и 3 свои у каждой комнаты.",
         "",
         "RP21_ROOMS\tequ\t%d" % len(cpc),
         "RP21_WHITE\tequ\t0x%02X" % white,
         "RP21_BLACK\tequ\t0x00",
         "; Цвет подвижных объектов (записи палитры 4..7: спрайт над тайлом",
         "; кода c даёт c xor 4).  Решение владельца 2026-09-22, § 0c",
         "; требований: светло-серый, а не белый, — белый занят пером 1,",
         "; самым частым фоном, и герой на нём пропадал бы.",
         "RP21_SPR\tequ\t0x%02X" % RP21_SPR,
         "",
         "; Чернила MSX -> код цвета: таблица слияния CPC (§ 3.2), ПОСТОЯННАЯ.",
         "; Имя то же, что у изменяемой таблицы схемы «Exolon», и живёт она",
         "; здесь же: так у неё один источник — этот генератор.",
         "INK2CODE:",
         "\tdb\t" + ",".join(str(c) for c in CPC21_INK2CODE[:8]),
         "\tdb\t" + ",".join(str(c) for c in CPC21_INK2CODE[8:]),
         "",
         "; на комнату 2 байта: цвет кода 2, цвет кода 3",
         "RP21_TAB:"]
    for i in range(0, len(tab), 16):
        L.append("\tdb\t" + ",".join("0x%02X" % v for v in tab[i:i + 16]))
    OUT21.write_text("\n".join(L) + "\n")
    print(f"{OUT21} — {len(tab)} байт таблицы")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stats", action="store_true")
    ap.add_argument("--scheme", choices=("exolon", "cpc21"), default="exolon")
    a = ap.parse_args()
    if a.scheme == "cpc21":
        return cpc21(a.stats)

    buf = PAYLOAD.read_bytes()
    rd = lambda addr: buf[addr - BASE]

    # банк цвета: 85 записей
    recs = []
    p = COLOR_BANK
    for _ in range(0x55):
        h, w = rd(p), rd(p + 1)
        recs.append((h, w, [rd(p + 2 + k) for k in range(h * w)]))
        p += 2 + h * w
    assert p == 0xAA6E, f"банк цвета кончился на {p:04X}, ждали AA6E"

    # список комнат
    rooms = []
    base = ROOM_MAPS_M1
    while base < COLOR_BANK:
        cnt = rd(base + 4)
        rooms.append((base, cnt))
        base += 6 + 4 * cnt
    assert len(rooms) == 87, f"комнат {len(rooms)}, ждали 87"

    tab = bytearray()
    stat_used = collections.Counter()
    stat_merge = collections.Counter()
    total_cells = 0
    for ri, (rbase, cnt) in enumerate(rooms):
        ink = collections.Counter()
        for e in range(cnt):
            code = rd(rbase + 6 + 4 * e + 3)
            h, w, data = recs[code % 0x55]
            for v in data:
                ink[v >> 4] += 1
        total_cells += sum(ink.values())
        slot = collections.Counter()
        for i, n in ink.items():
            if i in SLOT_OF_INK:
                slot[SLOT_OF_INK[i]] += n
        # порядок: по числу знакомест в комнате, при равенстве — по номеру слота
        order = sorted(range(5), key=lambda s: (-slot.get(s, 0), s))
        code_of = {}
        for k, s in enumerate(order):
            code_of[s] = CODES[k]
        stat_used[sum(1 for s in range(5) if slot.get(s, 0))] += 1
        red = ink.get(8, 0) > ink.get(13, 0)
        stat_merge["красный" if red else "пурпурный"] += 1
        b0 = ((code_of[0] | (8 if red else 0)) << 4) | code_of[1]
        b1 = (code_of[2] << 4) | code_of[3]
        assert code_of[4] == 21 - (code_of[0] + code_of[1] + code_of[2] + code_of[3])
        tab += bytes((b0, b1))

    cols = [v06_color(TMS[SLOT_INK[s]]) for s in range(4)]
    c_magenta, c_red = v06_color(TMS[13]), v06_color(TMS[8])
    white, black = v06_color(TMS[15]), 0x00

    print(f"комнат {len(rooms)}, знакомест с цветом {total_cells}")
    print("слотов чернил в комнате:",
          ", ".join(f"{k}: {v}" for k, v in sorted(stat_used.items())))
    print("цвет слитого слота 8/13:", dict(stat_merge))
    print("цвета слотов (Вектор BBGGGRRR): "
          + " ".join(f"{SLOT_INK[s]}={cols[s]:02X}" for s in range(4))
          + f" 13={c_magenta:02X} 8={c_red:02X} белый={white:02X}")
    print(f"таблица {len(tab)} байт")

    if a.stats:
        return 0

    L = ["; СГЕНЕРИРОВАНО tools/mk_room_pal.py — правки вносить ТУДА.",
         "; Раздача кодов цвета по комнатам, схема «Exolon» (§ 0a требований).",
         "; Коды: 0 пусто/чёрный, 3 скрытый чёрный, 4 белый (спрайты),",
         "; 1,2,5,6,7 — пять слотов чернил (красный 8 и пурпурный 13 слиты).",
         "",
         "RP_ROOMS\tequ\t%d" % len(rooms),
         "RP_CODE_BLACK\tequ\t3",
         "RP_CODE_WHITE\tequ\t4",
         "",
         "; цвет слотов 0..3 (чернила %s), затем слот 4: пурпурный / красный,"
         % ", ".join(str(SLOT_INK[s]) for s in range(4)),
         "; затем белый и чёрный",
         "RP_SLOTCOL:",
         "\tdb\t" + ",".join("0x%02X" % c for c in cols),
         "RP_MERGECOL:",
         "\tdb\t0x%02X,0x%02X" % (c_magenta, c_red),
         "RP_WHITECOL\tequ\t0x%02X" % white,
         "RP_BLACKCOL\tequ\t0x%02X" % black,
         "",
         "RP_TAB:"]
    for i in range(0, len(tab), 16):
        L.append("\tdb\t" + ",".join("0x%02X" % v for v in tab[i:i + 16]))
    OUT.write_text("\n".join(L) + "\n")
    print(f"{OUT} — {len(tab)} байт таблицы")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
