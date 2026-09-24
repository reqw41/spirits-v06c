#!/usr/bin/env python3
"""Рекурсивный дизасм payload'ов Spirits (MSX, сдвиг +0x100).

Линейный sweep не годится: код перемешан с графикой. Обход идёт от entry
по CALL/JP/JR/RST; всё недостижимое остаётся `db`.

  python3 tools/disasm_msx.py            # канон +0x100 → disasm/msx/
  python3 tools/disasm_msx.py --seg 2
  python3 tools/disasm_msx.py --orig     # оригинал     → disasm/msx/orig/
  python3 tools/disasm_msx.py --reshift  # оригинал, собранный обратно на
                                         # +0x100 → disasm/msx/reshift/
  python3 tools/disasm_msx.py --v06      # раскладка Вектора-06Ц
                                         #              → disasm/msx/v06/

Дополнительные точки входа (таблицы переходов, обработчики, найденные
руками) — в tools/entries.json; они добавляются к штатным.

## Три режима вывода

РАЗБОР во всех трёх режимах один и тот же и идёт в координатах КАНОНА
(+0x100). Иначе нельзя: обход по потоку управления ходит по операндам, а в
каноне верны 815 операндов из 929, и только про оставшиеся 114 известно,
что они стухли (таблицы STALE/STALE_LIKELY/STALE_PTR). Если разбирать в
координатах оригинала, неверными станут как раз те 815 — обход уйдёт в
графику. Поэтому меняется только ПЕЧАТЬ:

  ADJ  поправка к каждому адресу рантайма при печати: org, equ, имена
       меток, адреса в комментариях. 0 — канон, -0x100 — оригинал.
  FIX  чинить ли стухшие операнды. В каноне их чинить нельзя (сломается
       round-trip), в оригинальной раскладке они УЖЕ верны — в образе
       лежит исходное значение, — поэтому печатаются символом по своему
       настоящему адресу, и ассемблер выдаёт тот же самый байт.

Отсюда и обратная проверка: FIX=1, ADJ=0 даёт образ, где пересчитаны ВСЕ
929 адресов. Он обязан отличаться от канона ровно в 114 байтах.

Адреса системных переменных MSX (SYSTEM) и копии в page 1 (PAGE1) при
переезде НЕ двигаются: первые принадлежат BIOS, вторые — промежуточному
буферу загрузки, который к раскладке игры отношения не имеет.

## Четвёртый режим: v06

Раскладка Вектора-06Ц двигает куски образа НА РАЗНЫЕ расстояния (часть
уезжает в низкую RAM, часть — в свободные плоскости экрана), поэтому одной
поправки ADJ мало. В этом режиме вместо неё работает кусочная карта V06_MAP
(см. adj()), а вывод режется на куски по V06_LAYOUT — каждый в свой .asm со
своим org. Разбор по-прежнему идёт в координатах канона.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/vendor"))
from z80dis import decode  # noqa: E402

# Режим вывода, см. шапку. Ставится set_mode() до build_all().
ADJ = 0
FIX = False
TAG = ""     # подкаталог вывода: "" | "orig" | "reshift" | "v06"
MAP = None   # кусочная карта переезда [(lo, hi, delta)] в координатах канона
FIXED: set[str] = set()   # имена, которые в этом режиме НЕ двигаются
# Переехавшие операнды: [(адрес канона, длина, было, стало)]. Заполняется
# render()'ом; verify_v06.py сверяет по нему байты собранного образа.
RELOCATED: list[tuple[int, int, int, int]] = []


def set_mode(adj: int = 0, fix: bool = False, tag: str = "",
             map=None, fixed: set[str] | None = None):
    global ADJ, FIX, TAG, MAP, FIXED
    ADJ, FIX, TAG, MAP = adj, fix, tag, map
    FIXED = fixed if fixed is not None else (SYS_NAMES | P1_NAMES)


def adj(a: int) -> int:
    """Поправка к адресу канона `a` в текущем режиме.

    Без карты — общий сдвиг ADJ (канон/оригинал/reshift). С картой каждый
    кусок едет на своё расстояние, а адрес вне карты не едет вовсе.
    """
    if MAP is None:
        return ADJ
    for lo, hi, d in MAP:
        if lo <= a <= hi:
            return d
    return 0


def reloc() -> bool:
    """Режим переезда (имена с зашитым адресом переименовываются)."""
    return bool(ADJ) or MAP is not None


def lbl(a: int) -> str:
    """Имя автометки по адресу канона (печатается в координатах режима)."""
    return f"L_{a + adj(a):04X}"


_NAME_ADDR = re.compile(r"^(.*_)([0-9A-F]{4})$")


def adj_name(name: str, addr: int) -> str:
    """Имя с зашитым собственным адресом переезжает вместе с адресом.

    `SPR_BANK_E14B` в оригинальной раскладке лежит по E04B, и оставить ему
    старое имя — значит развести ровно ту путаницу, из-за которой вся эта
    работа и затеялась. Переименовывается только суффикс, РАВНЫЙ адресу
    определения: `KBD_CHK_F3B5` (процедура по D784, F3B5 — строка и бит
    клавиатуры) и `THUNK_CDC5_D00` под правило не подпадают, адреса page 1
    сюда не попадают вовсе — они не переезжают и берутся из PAGE1.
    """
    if not reloc():
        return name
    m = _NAME_ADDR.match(name)
    if m and int(m.group(2), 16) == addr:
        return f"{m.group(1)}{addr + adj(addr):04X}"
    return name


def out_path(seg: dict, what: str) -> Path:
    """Путь вывода с учётом режима: disasm/msx[/TAG]/x.asm, build[/TAG]/x.bin."""
    p = Path(seg[what])
    return ROOT / (p.parent / TAG / p.name if TAG else p)

# Сегменты дизасма.
#
# Файлов два, но исполняемых образов — четыре: SPIRITS.1 не остаётся по
# адресу загрузки, а раздаётся двумя LDIR'ами в page 1, откуда стадия 2
# переносит его в верхнюю RAM. Цепочка (см. docs/msx-memory.md):
#
#   .1[0x0000..0x104A]  BC40: → 5000..604A   83D5: → D100..E14A  резидентный слой
#   .1[0x104B..0x2B3D]  BC40: → 64AA..7F9C   83E0: → E14B..FC28  (с 0x10C3)
#   .1[0x2B40..0x2B80]  остаётся на BC40 — собственно код стадии 1
#
# Поэтому один и тот же файл разбирается под разными ORG: "1" — как он
# лежит после BLOAD, "res"/"hi" — как он реально исполняется.
#
# file_off/length — окно внутри payload; по умолчанию весь файл.
SEGMENTS = {
    "1": dict(
        load=0x9100,
        entries=[0xBC40],
        payload="ref/msx/SPIRITS.1.payload",
        entry_name="STAGE1",
        out="disasm/msx/spirits1.asm",
        bin="build/spirits1.bin",
        orig=0x9000,
    ),
    "res": dict(
        load=0xD100,
        # D4BA убран: это не начало инструкции, а операнд 0x99 внутри
        # `out (0x99),a` по D4B9, и ссылок на него нет ни из .2, ни изнутри.
        # D4AA/D4AE оставлены: начала инструкций (хвост процедуры D481),
        # хотя как самостоятельные точки входа они тоже не подтвердились.
        # D3F8 оставлен и подтверждён: 0xE9 = `jp (hl)`, зовётся из 2:C78F.
        entries=[
            0xD3F8, 0xD3FD, 0xD406, 0xD411, 0xD420, 0xD428, 0xD433,
            0xD4AA, 0xD4AE, 0xD4B4, 0xD4DF, 0xD4F8, 0xD4FE,
        ],
        payload="ref/msx/SPIRITS.1.payload",
        file_off=0x0000,
        length=0x104B,
        entry_name="RESIDENT",
        out="disasm/msx/resident.asm",
        bin="build/resident.bin",
        orig=0xD000,
    ),
    "hi": dict(
        load=0xE14B,
        entries=[],
        payload="ref/msx/SPIRITS.1.payload",
        file_off=0x10C3,
        # Стадия 2 копирует 0x1ADE байт (6522..7FFF), но стадия 1 заполнила
        # page 1 лишь по 7F9C: хвост 7F9D..7FFF — неинициализированная RAM,
        # она уезжает в FBC6..FC28 и данными игры не является. Реальное окно
        # файла — .1[0x10C3..0x2B3D] = 0x1A7B байт → E14B..FBC5.
        length=0x1A7B,
        entry_name="HIMEM_BLOCK",
        out="disasm/msx/himem.asm",
        bin="build/himem.bin",
        orig=0xE04B,
    ),
    "2": dict(
        load=0x83A0,
        entries=[0x83A0],
        payload="ref/msx/SPIRITS.2.payload",
        entry_name="STAGE2",
        out="disasm/msx/spirits2.asm",
        bin="build/spirits2.bin",
        orig=0x82A0,
    ),
}

# Резидентный VDP/клава-слой: копируется в RAM выше конца payload, в файле
# этих байтов нет. Объявляем equ, чтобы call/jp собирались в те же адреса.
# Подробности — docs/msx-vdp-abi.md.
#
# Имена даны по телу процедуры, а не по чужим заметкам. Из исходного списка
# 14 адресов не подтвердились три: D4AA и D4AE — середина и `ret` процедуры
# D481, на них никто не ссылается; D4BA — вообще не начало инструкции
# (байт 0x99 внутри `out (0x99),a` по D4B9), ссылок тоже нет. Наоборот,
# подтвердились неожиданные: D3F8 — байт 0xE9 (`jp (hl)`) внутри `jr nz` по
# D3F7, его зовут как «call (hl)»; D4F8 — общий `ret`.
ABI = {
    # --- VDP: адресация и обмен с VRAM
    0xD3FD: "VDP_SET_RADDR",      # hl -> адрес чтения VRAM
    0xD406: "VDP_SET_WADDR",      # hl -> адрес записи VRAM
    0xD411: "VDP_FILL",           # заливка bc байт значением a с hl
    0xD420: "VDP_RD_BYTE",        # a <- VRAM[hl]
    0xD428: "VDP_WR_BYTE",        # VRAM[hl] <- a
    0xD433: "VDP_COPY_TO_VRAM",   # bc байт (de) -> VRAM[hl]
    0xD4B4: "VDP_RD_STRIDE8",     # чтение b*c байт с шагом 8 в буфер (de)
    0xD31D: "VDP_WR_STRIDE8",     # запись b*c байт с шагом 8 из буфера (de)
    # --- мелкие переходники
    0xD3F8: "CALL_HL",            # 0xE9 = jp (hl): call D3F8 == call (hl)
    0xD4F8: "RET_STUB",           # общий ret (он же хвост KBD_SCAN)
    0xD4FE: "THUNK_CDC5_D00",     # ld d,0x00 : jp CDC5
    0xD503: "THUNK_CDC5_D60",     # ld d,0x60 : jp CDC5
    # --- клавиатура
    0xD4DF: "KBD_SCAN",           # c = код клавиши -> флаг переноса
    0xD784: "KBD_CHK_F3B5",       # строка 0xF3, бит 5
    # --- адресная арифметика экрана
    0xD192: "SCR_ADDR_BIT13",     # (b,c) -> hl, бит 13
    0xD370: "SCR_ADDR_BIT14",     # (b,c) -> hl, бит 14, b = сдвиг
    0xD700: "ATTR_ADDR",          # (b,c) -> hl в буфере атрибутов F34D
    # --- банки спрайтов
    0xD344: "SPR_HDR",            # b = номер -> b,a = размеры, hl = битмап
    0xD352: "SPR_BANK_VAR",       # ld hl,nn — nn патчится (AB76 / E14B)
    0xD358: "SPR_BANK_HI",        # банк E14B (блок himem)
    0xD34C: "SPR_BANK_A89C",      # банк A89C в SPIRITS.2
    # --- звук
    0xDD69: "PSG_WR",             # a = регистр, c = значение
    0xDC3A: "MUS_START",          # запуск плеера по указателям DD7F..DD87
    0xE0E7: "MUS_TRACK_1",
    0xE119: "MUS_TRACK_2",
    # --- переходники к проигрывателю эффектов 84F5 (дескрипторы в page 1)
    0xD7DA: "SFX_64D7",
    0xD7E5: "SFX_64E6",
    0xD7F2: "SFX_64D7_x25",
    0xD888: "SFX_64B9",
    0xD88E: "SFX_64AA",
    0xD894: "SFX_64C8",
    0xD89A: "SFX_64F5",
}

# Цели, по которым обходу ходить НЕЛЬЗЯ: {ключ сегмента: {адрес}}.
#
# В SPIRITS.2 есть куски кода, у которых абсолютные операнды НЕ пережили
# сдвиг +0x100: они указывают ровно на 0x100 ниже настоящего адреса. Видно
# по тому, что target+0x100 попадает в начало реальной процедуры, а сам
# target — в середину инструкции или в таблицу. Примеры (блок C0FB..C25F и
# соседи):
#
#   C116 call 0xC051 -> C151      C15D call 0xD0A0 -> D1A0 (резидент)
#   C125 call 0xC0AF -> C1AF      C196 jp z,0xCAAF -> CBAF
#   C1FB call 0xCCFA -> CDFA      C247 call 0xCCCF -> CDCF
#   C8BD call 0xD21D -> D31D      C584 call 0xD600 -> D700
#   C8B0 call 0xD636 -> D736      CF2C jp nz,0xD149 -> D249
#
# Исправленные цели заведены в tools/entries.json как обычные точки входа,
# а по стухшим ходить запрещено: иначе обход разбирает как код таблицы и
# графику (так массив объектов CCBF..CD0C превращался в мусорные мнемоники).
NO_FOLLOW = {
    "2": {
        0xC051, 0xC062, 0xC0AF,   # -> C151, C162, C1AF
        0xC625,                   # -> C725
        0xCAAF, 0xCAB7,           # -> CBAF, CBB7
        0xCB1D,                   # -> CC1D
        0xCCCF, 0xCCFA,           # -> CDCF, CDFA (цели внутри массива объектов)
        0xD0A0,                   # -> D1A0, резидентная процедура
        # Сырые цели из обработчиков объектов BF09..BF8C: в каноне там лежат
        # адреса раскладки 82A0 (см. STALE), и по ним обход ушёл бы в
        # середину чужих инструкций. Настоящие цели — BEF3/BF1C/BF68/C3BF/
        # CA26/CA2C — заведены точками входа в tools/entries.json.
        0xBE1C, 0xBE68,           # -> BF1C, BF68 (соседние обработчики)
        0xC2BF,                   # -> C3BF
        0xC926, 0xC92C,           # -> CA26, CA2C
    },
}

# Именованные области данных: {ключ сегмента: {адрес: (ИМЯ, описание)}}.
#
# Обход по потоку даёт только код; всё остальное вываливается безымянными
# кусками `D_XXXX`. Здесь эти куски режутся по границам и получают имя —
# чтобы в asm было видно, где карты комнат, где спрайты, а где шрифт.
# Адрес обязан лежать внутри окна своего сегмента; сегменты 1 и 2 частично
# перекрываются по адресам, поэтому словарь и разложен по ключам.
#
# Основание для каждой записи — как к адресу обращается ЖИВОЙ код
# (см. описание). Где обращения нет, это сказано прямо.
DATA_REGIONS = {
    "2": {
        0x83EB: ("GFX_83EB",
                 "битовые шаблоны 8x8 (графика). Живой код сюда не"
                 " обращается: это данные, которые резидентный слой гонит"
                 " в VRAM по указателям из карт комнат"),
        0x8547: ("ROOM_MAPS",
                 "карты экранов/комнат до A89B. Запись начинается с 00,"
                 " дальше номер комнаты и 4-байтные элементы. Живой код"
                 " C60D..C70A патчит в них отдельные байты (двери/ключи):"
                 " 8748/86C7, 8ADE/8CFD, 8FAC/8F3F, 92AE/91C3, 9E7A/9ED9,"
                 " A33A/A347, A37C..A384, A460/A464, A5D7, A64C"),
        # Имя не SPR_BANK_A89C: так уже зовётся процедура выбора банка по
        # D34C в ABI, а одно имя на два адреса ассемблер разрешит молча и
        # не в ту сторону (ловилось round-trip'ом: ld hl,A89C собиралось
        # как ld hl,D34C).
        0xA89C: ("SPR_DATA_A89C",
                 "банк спрайтов: адресуется из резидентной SPR_BANK_A89C"
                 " (D34C)"),
        0xAB76: ("SPR_DATA_AB76",
                 "второй банк спрайтов: его адрес патчится в SPR_BANK_VAR"
                 " (D352); сюда же смотрит CEB2 (ld hl,0xAB76)"),
        0xB640: ("GFX_B640",
                 "битовые шаблоны, берутся из CBD5 (ld de,0xB640 /"
                 " ld de,0xB690)"),
        0xB6E0: ("TEXT_ES",
                 "тексты в кодах тайлов (0x21='A', 0x73=пробел):"
                 " «HAS COMPLETADO EL ...», «... DE LA AVENTURA»,"
                 " титры «SPIRITS CONVERSION / CARLOS ARIAS / GRAFICOS /"
                 " MIGUE...». Печатаются из CECD/CBA0"),
        0xB7A2: ("OBJ_TABLE_B7A2",
                 "массив объектов: 20 записей по 9 байт, B7A2..B855. C8DB"
                 " делает ld iy,0xB7A2 / ld b,0x14, а C942 — ld bc,0x09 /"
                 " add iy,bc. 20*9 = 0xB4, то есть массив кончается ровно"
                 " там, где начинается HUD_TILES. Указателей в записи нет:"
                 " читаются только байты iy+0..iy+4 (координаты, номер"
                 " комнаты, флаги)"),
        0xB856: ("HUD_TILES",
                 "0x7F байт строки статуса («VIDAS», «ENERGIA») — выводятся"
                 " из CECD (ld hl,0xB856 / ld b,0x7F)"),
        0xB8F9: ("TEXT_SHORT",
                 "три короткие строки (0x13/0x0B/0x0B байт) для CBA0/CBAF/"
                 "CBB7, печать через CEF9. Адрес исправлен: в каноне +0x100"
                 " эти три ld hl стухли и указывают на B7F9/B80C/B817, то"
                 " есть внутрь OBJ_TABLE_B7A2. Что правильное место именно"
                 " B8F9, видно по стыковке длин: B8F9+0x13 = B90C, +0x0B ="
                 " B917, +0x0B = B922 = начало VRAM_COLOR_ROWS"),
        0xB922: ("VRAM_COLOR_ROWS",
                 "0x18*8 = 192 байта атрибутов цвета: D007 заливает ими"
                 " VRAM с 0x20C0 по 8 байт на строку"),
        0xB9E2: ("FONT_GLYPHS",
                 "знакогенератор: глифы по 8 байт до конца области данных"
                 " (BC88)"),
        # --- дальше кодовая зона BC89..D100: здесь данные вкраплены между
        # процедурами, поэтому куски мелкие и адресуются поимённо.
        0xBE2D: ("DEAD_BE2D",
                 "мёртвый кусок: декодируется как код (call D0A0 / 9 nop /"
                 " call D3F8 / call CFAA / jp BB89), но D0A0, CFAA и BB89 —"
                 " данные, а не начала процедур. Похоже на остаток прошлой"
                 " сборки, чьи адреса не пережили сдвиг +0x100"),
        # BF09..BF8C БОЛЬШЕ НЕ ДАННЫЕ: шесть обработчиков заведены точками
        # входа в tools/entries.json (BF09/BF12/BF1A/BF36/BF3B/BF51, седьмой
        # BEF3 был заведён раньше), а все 19 их абсолютных операндов — в
        # STALE. Без этого куски печатались сырыми `db`, при переезде на
        # Вектор их операнды оставались с адресами MSX, и обработчики
        # читали/писали не свои поля: BF2A, BF23, BF14... попадали в блок
        # данных 8847..BF88 (то есть в карты комнат), а не в OBJ_BLOCK.
        # Найдено ловушкой «исполнение внутри области данных»
        # (tools/trap_stale_v06js.js): 1285 заходов за 1500 кадров.
        0xC009: ("OBJ_BLOCK_C009",
                 "блок состояния объектов: 4 записи по 0x0B байт, C009..C034."
                 " База берётся из BE70/BE7F/BE8A/BE95/BEA2 (ld iy,C009 /"
                 " C014 / C01F / C02A). Поля iy+2/3 и iy+8/9 читаются в hl"
                 " (BEBA..BEC9) и уходят в call (hl) — это 8 указателей на"
                 " обработчики. ВСЕ ВОСЕМЬ СТУХЛИ: сверка с кассетой"
                 " показывает, что инструмент сдвига данные не трогал вовсе,"
                 " и указатели остались от раскладки 82A0 (см."
                 " docs/msx-relocation.md)"),
        0xC2EA: ("GAME_VARS",
                 "главный блок переменных игры: 19 адресов, 105 обращений"
                 " из живого кода (C2EA..C2FA, C2FC, C2FE)"),
        0xCB29: ("DEAD_CB29",
                 "мёртвый обрывок: `jr nz` из него ведёт в середину"
                 " инструкции по CB10, а хвост повторяет код по 84B1"),
        0xCCBF: ("OBJ_ARRAY_CCBF",
                 "рабочий массив объектов: 3 записи по 0x0D байт (0x27 ="
                 " 39 = 3*13 байт копирует ldir из CB8D). База для iy в блоке"
                 " C0FB (там написано ld iy,0xCBBF — операнд не пережил сдвиг"
                 " +0x100). Отдельные поля читает C083: CCC5, CCC8, CCD2,"
                 " CCD5, CCDF. Указателей в записи НЕТ: пара iy+7/iy+8"
                 " читается как b,c (C1C2/C22C) и идёт в рисование спрайта"
                 " координатами, а не адресом"),
        0xCCE6: ("OBJ_ARRAY_INIT",
                 "начальные значения массива: CB8D делает"
                 " ld hl,0xCCE6 / ld de,0xCCBF / ld bc,0x27 / ldir"),
        0xCE7B: ("LEVEL_VARS",
                 "переменные уровня: CE7B, CE7C, CE7E, CE80, CE82, CE84,"
                 " CE86 — 22 обращения из живого кода"),
        0xCE88: ("JUMP_TABLE_CE88",
                 "таблица переходов, 6 слов: CE5A, CE56, CE4D, CE12, CE1F,"
                 " CE2C. Все шесть разобраны как код (точки входа в"
                 " tools/entries.json)"),
        0xCFAA: ("PARAM_TABLE_CFAA",
                 "таблица параметров: живой код ни разу не переходит сюда и"
                 " не читает отсюда по имени; начало повторяет структуру"
                 " LEVEL_VARS (35 90 1C 80 0F 50)"),
        0xD090: ("BUF_D090",
                 "20 нулевых байт (буфер) + 6-байтная таблица D0A4..D0A9;"
                 " процедура начинается только с D0AA"),
        0xD0EA: ("DEAD_D0EA",
                 "мёртвый хвост: его jr/djnz ведут в середину живой"
                 " процедуры D0CA, а команды дословно повторяют её"),
    },
    "hi": {
        0xE14B: ("SPR_BANK_E14B",
                 "банк спрайтов: ровно 53 записи [высота][ширина][битмап],"
                 " E14B..F2A7 (посчитано проходом по заголовкам). Адресуется"
                 " из резидентной SPR_HDR через SPR_BANK_HI (D358)"),
        0xF2A8: ("WORK_RAM",
                 "рабочая RAM игры: буферы объектов и буфер атрибутов 24x24."
                 " Содержимое файла здесь затирается на первом же кадре, так"
                 " что байты — мусор, важны только адреса. В каноне +0x100"
                 " СЮДА НИКТО НЕ ОБРАЩАЕТСЯ: все 41 обращение к буферам"
                 " остались от раскладки E04B (F1A9..F800) и бьют по хвосту"
                 " банка спрайтов — см. docs/msx-relocation.md"),
    },
}

# Копия SPIRITS.1 в page 1: она остаётся живой после загрузки, и часть кода
# адресует именно её. Диапазон 5000..7F9C пересекается с кодировкой адресов
# VRAM (бит 14 в hl, см. SCR_ADDR_BIT14), поэтому по диапазону здесь гадать
# нельзя — только поимённый список подтверждённых адресов.
PAGE1 = {
    0x5000: "P1_RESIDENT",    # копия SPIRITS.1[0000..104A]
    0x61A8: "P1_STACK_TOP",   # ld sp,61A8 на 83D2
    0x64AA: "P1_SFX_64AA",    # дескрипторы звуковых эффектов, 15 байт каждый
    0x64B9: "P1_SFX_64B9",
    0x64C8: "P1_SFX_64C8",
    0x64D7: "P1_SFX_64D7",
    0x64E6: "P1_SFX_64E6",
    0x64F5: "P1_SFX_64F5",
    0x6522: "P1_HIMEM",       # копия SPIRITS.1[10C3..2B3D], уезжает в E14B
}

# Единственный адрес НИЖЕ образа игры, который прежний сдвиг ТРОНУЛ.
#
# `res:DBEC ld hl,0x82F4` патчит операнд источника в `2:CF36` (чтение 8 байт
# узора). В кассетном оригинале на том же месте лежит `ld hl,0x81F4` — то
# есть адрес пережил сдвиг +0x100 и переезжать обязан. Это единственный
# такой случай: сплошная сверка с кассетой по всем операндам ниже 0x83A0
# (их 136 в разобранном коде) даёт ровно одно совпадение, остальные —
# константы: длины, адреса VRAM, ноты музыкального плеера (0x80xx..0x82xx)
# и дескрипторы эффектов в page 1.
#
# По диапазону такой адрес не поймать: 0x82F4 неотличим от `ld de,0x82A6`
# из плеера. Поэтому — поимённо, как и page 1.
LOWMEM = {
    0x82F4: "LOW_TILE_SRC",   # 0x81F4 в оригинале: 8 байт узора ниже образа
}

# Таблицы указателей в данных: {сегмент: {адрес: (записей, шаг, (смещения),
# описание)}}. Каждое слово по адресу base + i*шаг + смещение печатается как
# `dw МЕТКА`, а не сырыми байтами. Байты те же — проверяется round-trip'ом.
#
# Основание — живой код, который по этой таблице ходит (см. описание). Больше
# подтверждённых таблиц указателей в разобранной части нет: сплошной перебор
# пар байт в данных даёт сотни попаданий в начала инструкций, но почти все —
# случайные (графика), см. docs/msx-relocation.md.
POINTER_TABLES = {
    "2": {
        0xCE88: (6, 2, (0,),
                 "таблица переходов: CEB9 берёт из неё слово по индексу и"
                 " кладёт в hl, дальше jp (hl). Все 6 целей — начала"
                 " разобранных процедур"),
        0xC009: (4, 0x0B, (2, 8),
                 "массив состояния объектов: BE70/BE7F/BE8A/BE95/BEA2 делают"
                 " ld iy,C009 / C014 / C01F / C02A — шаг записи 0x0B. Поля"
                 " iy+2/3 и iy+8/9 читаются как hl (BEBA..BEC9) и уходят в"
                 " call (hl): это указатели на обработчики BDF3/BE09/BE12/"
                 "BE1A/BE36/BE3B/BE51"),
        # Патч дверей/ключей в картах комнат.  CE6A (Вектор 176A) ходит по
        # PARAM_TABLE_CEAA+0x24 двумя циклами: 11 слов подряд (`ld e,(hl) /
        # inc hl / ld d,(hl) / inc hl / ld (de),a`, a=0x36) и дальше 9 троек
        # «слово + байт» (`ld (de),a`, значение из третьего байта).  Все 20
        # слов — адреса ВНУТРИ ROOM_MAPS, и в каноне они СТУХШИЕ (инструмент
        # сдвига данные не трогал), см. STALE_PTR.
        #
        # Без этого переезд их не двигал, и на Векторе игра писала по числам
        # 85C7..A64C — это свободная зона 4A00..8846, то есть двери и ключи
        # в картах НЕ ПРОСТАВЛЯЛИСЬ вовсе.  Найдено ловушкой обращений в
        # дырки и свободную зону (tools/trap_stale_v06js.js): 279 630 записей
        # по 7F9C..8648 за 3000 кадров.
        0xCFCE: (11, 2, (0,),
                 "11 указателей в ROOM_MAPS: куда CE6A кладёт 0x36"),
        0xCFE4: (9, 3, (0,),
                 "9 записей «указатель в ROOM_MAPS + байт»: второй цикл CE7A"),
    },
    "res": {
        # Переменные плеера мелодий, третий голос.  res:DC87/DC88 (оригинал;
        # канон DD87, Вектор 2587) — УКАЗАТЕЛЬ НА ДАННЫЕ НОТЫ: плеер берёт
        # оттуда слово и каждый тик пишет по нему R4/R5 (данные FF FE по
        # оригинальному DFE5).  Слово лежит в db-области, поэтому ни сдвиг
        # +0x100, ни переезд на Вектор его не двигали, и на Векторе оно
        # показывало в ВИДИМУЮ ПЛОСКОСТЬ (DFE5) — плеер писал в регистры
        # мусор с экрана.  Звуковой агент закрыл это врезкой в
        # tools/build_port_rom.py (2587: DFE5 -> 28E5); здесь то же самое
        # делается честно, генератором, и попадает в проверки verify_v06.
        0xDD87: (1, 2, (0,),
                 "третий голос плеера: указатель на данные ноты, DFE5"),
    },
}

# Стухшие операнды: {сегмент: {адрес инструкции: правильное значение}}.
#
# Сдвиг +0x100 пересчитал не все абсолютные адреса. Эти — не пересчитал, и
# символизировать их НЕЛЬЗЯ: метка увезла бы их вместе со всеми, а они и так
# указывают не туда. Печатаются числом с пометкой в комментарии.
#
# Таблица не выдумана, а доказана: байты инструкции в дисковом образе по
# адресу A совпадают с кассетными (оригинал, не сдвинут) по A-0x100 —
# значит, операнд остался от старой раскладки. Пересобрать список:
#   python3 tools/verify_shift.py --emit
# verify_shift.py сверяет эту таблицу со своим расчётом и краснеет при
# расхождении.
STALE = {
    "2": {
        # --- обработчики объектов BF09..BF8C (оригинал BE09..BE8C).
        # Область заведена кодом точками входа BF09/BF12/BF1A/BF36/BF3B/BF51
        # (tools/entries.json).  Инструмент сдвига +0x100 данные не трогал,
        # поэтому ВСЕ абсолютные операнды здесь остались от раскладки 82A0 —
        # ровно тот же случай, что и 8 указателей OBJ_BLOCK_C009.
        0xBF09: 0xC02A,   # ld a,(0xBF2A)     поле OBJ_BLOCK_C009+0x21
        0xBF12: 0xBEF3,   # call 0xBDF3       обработчик BEF3
        0xBF33: 0xCA2C,   # jp 0xC92C
        0xBF38: 0xCA26,   # jp 0xC926
        0xBF3B: 0xC02A,   # ld a,(0xBF2A)
        0xBF3F: 0xC02A,   # ld (0xBF2A),a
        0xBF44: 0xBF68,   # call z,0xBE68     соседний обработчик
        0xBF53: 0xBF1C,   # call 0xBE1C       соседний обработчик
        0xBF56: 0xC3BF,   # call 0xC2BF
        0xBF5B: 0xC023,   # ld a,(0xBF23)
        0xBF60: 0xC023,   # ld (0xBF23),a
        0xBF65: 0xCA26,   # jp 0xC926
        0xBF68: 0xC014,   # ld (0xBF14),a
        0xBF6B: 0xC02B,   # ld a,(0xBF2B)
        0xBF6E: 0xC015,   # ld (0xBF15),a
        0xBF71: 0xC02E,   # ld hl,(0xBF2E)
        0xBF78: 0xC031,   # ld a,(0xBF31)
        0xBF7B: 0xC01B,   # ld (0xBF1B),a
        0xBF87: 0xC018,   # ld (0xBF18),hl
        0xBEFF: 0xC56C,   # call 0xC46C
        0xC0FB: 0xCCBF,   # ld iy,0xCBBF
        0xC109: 0xC162,   # call 0xC062
        0xC10C: 0xC2F6,   # ld a,(0xC1F6)
        0xC116: 0xC151,   # call 0xC051
        0xC119: 0xC9F2,   # call 0xC8F2
        0xC120: 0xC179,   # call nz,0xC079
        0xC125: 0xC1AF,   # call 0xC0AF
        0xC12A: 0xC151,   # call 0xC051
        0xC12F: 0xCE7B,   # ld a,(0xCD7B)
        0xC15D: 0xD1A0,   # call 0xD0A0
        0xC163: 0xC1E8,   # jp z,0xC0E8
        0xC170: 0xC1E2,   # ld hl,0xC0E2
        0xC185: 0xC725,   # jp nz,0xC625
        0xC188: 0xCE86,   # ld a,(0xCD86)
        0xC18F: 0xCCD5,   # ld (0xCBD5),a
        0xC192: 0xCCC8,   # ld a,(0xCBC8)
        0xC196: 0xCBAF,   # jp z,0xCAAF
        0xC19B: 0xCE84,   # ld a,(0xCD84)
        0xC1A2: 0xCCC8,   # ld (0xCBC8),a
        0xC1A5: 0xCCD5,   # ld a,(0xCBD5)
        0xC1A9: 0xCBB7,   # jp z,0xCAB7
        0xC1AC: 0xCBA0,   # jp 0xCAA0
        0xC1B2: 0xC009,   # ld a,(0xBF09)
        0xC1B8: 0xCCD5,   # ld a,(0xCBD5)
        0xC1BD: 0xCCC8,   # ld a,(0xCBC8)
        0xC1C8: 0xC00E,   # ld a,(0xBF0E)
        0xC1D3: 0xC00D,   # ld a,(0xBF0D)
        0xC1E0: 0xBCD4,   # ld (0xBBD4),a
        0xC1FB: 0xCDFA,   # call 0xCCFA
        0xC232: 0xC2F6,   # ld a,(0xC1F6)
        0xC23A: 0xCE7B,   # ld a,(0xCD7B)
        0xC247: 0xCDCF,   # call 0xCCCF
        0xC24D: 0xD26C,   # call 0xD16C
        0xC3BF: 0xC023,   # ld bc,(0xBF23)
        0xC497: 0xC747,   # call 0xC647
        0xC49B: 0xC2EA,   # ld (0xC1EA),a
        0xC584: 0xD700,   # call 0xD600
        0xC74D: 0xF3B9,   # ld hl,0xF2B9
        0xC78F: 0xD4F8,   # call 0xD3F8
        0xC7CC: 0xF68D,   # ld de,0xF58D
        0xC7D8: 0xF68F,   # ld hl,0xF58F
        0xC7DB: 0xF68D,   # ld de,0xF58D
        0xC7E6: 0xF68D,   # ld de,0xF58D
        0xC7F1: 0xF68D,   # ld de,0xF58D
        0xC83F: 0xF694,   # ld de,0xF594
        0xC855: 0xF694,   # ld de,0xF594
        0xC874: 0xF694,   # ld de,0xF594
        0xC881: 0xF694,   # ld de,0xF594
        0xC894: 0xE2C7,   # jp c,0xE1C7
        0xC897: 0xF694,   # ld de,0xF594
        0xC89D: 0xC8A5,   # ld (0xC7A5),hl
        0xC8B0: 0xD736,   # call 0xD636
        0xC8B6: 0xF694,   # ld de,0xF594
        0xC8BD: 0xD31D,   # call 0xD21D
        0xC8C3: 0xF694,   # ld de,0xF594
        0xC8CA: 0xD31D,   # call 0xD21D
        0xCB58: 0xF3B9,   # ld hl,0xF2B9
        0xCB5B: 0xF3BA,   # ld de,0xF2BA
        0xCBA0: 0xB8F9,   # ld hl,0xB7F9
        0xCBAA: 0xC09A,   # ld (0xBF9A),a
        0xCBAF: 0xB90C,   # ld hl,0xB80C
        0xCBB7: 0xB917,   # ld hl,0xB817
        0xCBBF: 0xCEF9,   # call 0xCDF9
        0xCBC7: 0xC78A,   # call 0xC68A
        0xCBCA: 0xCE42,   # ld a,(0xCD42)
        0xCBCF: 0xCE42,   # ld (0xCD42),a
        0xCBD2: 0xCB0C,   # jp 0xCA0C
        0xCC0C: 0xD31D,   # call 0xD21D
        0xCC2E: 0xCCB2,   # jp z,0xCBB2
        0xCCBC: 0xCC1D,   # jp 0xCB1D
        0xCD1B: 0xF3B9,   # ld hl,0xF2B9
        0xCEC9: 0xCD7B,   # ld (0xCC7B),hl
        0xCF2C: 0xD249,   # jp nz,0xD149
        # Найдено при переезде на Вектор: инструкция C1E8 в каноне вообще не
        # разбиралась (ссылка на неё — стухший операнд C163 jp z,0xC0E8), и
        # её `call` печатался байтами внутри области данных. Обе точки входа
        # добавлены в tools/entries.json.
        0xC1E8: 0xCC12,   # call 0xCB12
    },
    "res": {
        0xD1F2: 0xF329,   # ld ix,0xF229
        0xD202: 0xF87E,   # ld hl,0xF77E
        0xD205: 0xF87F,   # ld de,0xF77F
        0xD20F: 0xF8FE,   # ld hl,0xF7FE
        0xD212: 0xF8FF,   # ld de,0xF7FF
        0xD21F: 0xF87E,   # ld (0xF77E),hl
        0xD22F: 0xF8FE,   # ld hl,0xF7FE
        0xD23B: 0xF8FD,   # ld hl,0xF7FD
        0xD387: 0xF44D,   # ld hl,0xF34D
        0xD38A: 0xF44D,   # ld de,0xF34D
        0xD3AC: 0xD520,   # ld a,(0xD420)
        0xD3B0: 0xD518,   # ld a,(0xD418)
        0xD3BC: 0xD51A,   # ld hl,(0xD41A)
        0xD3DE: 0xF2A9,   # ld de,0xF1A9
        0xD3F9: 0xF2A9,   # ld hl,0xF1A9
        0xD590: 0xF8FE,   # ld hl,0xF7FE
        0xD59B: 0xF44D,   # ld hl,0xF34D
        0xD59E: 0xF44E,   # ld de,0xF34E
        0xD5A9: 0xF56D,   # ld hl,0xF46D
        0xD5AC: 0xF56E,   # ld de,0xF46E
        0xD5E8: 0xF44D,   # ld bc,0xF34D
        0xD710: 0xF44D,   # ld bc,0xF34D
        0xD742: 0xF68D,   # ld hl,0xF58D
        0xD745: 0xF68E,   # ld de,0xF58E
        0xD764: 0xF87E,   # ld hl,0xF77E
        0xD770: 0xF900,   # ld hl,0xF800
        0xD77C: 0xF329,   # ld ix,0xF229
        0xDBE6: 0xDA8E,   # jp 0xD98E
    },
}

# То же, но кассетой не проверяется: 83A0..84D6 в кассетном образе не
# покрыто. Значение F58D — из того же семейства, что 22 доказанных стухших
# обращения к буферам рабочей RAM, и в этой же процедуре соседний операнд
# (83D8 ld de,0xD100) пересчитан верно — значит, инструмент сдвига по этой
# области ходил и именно высокие адреса пропускал.
STALE_LIKELY = {
    "2": {
        0x8484: 0xF68D,   # ld de,0xF58D
        0x849D: 0xF68D,   # ld hl,0xF58D
        0x84B7: 0xF68D,   # ld de,0xF58D
        0x84C3: 0xF68D,   # ld de,0xF58D
    },
}


# Стухшие указатели В ДАННЫХ: {сегмент: {адрес слова: правильное значение}}.
#
# Инструмент сдвига данные почти не трогал. Это видно напрямую: во всём окне
# B640..D100, где кассетный эталон описывает тот же образ, он изменил в
# данных ровно 6 байт — старшие байты шести слов JUMP_TABLE_CE88. Всё
# остальное в данных осталось от раскладки 82A0, в том числе 8 указателей
# OBJ_BLOCK_C009: слова по C00B..C032 в дисковом образе побайтово равны
# кассетным по BF0B..BF32.
STALE_PTR = {
    "2": {
        # --- 20 указателей патча дверей/ключей в PARAM_TABLE_CEAA+0x24
        # (канон = оригинал + 0x100).  Основание — то же, что у C00B..C032:
        # инструмент сдвига данные не трогал, и слова остались от 82A0.
        0xCFCE: 0x8748,   # в образе 0x8648
        0xCFD0: 0x8ADE,   # в образе 0x89DE
        0xCFD2: 0x8FAC,   # в образе 0x8EAC
        0xCFD4: 0x92AE,   # в образе 0x91AE
        0xCFD6: 0xA64C,   # в образе 0xA54C
        0xCFD8: 0x9E7A,   # в образе 0x9D7A
        0xCFDA: 0xA37C,   # в образе 0xA27C
        0xCFDC: 0xA380,   # в образе 0xA280
        0xCFDE: 0xA384,   # в образе 0xA284
        0xCFE0: 0xA460,   # в образе 0xA360
        0xCFE2: 0xA464,   # в образе 0xA364
        0xCFE4: 0x86C7,   # в образе 0x85C7
        0xCFE7: 0x8CFD,   # в образе 0x8BFD
        0xCFEA: 0x8F3F,   # в образе 0x8E3F
        0xCFED: 0x91C3,   # в образе 0x90C3
        0xCFF0: 0x9ED9,   # в образе 0x9DD9
        0xCFF3: 0x9F3F,   # в образе 0x9E3F
        0xCFF6: 0xA347,   # в образе 0xA247
        0xCFF9: 0xA403,   # в образе 0xA303
        0xCFFC: 0xA5D7,   # в образе 0xA4D7
        0xC00B: 0xBEF3,
        0xC011: 0xBF1A,
        0xC016: 0xBEF3,
        0xC01C: 0xBF36,
        0xC021: 0xBF12,
        0xC027: 0xBF51,
        0xC02C: 0xBF09,
        0xC032: 0xBF3B,
    },
    "res": {
        # То же, что у слов ROOM_MAPS: данные сдвиг +0x100 не трогал, поэтому
        # в каноне слово осталось от раскладки D000 (в образе DFE5, настоящий
        # канонический адрес E0E5).
        0xDD87: 0xE0E5,
    },
}


def stale_fix(key: str, pc: int) -> int | None:
    """Правильное значение стухшего операнда в координатах канона."""
    if pc in STALE.get(key, {}):
        return STALE[key][pc]
    return STALE_LIKELY.get(key, {}).get(pc)


def stale_at(key: str, pc: int) -> tuple[int, str] | None:
    """(правильное значение, пометка) для стухшего операнда, иначе None.

    В режиме FIX возвращает None: там стухших нет — операнд печатается
    символом по своему настоящему адресу (см. шапку).
    """
    if FIX:
        return None
    if pc in STALE.get(key, {}):
        return STALE[key][pc], "СТУХШИЙ ОПЕРАНД, должно быть"
    if pc in STALE_LIKELY.get(key, {}):
        return STALE_LIKELY[key][pc], "СТУХШИЙ ОПЕРАНД (по аналогии), должно быть"
    return None

# Точки BIOS/системы, встречающиеся в обоих сегментах.
SYSTEM = {
    0x0024: "BIOS_ENASLT",
    0x0072: "BIOS_CHGCLR",
    0x00A8: "PORT_PSLOT",  # не BIOS, но адрес известен
    0xF3E0: "RG1SAV",
    0xF3EB: "BDRCLR",
    0xFD9F: "H_KEYI",
    0xFFFF: "SSLOT_REG",
}


def seg_bytes(seg: dict) -> bytes:
    """Окно payload, которое покрывает сегмент."""
    data = (ROOT / seg["payload"]).read_bytes()
    off = seg.get("file_off", 0)
    ln = seg.get("length")
    # length может выходить за конец файла: стадия 2 копирует 0x1ADE байт,
    # а .1 столько не заполнил — хвост в page 1 остаётся мусором.
    return data[off : off + ln] if ln else data[off:]


def load_mem(seg: dict) -> tuple[bytearray, int, int]:
    data = seg_bytes(seg)
    mem = bytearray(0x10000)
    base = seg["load"]
    mem[base : base + len(data)] = data
    return mem, base, base + len(data)


def disasm_reachable(mem: bytearray, entries: list[int], base: int, end: int,
                     no_follow: set[int] | None = None):
    """Обход по потоку управления. Возвращает {addr: Insn}.

    no_follow — адреса, на которые НЕ переходить (стухшие операнды, см.
    NO_FOLLOW). Сами entry из этого множества не исключаются.
    """
    no_follow = no_follow or set()
    code: dict[int, object] = {}
    work = list(entries)
    seen = set()
    while work:
        pc = work.pop()
        if pc in seen or not (base <= pc < end):
            continue
        seen.add(pc)
        while base <= pc < end:
            if pc in code:
                break
            try:
                ins = decode(mem[pc:], pc)
            except Exception:
                break
            if pc + ins.length > end:
                break  # инструкция не помещается в окно — это уже данные
            code[pc] = ins
            for t in ins.targets:
                if base <= t < end and t not in no_follow:
                    work.append(t)
            # z80dis отдаёт `ret cc` с flow='ret' наравне с безусловным `ret`.
            # Для обхода это неверно: условный возврат не обрывает поток, за
            # ним продолжается код. Отличаем по мнемонике: у условного всегда
            # есть операнд-условие ("ret nz"), у безусловных пробела нет
            # ("ret", "reti", "retn").
            if ins.flow in ("jump", "ret", "dyn", "halt") \
                    and not ins.fmt.startswith("ret "):
                break
            pc += ins.length
    return code


# Сегменты, которые живут в памяти ОДНОВРЕМЕННО и поэтому образуют одно
# адресное пространство: игра, резидентный слой и блок верхней памяти.
# Сегмент "1" в него не входит — это образ SPIRITS.1 в момент BLOAD, к
# моменту игры он затёрт, и его адреса 9100..BC80 означают совсем другое.
RUNTIME_SEGS = ("2", "res", "hi")

# Диапазон, в котором 16-битную константу (`ld hl,nn`) можно считать адресом
# внутри образа. Нижняя граница — начало SPIRITS.2, верхняя — конец блока
# верхней памяти. Ниже 83A0 лезть нельзя: адреса VRAM игра держит в hl с
# установленным битом 14 (SCR_ADDR_BIT14), и они дают 4000..7FFF — те же
# числа, что page-1 копия. Поэтому page-1 символизируется только поимённо
# (PAGE1), а не по диапазону.
IMM_LO, IMM_HI = 0x83A0, 0xFBC6


def layout(code: dict, base: int, end: int, regions: dict):
    """Раскладка сегмента: что печатается кодом, что данными.

    Возвращает (emitted, gaps, overlaps):
      emitted  — адреса инструкций в порядке вывода;
      gaps     — куски данных (start, stop, имя), порезанные по DATA_REGIONS;
      overlaps — цели, попавшие внутрь уже выведенной инструкции.

    Считается ДО рендера: адресное пространство символов строится по этой
    же раскладке, иначе `ИМЯ+смещение` указывало бы на несуществующий блок.
    """
    emitted: list[int] = []
    gaps: list[tuple[int, int, str]] = []
    overlaps: list[int] = []

    def cut(a: int, b: int):
        cuts = [x for x in sorted(regions) if a < x < b]
        for s, e in zip([a] + cuts, cuts + [b]):
            gaps.append((s, e, regions.get(s, (f"D_{s + adj(s):04X}", None))[0]))

    cursor = base
    for pc in sorted(code):
        if pc < cursor:
            # Цель потока попала внутрь уже выведенной инструкции. Так бывает
            # честно (прыжок в середину опкода как приём), но байты канона
            # задаёт первый разбор — второй молча пропускаем, иначе round-trip
            # разъедется.
            overlaps.append(pc)
            continue
        if pc > cursor:
            cut(cursor, pc)
        emitted.append(pc)
        cursor = pc + code[pc].length
    if cursor < end:
        cut(cursor, end)
    return emitted, gaps, overlaps


def seg_entries(key: str) -> list[int]:
    """Точки входа сегмента: штатные + tools/entries.json (адреса канона)."""
    entries = list(SEGMENTS[key]["entries"])
    extra = ROOT / "tools/entries.json"
    if extra.is_file():
        cfg = json.loads(extra.read_text())
        entries += [int(x, 16) for x in cfg.get(key, [])]
    return entries


def analyze(key: str) -> dict:
    """Разбор сегмента + раскладка. Меток здесь ещё нет."""
    seg = SEGMENTS[key]
    mem, base, end = load_mem(seg)
    entries = seg_entries(key)
    code = disasm_reachable(mem, entries, base, end, NO_FOLLOW.get(key, set()))
    regions = {a: (adj_name(v[0], a), v[1])
               for a, v in DATA_REGIONS.get(key, {}).items()
               if base <= a < end}
    emitted, gaps, overlaps = layout(code, base, end, regions)
    return dict(key=key, seg=seg, mem=mem, base=base, end=end, code=code,
                entries=entries, regions=regions, emitted=emitted, gaps=gaps,
                overlaps=overlaps, labels={})


def base_labels(A: dict) -> dict[int, str]:
    """Метки на целях потока, на entry и на процедурах ABI."""
    base, end, code = A["base"], A["end"], A["code"]
    labels: dict[int, str] = {}
    if A["seg"]["entries"]:
        labels[A["seg"]["entries"][0]] = A["seg"]["entry_name"]
    for a, name in ABI.items():
        if base <= a < end:
            labels[a] = adj_name(name, a)
    for pc, ins in code.items():
        for t in ins.targets:
            if base <= t < end and t in code:
                labels.setdefault(t, lbl(t))
    return labels


def pointer_addrs(key: str) -> dict[int, int]:
    """{адрес слова-указателя: адрес таблицы} из POINTER_TABLES."""
    out: dict[int, int] = {}
    for a, (n, stride, offs, _why) in POINTER_TABLES.get(key, {}).items():
        for i in range(n):
            for o in offs:
                out[a + i * stride + o] = a
    return out


def operand_refs(A: dict):
    """Операнды, которые имеет смысл символизировать: [(pc, значение)].

    Стухшие исключены: метка увезла бы их вместе со всеми при смене org, а
    они и так указывают не туда. Они печатаются числом и помечаются.
    В режиме FIX они, наоборот, включены — по СВОЕМУ настоящему адресу.
    """
    key = A["key"]
    out = []
    for pc, ins in A["code"].items():
        if ins.operand is None or ins.opkind not in ("abs16", "imm16"):
            continue
        v = ins.operand
        if FIX and stale_fix(key, pc) is not None:
            v = stale_fix(key, pc)
        elif stale_at(key, pc):
            continue
        if ins.opkind == "imm16" and not (IMM_LO <= v < IMM_HI) \
                and v not in PAGE1 and v not in LOWMEM:
            continue
        out.append((pc, v))
    return out


def build_space(As: dict, keys) -> tuple[dict[int, int], dict[int, str]]:
    """Адресное пространство: (покрытие, имена).

    Покрытие — {адрес: адрес начала блока}, где блок это либо инструкция,
    либо кусок данных. По нему адрес внутрь блока печатается как
    `ИМЯ+смещение`, а не голым числом.
    """
    cover: dict[int, int] = {}
    names: dict[int, str] = {}
    for key in keys:
        A = As[key]
        for pc in A["emitted"]:
            for k in range(A["code"][pc].length):
                cover[pc + k] = pc
        for s, e, n in A["gaps"]:
            names[s] = n
            for k in range(s, e):
                cover[k] = s
    return cover, names


# ГРАНИЧНЫЕ УКАЗАТЕЛИ: адрес численно лежит в одном куске, а по смыслу
# принадлежит соседнему. Классика — «база таблицы минус один», когда обход
# начинается с прибавления. Символизатор по числу привяжет такой адрес к
# ЧУЖОЙ области, и при переезде, где соседние куски едут с разными
# поправками, указатель уедет не туда.
#
# Найдено на Векторе: `res:D26C ld hl,0x8546` — это ROOM_MAPS-1 (обход списка
# объектов комнаты сначала делает `add hl,bc`). 0x8546 — последний байт
# головы стадии 2, голова едет на -0x8000, карты комнат на +0x400. Указатель
# уезжал в 0x0446, обход шёл по дырке выравнивания и дальше по КОДУ игры
# (номер образа 0xCD — это прочитанный опкод call), комната не рисовалась,
# а спрайтовый блиттер крутился вхолостую. На MSX дефект невидим: там обе
# раскладки читают одни и те же байты. Ловится tools/trap_stale_v06js.js.
#
# Ключ и значение — адреса КАНОНА: {указатель: начало области-владельца}.
BORDER_PTRS = {
    0x8546: 0x8547,   # ROOM_MAPS-1, res:D26C
}


def resolve(v: int, cover: dict, names: dict):
    """Символ для адреса v: (текст, имя-определение, адрес-определение).

    None — символа нет, печатать числом.
    """
    if v in SYSTEM:
        return SYSTEM[v], SYSTEM[v], v
    if v in names:
        return names[v], names[v], v
    if v in PAGE1:
        return PAGE1[v], PAGE1[v], v
    if v in LOWMEM:
        return LOWMEM[v], LOWMEM[v], v
    if v in BORDER_PTRS:
        owner = BORDER_PTRS[v]
        n = names.get(owner)
        if n is not None:
            return f"{n}-0x{owner - v:X}", n, owner
    b = cover.get(v)
    if b is None:
        return None
    n = names.get(b)
    if n is None:
        return None
    return f"{n}+0x{v - b:X}", n, b


def _wrap(text: str, width: int = 72) -> list[str]:
    """Описание области данных — в несколько строк комментария."""
    lines, cur = [], ""
    for w in text.split():
        if cur and len(cur) + 1 + len(w) > width:
            lines.append(cur)
            cur = w
        else:
            cur = f"{cur} {w}" if cur else w
    if cur:
        lines.append(cur)
    return lines


SYS_NAMES = set(SYSTEM.values())
P1_NAMES = set(PAGE1.values())
set_mode()   # значение по умолчанию для FIXED — теперь оба набора известны


def fixed_value(v: int, cover: dict, names: dict) -> int:
    """Значение, которое ассемблер положит в операнд для адреса `v`.

    `v` — адрес в координатах КАНОНА. Символы рантайма при переезде едут на
    ADJ, системные переменные MSX и адреса page 1 — нет (см. шапку). Если
    символа нет, число печатается как есть и никуда не едет.
    """
    r = resolve(v, cover, names)
    if r is None:
        return v
    if r[1] in FIXED:
        return v
    # Поправка берётся по адресу ОПРЕДЕЛЕНИЯ символа, а не по самому числу:
    # для обычного `ИМЯ+смещение` это одно и то же (область не пересекает
    # границу кусков — генератор за этим следит), а граничный указатель
    # (BORDER_PTRS) обязан ехать вместе с областью-владельцем.
    return v + adj(r[2])


def render(A: dict, cover: dict, names: dict, piece=None) -> str:
    """Текст .asm. piece=(lo, hi, org, имя) — печатать только этот кусок.

    Кусок задаётся адресами КАНОНА включительно; его границы обязаны
    совпадать с границами инструкций/областей данных (проверяется).
    """
    key, seg, mem = A["key"], A["seg"], A["mem"]
    base, end, code = A["base"], A["end"], A["code"]
    labels, regions = A["labels"], A["regions"]
    ptrs = pointer_addrs(key)
    if piece is None:
        p_lo, p_end, org = base, end, base + adj(base)
    else:
        p_lo, p_hi, org, _nm = piece
        p_end = p_hi + 1

    used: dict[str, int] = {}     # имя -> адрес, для equ в шапке
    defined: set[str] = set()     # имена, строка определения которых выведена
    body: list[str] = []
    # Учёт АБСОЛЮТНЫХ операндов: символизировано / не опознано / стухло.
    # Относительные (jr/djnz) считаются отдельно: при смене org они и так
    # не ломаются, метка им нужна только для читаемости.
    n_sym = n_plain = n_stale = n_rel = 0
    # В режиме FIX: сколько починенных адресов НЕ получили символа. Такой
    # адрес остаётся числом и при смене org не поедет — это дыра в переезде,
    # и молчать о ней нельзя.
    unresolved_fix: list[tuple[int, int]] = []

    def sym(v: int, rel: bool = False) -> str | None:
        nonlocal n_sym, n_plain, n_rel
        r = resolve(v, cover, names)
        if r is None:
            if not rel:
                n_plain += 1
            return None
        text, name, addr = r
        used[name] = addr
        if rel:
            n_rel += 1
        else:
            n_sym += 1
        return text

    def at(a: int) -> str:
        """Адрес для комментария — в координатах режима."""
        return f"{org + (a - p_lo):04X}"

    stale_ptr = STALE_PTR.get(key, {})

    def emit_db(start: int, stop: int):
        nonlocal n_stale
        j = start
        while j < stop:
            if j in ptrs and j + 1 < stop:
                v = mem[j] | (mem[j + 1] << 8)
                if j in stale_ptr and not FIX:
                    s, note = None, ("  ; СТУХШИЙ УКАЗАТЕЛЬ, должно быть "
                                     f"{stale_ptr[j]:04X}")
                    n_stale += 1
                    raw = v
                else:
                    if j in stale_ptr:
                        v = stale_ptr[j]   # в оригинале указатель уже верен
                    s, note = sym(v), ""
                    raw = fixed_value(v, cover, names)
                    if raw != v:
                        RELOCATED.append((j, 2, v, raw))
                    if s is None and FIX:
                        unresolved_fix.append((j, v))
                body.append(f"\tdw\t{s or f'0x{raw:04X}'}"
                            f"\t; {at(j)}  {raw & 0xFF:02X} {raw >> 8:02X}{note}")
                j += 2
                continue
            k = j + 1
            while k < stop and k - j < 16 and k not in ptrs:
                k += 1
            row = ",".join(f"0x{x:02X}" for x in mem[j:k])
            body.append(f"\tdb\t{row}\t; {at(j)}")
            j = k

    def emit_data(start: int, stop: int, name: str):
        body.append(f"{name}:\t\t\t; данные {at(start)}..{at(stop - 1)}"
                    f" ({stop - start} байт)")
        defined.add(name)
        why = regions.get(start, (None, None))[1]
        if why:
            for line in _wrap(why):
                body.append(f"; {line}")
        emit_db(start, stop)

    gaps = {s: (e, n) for s, e, n in A["gaps"]}
    bounds = set(A["emitted"]) | {s for s, _e, _n in A["gaps"]} | {end}
    bounds |= {e for _s, e, _n in A["gaps"]}
    if p_lo not in bounds or p_end not in bounds:
        raise SystemExit(f"кусок {org:04X}: граница {p_lo:04X}/{p_end:04X}"
                         " не совпадает с границей инструкции или области")
    cursor = p_lo
    for pc in A["emitted"]:
        if pc < p_lo or pc >= p_end:
            continue
        while cursor < pc:
            e, n = gaps[cursor]
            emit_data(cursor, e, n)
            cursor = e
        if pc in labels:
            body.append(f"{labels[pc]}:")
            defined.add(labels[pc])
        ins = code[pc]
        note = ""
        emit = None          # значение операнда после переезда, если менялось
        st = stale_at(key, pc)
        if st is not None:
            txt = ins.text(None)
            note = f"  ; {st[1]} {st[0]:04X}"
            n_stale += 1
        elif ins.opkind == "rel8" and ins.targets:
            txt = ins.text(sym(ins.targets[0], rel=True))
        elif ins.operand is not None and ins.opkind in ("abs16", "imm16"):
            v = ins.operand
            if FIX and stale_fix(key, pc) is not None:
                # В оригинальной раскладке в образе лежит ИСХОДНОЕ значение:
                # печатаем символ по настоящему адресу — ассемблер выдаст
                # ровно тот же байт, что и в каноне.
                v = stale_fix(key, pc)
                note = "  ; в каноне +0x100 этот операнд стухший"
            if ins.opkind == "imm16" and not (IMM_LO <= v < IMM_HI) \
                    and v not in PAGE1 and v not in LOWMEM:
                txt = ins.text(None)
            else:
                s = sym(v)
                txt = ins.text(s)
                emit = fixed_value(v, cover, names)
                if emit != v:
                    RELOCATED.append((pc, ins.length, v, emit))
                if s is None and FIX and stale_fix(key, pc) is not None:
                    unresolved_fix.append((pc, v))
        else:
            txt = ins.text(None)
        # Байты в комментарии — те, что соберутся ЗДЕСЬ. 16-битный операнд у
        # z80 всегда занимает два последних байта инструкции.
        if emit is None or emit == ins.operand:
            raw = " ".join(f"{mem[pc + k]:02X}" for k in range(ins.length))
        else:
            pre = [mem[pc + k] for k in range(ins.length - 2)]
            raw = " ".join(f"{x:02X}" for x in
                           pre + [emit & 0xFF, emit >> 8])
        body.append(f"\t{txt:<30s}; {at(pc)}  {raw}{note}")
        if ins.flow in ("jump", "ret", "halt"):
            body.append("")
        cursor = pc + ins.length
    while cursor < p_end:
        e, n = gaps[cursor]
        emit_data(cursor, e, n)
        cursor = e

    # --- шапка
    shift = seg["load"] - seg["orig"]
    n_code = sum(i.length for pc, i in code.items() if p_lo <= pc < p_end)
    n_all = n_sym + n_plain + n_stale
    base, end = p_lo, p_end
    if MAP is not None:
        head = [
            f"; Spirits (Topo Soft, 1987), MSX — {seg['entry_name']}"
            f" [РАСКЛАДКА ВЕКТОРА-06Ц, кусок {piece[3]}]",
            f"; Источник — {seg['payload']} в раскладке ОРИГИНАЛА"
            f" (канон сдвинут на +0x{shift:03X}).",
            f"; Оригинал {base - 0x100:04X}..{end - 1 - 0x100:04X}"
            f"  ->  Вектор {org:04X}..{org + (end - base) - 1:04X}"
            f" ({end - base} байт)",
            f"; Достижимый код {n_code} байт, остальное — db (графика/таблицы).",
            ";",
            f"; Абсолютных адресов {n_all}: символом {n_sym}, числом"
            f" {n_plain}. Относительных {n_rel}.",
            "; Раскладка и проверки — docs/v06-memory.md,"
            " tools/verify_v06.py.",
            "; Адреса в комментариях — уже ВЕКТОРНЫЕ; пояснения к областям"
            " данных",
            "; цитируют адреса канона +0x100 (это разбор, а не операнды).",
            ";",
            "; Сгенерировано tools/disasm_msx.py --v06 — правки вносить туда"
            " или в tools/entries.json.",
        ]
    elif FIX:
        what = ("ОРИГИНАЛЬНАЯ РАСКЛАДКА" if ADJ else
                "канон +0x100 с ПОЧИНЕННЫМИ адресами")
        head = [
            f"; Spirits (Topo Soft, 1987), MSX — {seg['entry_name']}"
            f" [{what}]",
            f"; Восстановлено из {seg['payload']} (канон сдвинут на +0x{shift:03X}),",
            "; проверки — tools/verify_orig.py.",
            f"; Диапазон {org:04X}..{org + (end - base) - 1:04X}"
            f" ({end - base} байт)"
            + (f", entry {seg['entries'][0] + ADJ:04X}" if seg["entries"] else ""),
            f"; Достижимый код {n_code} байт, остальное — db (графика/таблицы).",
            ";",
            f"; Абсолютных адресов {n_all}: символом {n_sym}, числом"
            f" {n_plain}. Относительных {n_rel}.",
            "; Стухших нет: в этой раскладке операнды канона, которые сдвиг"
            " пропустил,",
            "; и есть правильные — они выписаны символом по своему настоящему"
            " адресу.",
            "; Пояснения к областям данных цитируют адреса КАНОНА +0x100:"
            " это разбор,",
            "; а не операнды, и переписывать его автоматически нельзя.",
            "; Разбор — docs/msx-relocation.md, § 7.",
            ";",
            "; Сгенерировано tools/disasm_msx.py --"
            + ("orig" if ADJ else "reshift")
            + " — правки вносить туда или в tools/entries.json.",
        ]
    else:
        head = [
            f"; Spirits (Topo Soft, 1987), MSX — {seg['entry_name']}",
            f"; Дизасм {seg['payload']}, собирается байт-в-байт: tools/verify_disasm.py",
            f"; Диапазон {base:04X}..{end - 1:04X} ({end - base} байт)"
            + (f", entry {seg['entries'][0]:04X}" if seg["entries"] else ""),
            f"; Сдвиг +0x{shift:03X} относительно оригинала ({seg['orig']:04X}).",
            f"; Достижимый код {n_code} байт, остальное — db (графика/таблицы).",
            ";",
            "; Абсолютные адреса вынесены в метки, чтобы переезд на другую"
            " раскладку",
            "; делал ассемблер, а не пересчёт операндов скриптом.",
            f"; Абсолютных адресов {n_all}: метками {n_sym}, стухших"
            f" {n_stale} (помечены в строке —",
            f"; символизировать их нельзя), не опознано {n_plain}."
            f" Относительных переходов {n_rel}.",
            "; Разбор — docs/msx-relocation.md.",
            ";",
            "; Сгенерировано tools/disasm_msx.py — правки вносить туда"
            " или в tools/entries.json.",
        ]
    out = list(head)
    if A["overlaps"]:
        out.append("; Наложения (цель внутри предыдущей инструкции): "
                   + ", ".join(at(a) for a in A["overlaps"]))
    if unresolved_fix:
        out.append("; ВНИМАНИЕ, починенный адрес без символа: "
                   + ", ".join(f"{at(a)}->{v + adj(v):04X}"
                               for a, v in unresolved_fix))
    out.append("")
    ext = sorted(((a, n) for n, a in used.items() if n not in defined),
                 key=lambda x: x[0])
    if ext:
        out += [
            "; Символы вне этого образа: резидентный слой (он копируется в"
            " верхнюю RAM",
            "; из SPIRITS.1 — см. docs/msx-vdp-abi.md), копия в page 1, BIOS"
            " и цели,",
            "; попавшие внутрь чужой инструкции. equ байтов не порождает —"
            " канон не",
            "; трогается, а при смене org правится в одном месте.",
        ]
        # Системные переменные MSX и page 1 при переезде НЕ двигаются.
        out += [f"{n}:\tequ\t0x{a if n in FIXED else a + adj(a):04X}"
                for a, n in ext]
        out.append("")
    out += [f"\torg\t0x{org:04X}", ""]
    return "\n".join(out + body) + "\n"


def build_all() -> dict:
    """Разбор всех сегментов + единое адресное пространство рантайма."""
    As = {k: analyze(k) for k in SEGMENTS}
    for A in As.values():
        A["labels"] = base_labels(A)
    cover, names = build_space(As, RUNTIME_SEGS)
    # Метка на начале инструкции, куда смотрит операнд: без неё обращение к
    # процедуре печаталось бы числом, а самомодификация — числом в середину.
    owner = {pc: k for k in RUNTIME_SEGS for pc in As[k]["emitted"]}

    def want_label(v: int):
        b = cover.get(v)
        if b is not None and b in owner:
            As[owner[b]]["labels"].setdefault(b, lbl(b))

    for key in RUNTIME_SEGS:
        for _pc, v in operand_refs(As[key]):
            want_label(v)
        # Цели таблиц указателей в данных: без метки `dw` печаталось бы
        # числом и при смене org указало бы на старое место.
        mem = As[key]["mem"]
        for a, table in pointer_addrs(key).items():
            if a in STALE_PTR.get(key, {}):
                # В каноне такой указатель стухший: символизировать нельзя.
                # В режиме FIX он целится по настоящему адресу.
                if FIX:
                    want_label(STALE_PTR[key][a])
                continue
            want_label(mem[a] | (mem[a + 1] << 8))
    for key in RUNTIME_SEGS:
        names.update(As[key]["labels"])
    # Одно имя на два адреса ассемблер разрешает молча и не в ту сторону.
    # Проверка дешёвая, а ошибка дорогая — падаем сразу.
    seen: dict[str, int] = {}
    for a, n in (list(names.items()) + list(SYSTEM.items())
                 + list(PAGE1.items()) + list(LOWMEM.items())):
        if seen.setdefault(n, a) != a:
            raise SystemExit(f"имя {n} задано дважды: "
                             f"{seen[n]:04X} и {a:04X}")
    # Сегмент "1" живёт в своём адресном пространстве (образ на момент BLOAD).
    cov1, nm1 = build_space(As, ("1",))
    nm1.update(As["1"]["labels"])
    return dict(As=As, cover=cover, names=names, cover1=cov1, names1=nm1)


def run_seg(key: str, S: dict) -> tuple[int, int]:
    A = S["As"][key]
    if key == "1":
        text = render(A, S["cover1"], S["names1"])
    else:
        text = render(A, S["cover"], S["names"])
    out = out_path(A["seg"], "out")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text)
    n_code = sum(i.length for i in A["code"].values())
    total = A["end"] - A["base"]
    print(f"seg {key}: {out.relative_to(ROOT)}  код {n_code}/{total} байт "
          f"({100 * n_code / total:.1f}%), инструкций {len(A['code'])}, "
          f"entries {len(A['entries'])}")
    return n_code, total


# =====================================================================
# Раскладка Вектора-06Ц
# =====================================================================
#
# 64 КБ ОЗУ; верхние 32 КБ — четыре экранные плоскости по 8 КБ
# (0x8000 + p*0x2000). Схема цвета «Exolon» (docs/adapter-requirements.md,
# § 0a): ВИДИМЫ три верхние плоскости 0xA000..0xFFFF, невидима одна нижняя
# 0x8000..0x9FFF — палитра задана так, что pal[i] == pal[i & 7], то есть
# бит плоскости 0x8000 (вес 8) на цвет не влияет и там лежат данные игры.
#
# Блок чистых данных 14 146 б больше одной плоскости (8 192 б), поэтому он
# кладётся ХВОСТОМ в невидимую плоскость: 0x6847..0x9F88. Голова блока
# (0x6847..0x7FFF) лежит в обычной низкой RAM.
#
# ЦЕНА: прежняя раскладка (данные на 0x8847) запускалась на MSX без правок
# и ею проверялся сам переезд (tools/openmsx/run-both.sh). Теперь блок
# накрывает 0x8000..0x82F3 — буферы окна save-under РОДНОГО движка героя, —
# и на MSX эта раскладка неверна. На Векторе движок героя перехвачен и
# буферы мертвы (docs/render-paths.md, B.4/B.10), так что это потеря только
# инструмента сверки, а не рабочей раскладки.
#
# Куски вывода: (сегмент, канон lo, канон hi включительно, новый адрес,
# имя файла). Границы кусков обязаны совпадать с границами инструкций
# или областей данных — render() это проверяет.
# ВСЕ поправки кратны 0x100 — это условие, а не совпадение. В образе есть
# адреса, собранные из байтов: `ld h,0xF3 / ld l,a` (res:D0AD), `ld b,0xD5`
# (res:D2E7) и ещё три спорных (docs/msx-relocation.md, § 5.3). Ассемблер их
# не видит, править надо руками — и при кратной странице поправке правка
# каждого такого места это РОВНО ОДИН байт (0xF3 -> 0x3C), а при любой
# другой — переписывание пары команд. За это заплачено 438 байтами дырок
# между кусками.
V06_LAYOUT = [
    ("2",   0x83A0, 0x8546, 0x02A0, "spirits2_head"),
    ("2",   0x8547, 0xBC88, 0x6847, "spirits2_data"),
    ("2",   0xBC89, 0xD100, 0x0489, "spirits2_tail"),
    ("res", 0xD100, 0xE14A, 0x1900, "resident"),
    ("hi",  0xE14B, 0xFBC5, 0x294B, "himem"),
]

# Таблица дескрипторов звуковых эффектов. На MSX она живёт в копии
# SPIRITS.1 в page 1 (0x64AA..0x6521) и наверх не переносится — то есть
# ни в один рантайм-сегмент не входит. На Векторе page 1 нет, и таблицу
# надо положить явно: SPIRITS.1[0x104B..0x10C2], 120 байт.
# org обязан кончаться на 0xAA (поправка кратна 0x100) и лежать ВЫШЕ
# рабочей области игры — см. V06_WORK_END.
V06_SFX = dict(src=0x104B, length=0x78, org=0x4EAA, name="sfx")

# Прочие фиксированные адреса новой раскладки.
#
# СКОЛЬКО RAM ИГРА ЗАНИМАЕТ НА САМОМ ДЕЛЕ.  Размер блока в файле (F1A8..FAC5)
# обманывает: теневые таблицы спрайтов лежат ВЫШЕ конца образа —
# SAT по F77E..F7FD, образы по F800..FFFF, — и резидентный слой чистит их
# одним `ldir` (D70F: ld hl,F7FE / ld de,F7FF / ld bc,07FF / ld (hl),0),
# а запись образа (D874) уходит ещё дальше и заворачивается за FFFF в
# 0000..00FB, где на MSX стоит ROM BIOS и запись теряется.
# После поправки -0xB700 это 4100..48FF плюс страница «заворота» 4900..49FF.
# Значит НИЧЕГО постороннего между 39C6 и 49FF лежать не может.
# Первая раскладка этого не учла: там на 44AA стояла таблица звуковых
# эффектов (затиралась в ноль — звука не было вовсе), на 45F4 —
# LOW_TILE_SRC, а с 45FC начинался стек.  Замер ловушкой:
# tools/trap_stale_v06js.js.
V06_WORK_END = 0x49FF     # рабочая область игры кончается здесь, не на 43C5
V06_STACK_TOP = 0x6500    # ld sp; стек растёт вниз, до V06_STACK_BOT
V06_STACK_BOT = 0x6426    # нижняя граница стека (218 байт; ЭТАП E увёл стек
                          # из середины зоны адаптера экрана в хвост бывшего
                          # SPRSAV: слоты и копии образов умерли, а адаптеру
                          # понадобилась НЕПРЕРЫВНАЯ зона 5000..60E3.
                          # Замеренная глубина стека 40 байт, docs/v06-memory.md § 10)
# LOW_TILE_SRC (оригинал 0x81F4) — НЕ «8 байт узора», а БАЗА ТАБЛИЦЫ
# ОБРАЗОВ: res:DAEC кладёт её в операнд 2:CD36 (`ld hl,BASE`), а CE36
# считает адрес как BASE + (индекс-1)*8. Индексы логотипа «topo SOFT»
# (res:DB0E: 21 22 .. 30, 18) дают 0x82B4..0x837B — то есть читают ГОЛОВУ
# образа (82A0..8446), а вовсе не восемь байт под ним. Значит база обязана
# ехать вместе с головой, на -0x8000: 0x81F4 -> 0x01F4. Прежнее значение
# 0x45F4 разрывало эту связь, и логотип читался из области стека — его
# просто не было на экране (проверено монохромной сверкой с живым MSX).
# 0x01F4..0x01FB лежит в зарезервированном под стартовый код 003F..029F;
# сами эти 8 байт не читаются никогда (индекс 1 = первый образ = база+0,
# а в списках индекс 1 не встречается), на MSX там была неинициализированная
# RAM.
V06_LOW_TILE = 0x01F4
V06_ENTRY = 0x0489        # игровой цикл (оригинал BB89)

# Кусочная карта переезда. Задаётся в координатах ОРИГИНАЛА — так её можно
# читать: (lo, hi, новый адрес, page1). page1=True значит, что кусок живёт в
# копии SPIRITS.1 в page 1 и НЕ участвовал в сдвиге +0x100, то есть в каноне
# у него тот же адрес; всё остальное в каноне лежит на 0x100 выше.
V06_MAP_ORIG = [
    (0x82A0, 0x8446, 0x02A0, False),   # голова игры: стадия 2 + плеер эффектов
    (0x8447, 0xBB88, 0x6847, False),   # чистые данные -> низкая RAM + плоскость 8000
    (0xBB89, 0xFAC5, 0x0489, False),   # код игры + резидент + банк + раб. RAM
    (0x81F4, 0x81FB, V06_LOW_TILE, False),   # 8 байт узора из-под образа
    (0x64AA, 0x6521, V06_SFX["org"], True),  # дескрипторы эффектов из page 1
]

# Она же в координатах КАНОНА: (lo, hi, поправка). Разбор идёт в каноне.
V06_MAP = [(lo + (0 if p1 else 0x100), hi + (0 if p1 else 0x100),
            new - lo - (0 if p1 else 0x100))
           for lo, hi, new, p1 in V06_MAP_ORIG]

# Условие кратности странице — не пожелание, а то, на чём держится § 5.3.
for _lo, _hi, _new, _p1 in V06_MAP_ORIG:
    if (_new - _lo) & 0xFF:
        raise SystemExit(f"V06_MAP_ORIG: поправка для {_lo:04X} не кратна"
                         f" 0x100 ({_new - _lo:+05X})")

# Что НЕ переезжает. Все эти адреса встречаются только в мёртвой на
# Векторе голове стадии 2 (0x82A0..0x82EA оригинала): вызовы BIOS, хук
# H.KEYI, регистр слотов и адреса копии в page 1. Проверено сплошным
# поиском по disasm/msx/orig/*.asm — других обращений нет.
V06_FIXED = {"BIOS_ENASLT", "BIOS_CHGCLR", "PORT_PSLOT", "RG1SAV",
             "BDRCLR", "H_KEYI", "SSLOT_REG",
             "P1_RESIDENT", "P1_STACK_TOP", "P1_HIMEM"}


def v06_addr(a: int) -> int:
    """Адрес ОРИГИНАЛА → адрес Вектора (None, если адрес не переезжает)."""
    for lo, hi, new, _p1 in V06_MAP_ORIG:
        if lo <= a <= hi:
            return new + (a - lo)
    return None


# Режимы: имя → параметры set_mode().
MODES = {
    "canon": dict(adj=0, fix=False, tag=""),
    "orig": dict(adj=-0x100, fix=True, tag="orig"),
    "reshift": dict(adj=0, fix=True, tag="reshift"),
    "v06": dict(adj=0, fix=True, tag="v06", map=V06_MAP, fixed=V06_FIXED),
}


def v06_out(name: str, what: str) -> Path:
    d = "disasm/msx/v06" if what == "out" else "build/v06"
    ext = "asm" if what == "out" else "bin"
    return ROOT / d / f"{name}.{ext}"


def run_v06(S: dict):
    """Вывод кусков раскладки Вектора + таблицы эффектов."""
    total = 0
    for key, lo, hi, org, name in V06_LAYOUT:
        if org != lo + adj(lo) or org + (hi - lo) != hi + adj(hi):
            raise SystemExit(f"кусок {name}: org {org:04X} не согласован"
                             f" с V06_MAP ({lo + adj(lo):04X})")
        A = S["As"][key]
        text = render(A, S["cover"], S["names"], piece=(lo, hi, org, name))
        out = v06_out(name, "out")
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text)
        n = hi - lo + 1
        total += n
        print(f"  {out.relative_to(ROOT)}: оригинал "
              f"{lo - 0x100:04X}..{hi - 0x100:04X} -> Вектор "
              f"{org:04X}..{org + n - 1:04X} ({n} байт)")
    # Таблица эффектов: сырые байты из SPIRITS.1, кода там нет.
    src = (ROOT / SEGMENTS["1"]["payload"]).read_bytes()
    off, ln, org = V06_SFX["src"], V06_SFX["length"], V06_SFX["org"]
    rows = [
        "; Spirits (Topo Soft, 1987), MSX — таблица дескрипторов звуковых"
        " эффектов",
        "; [РАСКЛАДКА ВЕКТОРА-06Ц, кусок sfx]",
        f"; SPIRITS.1[0x{off:04X}..0x{off + ln - 1:04X}], {ln} байт:"
        " 8 записей по 15 байт.",
        "; На MSX лежит в копии page 1 по 64AA..6521 и наверх не"
        " переносится; на",
        "; Векторе page 1 нет, поэтому кладётся явно. Живых записей 6:"
        " 64AA, 64B9,",
        "; 64C8, 64D7, 64E6, 64F5 — резидентный слой адресует их"
        " как P1_SFX_*.",
        ";",
        "; Сгенерировано tools/disasm_msx.py --v06.",
        "",
        f"\torg\t0x{org:04X}",
        "",
    ]
    for j in range(0, ln, 16):
        chunk = src[off + j:off + min(j + 16, ln)]
        rows.append("\tdb\t" + ",".join(f"0x{x:02X}" for x in chunk)
                    + f"\t; {org + j:04X}")
    out = v06_out(V06_SFX["name"], "out")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(rows) + "\n")
    total += ln
    print(f"  {out.relative_to(ROOT)}: page 1 64AA..6521 -> Вектор "
          f"{org:04X}..{org + ln - 1:04X} ({ln} байт)")
    print(f"  всего {total} байт (оригинал занимал столько же)")


def generate(mode: str, segs=None):
    """Сгенерировать дизасм в одном режиме. Возвращает S от build_all()."""
    set_mode(**MODES[mode])
    RELOCATED.clear()
    S = build_all()
    if mode == "v06":
        run_v06(S)
    else:
        for key in segs or sorted(SEGMENTS):
            run_seg(key, S)
    set_mode()
    return S


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seg", choices=sorted(SEGMENTS), action="append")
    ap.add_argument("--orig", action="store_true",
                    help="оригинальная раскладка → disasm/msx/orig/")
    ap.add_argument("--reshift", action="store_true",
                    help="оригинал, собранный обратно на +0x100"
                         " → disasm/msx/reshift/ (обратная проверка)")
    ap.add_argument("--v06", action="store_true",
                    help="раскладка Вектора-06Ц → disasm/msx/v06/")
    args = ap.parse_args()
    modes = [m for m, on in (("orig", args.orig), ("reshift", args.reshift),
                             ("v06", args.v06)) if on] or ["canon"]
    for m in modes:
        generate(m, args.seg)


if __name__ == "__main__":
    main()
