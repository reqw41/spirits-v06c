#!/usr/bin/env python3
"""СТРАНИЦА СПРАВКИ: текст из docs/help-page-ru.md -> поток для title.asm.

    python3 tools/mk_help.py            # отчёт цифрами
    python3 tools/mk_help.py --json     # + build/help/help-expect.json
    (как стадия сборки — вызывается из tools/build_port_rom.py)

ЧТО ЭТО.  После заставки (картинка + мелодия) по нажатию показывается ОДИН
экран справки по-русски, и только потом идут титры и игра
(docs/adapter-requirements.md § 0b).  Рисует страницу код заставки
(src/v06/title.asm) — своим циклом, ДО того как проснётся адаптер экрана.

ТЕКСТ — ДАННЫЕ, И ТОЛЬКО ДАННЫЕ.  Источник — фрагмент в тройных кавычках
из docs/help-page-ru.md; поменять текст = поменять тот фрагмент и пересобрать
порт.  Ни одного знака здесь не зашито.

ЧЕМ РИСУЕТСЯ ЗНАК.  Кодировка — ШРИФТ САМОЙ ИГРЫ (tools/i18n_ru.py,
CHAR_CODE): те же коды, что печатает 2:CE36, и тот же адрес базы (операнд
1737).  В шрифте игры НЕТ строчных букв и НЕТ знаков препинания, кроме
двоеточия, пробела и процента, поэтому:

  * текст поднимается в ВЕРХНИЙ регистр (отчёт печатает, сколько знаков
    подняли) — иного начертания в шрифте не существует;
  * девять недостающих знаков `. , - * = / ! ( )` дорисованы ЗДЕСЬ,
    в стиле шрифта игры, и лежат ОТДЕЛЬНОЙ таблицей рядом с текстом:
    коды 0xF0.. — они не входят в шрифт игры и печатнику игры не видны.
    Так страница не трогает ни таблицу глифов, ни два операнда базы
    (1737/23FE), то есть образ адаптера остаётся ровно тем, что проверен
    гейтами перевода.

РАМКА.  По периметру экрана — ТОТ ЖЕ орнамент, что у панели HUD: коды
0x70/0x71 вперемежку (docs/i18n-inventory.md § 1.3; в потоке панели 9B56 они
и образуют рамку), пером панели — код цвета 2.  Рамку рисует title.asm
циклом, а здесь она пересчитывается независимо для ожидаемой картинки гейта.
Фигурки 0x57..0x66 — это ЖИЗНИ, не рамка, и здесь не используются.

ФОРМАТ ПОТОКА (его читает T_HELP в src/v06/title.asm):

    [флаги][колонка][длина][коды...]  ... [0xFF]
    флаги: биты 0..4 — ряд 0..23;  бит 7 = 1 — плоскость C000 (цвет 2),
                                   бит 7 = 0 — плоскость E000 (белый)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import i18n_ru  # noqa: E402

OUT = ROOT / "build" / "help"
SRC = ROOT / "docs" / "help-page-ru.md"

# --- ГЕОМЕТРИЯ СТРАНИЦЫ
COLS, ROWS = 32, 24
FRAME_ROWS = (0, ROWS - 1)          # рамка сверху и снизу
FRAME_COLS = (0, COLS - 1)          # рамка слева и справа
INNER_ROW0, INNER_ROW1 = 1, ROWS - 2    # 1..22 — 22 ряда под текст
INNER_COL0, INNER_COL1 = 1, COLS - 2    # 1..30 — 30 знакомест
HEAD_ROW = 0                        # заголовок — В ВЕРХНЕЙ СТРОКЕ РАМКИ
HEAD_PAD = " "                      # пробел по бокам: « SPIRITS »
BODY_ROW = 2                        # с этого ряда идёт остальной текст
PLANE_TEXT = 0x00                   # флаг плоскости: E000, белый
PLANE_ORN = 0x80                    # C000, перо панели
FRAME_CODES = (0x71, 0x70)          # чётная сумма (ряд+кол) -> 71, нечётная -> 70
PUNCT_FIRST = 0xF0                  # коды дорисованных знаков (вне шрифта игры)

# --- ДЕВЯТЬ ЗНАКОВ В СТИЛЕ ШРИФТА ИГРЫ.
# Стиль тот же, что у кириллицы (tools/i18n_ru.py § 1): поле 7 колонок
# (биты 6..0, бит 7 пуст), верхняя строка байта пустая, штрих 2 пикселя.
PUNCT: dict[str, list[str]] = {
    ".": ["........", "........", "........", "........",
          "........", "........", "..##....", "..##...."],
    ",": ["........", "........", "........", "........",
          "........", "..##....", "..##....", ".##....."],
    "-": ["........", "........", "........", "........",
          ".######.", ".######.", "........", "........"],
    # «*» СНЯТА 2026-09-23, чтобы таблица осталась в 72 байта: место под неё
    # кончилось (3C01 и дальше — ЖИВАЯ память игры, замер zonewatch: чтений
    # 24, записей 9 за полный проход), а сама она в тексте не встречалась ни
    # разу. Понадобится — вернуть сюда и искать таблице новое место целиком.
    #   "*": ["........", "........", ".##..##.", "..####..",
    #         ".######.", "..####..", ".##..##.", "........"],
    "=": ["........", "........", ".######.", ".######.",
          "........", ".######.", ".######.", "........"],
    "/": ["........", ".....##.", ".....##.", "....##..",
          "...##...", "..##....", ".##.....", ".##....."],
    "!": ["........", "..##....", "..##....", "..##....",
          "..##....", "..##....", "........", "..##...."],
    "(": ["........", "...##...", "..##....", "..##....",
          "..##....", "..##....", "..##....", "...##..."],
    ")": ["........", "...##...", "....##..", "....##..",
          "....##..", "....##..", "....##..", "...##..."],
    # ЛАТИНСКАЯ Q — СВОЯ, А НЕ ИЗ ШРИФТА ИГРЫ.  В шрифте картриджа она
    # нарисована кольцом без нижней дуги с диагональю внутри и читается
    # как «N» с шапкой (байты 1C 63 73 7B 6F 67 63 63; те же и в испанском
    # образе, то есть это не наша порча).  В справке Q — клавиша «налево»,
    # её обязано быть видно.  Наша сделана из «O» того же шрифта
    # (00 1C 36 63 63 63 36 1C) плюс хвост в стиле «S».
    "Q": ["........", "...###..", "..##.##.", ".##...##",
          ".##...##", ".##.####", "..#####.", "......##"],
}
PUNCT_ORDER = list(PUNCT)
# Знаки, которые берём ИЗ СВОЕЙ таблицы, даже если они есть в шрифте игры.
PUNCT_OVERRIDE = frozenset("Q")


def rows_to_bytes(rows: list[str]) -> bytes:
    if len(rows) != 8 or any(len(r) != 8 for r in rows):
        sys.exit("mk_help: глиф не 8x8")
    out = bytearray()
    for r in rows:
        b = 0
        for k, c in enumerate(r):
            if c == "#":
                b |= 0x80 >> k
        out.append(b)
    return bytes(out)


def punct_table() -> bytes:
    return b"".join(rows_to_bytes(PUNCT[ch]) for ch in PUNCT_ORDER)


def char_code(ch: str) -> int:
    """Код знака: сперва шрифт игры, потом дорисованные.

    Исключение — PUNCT_OVERRIDE: там наш глиф лучше глифа картриджа.
    """
    if ch in PUNCT and ch in PUNCT_OVERRIDE:
        return PUNCT_FIRST + PUNCT_ORDER.index(ch)
    if ch in i18n_ru.CHAR_CODE:
        return i18n_ru.CHAR_CODE[ch]
    if ch in PUNCT:
        return PUNCT_FIRST + PUNCT_ORDER.index(ch)
    sys.exit(f"mk_help: нет глифа для {ch!r} — дорисуйте его в PUNCT")


def read_text() -> list[str]:
    """Строки справки из docs/help-page-ru.md (первый блок в ```).

    ПУСТЫЕ СТРОКИ СОХРАНЯЮТСЯ: в новом тексте (решение владельца 2026-09-22)
    они — разделители разделов, и на странице им отвечают ПУСТЫЕ РЯДЫ.
    Срезаются только пустые строки по краям блока.
    """
    m = re.search(r"```\n(.*?)```", SRC.read_text(), re.S)
    if not m:
        sys.exit(f"mk_help: в {SRC} нет блока текста в тройных кавычках")
    lines = [l.rstrip() for l in m.group(1).split("\n")]
    while lines and lines[0] == "":
        lines.pop(0)
    while lines and lines[-1] == "":
        lines.pop()
    return lines


def layout(lines: list[str]) -> tuple[list[tuple[int, int, str, int]], dict]:
    """Строки -> знакоместа.  Возвращает (текст, рамка, отчёт).

    cells — список (ряд, колонка, СИМВОЛ, флаг плоскости): из него и поток, и
    ожидаемая картинка гейта.  Разделители из дефисов выбрасываются: их место
    занимает рамка (решение владельца 2026-09-22).

    ЗАГОЛОВОК — В ВЕРХНЕЙ СТРОКЕ РАМКИ (ряд 0, решение владельца 2026-09-22):
    орнамент там ПРЕРЫВАЕТСЯ, и по центру стоит « SPIRITS » с пробелом по
    бокам.  Кода это не стоит: T_FRAME по-прежнему кроет ряд 0 целиком, а
    поток поверх кладёт в плоскость C000 девять ПРОБЕЛОВ (глиф 0x73 — восемь
    нулей, он и стирает орнамент), и уже поверх — сам заголовок БЕЛЫМ, в
    плоскость E000.  Цена белизны — одна лишняя запись потока (10 байт).
    """
    rep = {"строк в файле": len(lines)}
    body = [l for l in lines if set(l.strip()) != {"-"}]
    rep["выброшено разделителей ----"] = len(lines) - len(body)
    up = [l.upper() for l in body]
    rep["знаков поднято в верхний регистр"] = sum(
        1 for a, b in zip("".join(body), "".join(up)) if a != b)
    width = INNER_COL1 - INNER_COL0 + 1
    wide = [(i, l) for i, l in enumerate(up) if len(l.strip()) > width]
    if wide:
        sys.exit(f"mk_help: строка {wide[0][0]} шире {width} знакомест: {wide[0][1]!r}")
    rows_have = INNER_ROW1 - BODY_ROW + 1
    if len(up) - 1 > rows_have:
        sys.exit(f"mk_help: строк текста {len(up) - 1} (без заголовка), а внутри"
                 f" рамки помещается {rows_have} (ряды {BODY_ROW}..{INNER_ROW1})")
    cells: list[tuple[int, int, str, int]] = []
    # заголовок: « SPIRITS » по центру ряда 0, поверх орнамента
    head = HEAD_PAD + up[0].strip() + HEAD_PAD
    hcol = (COLS - len(head)) // 2
    head_span = range(hcol, hcol + len(head))
    # рамка: тот же орнамент, что у панели HUD.  В ПОТОК ОНА НЕ ИДЁТ — её
    # рисует циклом сам title.asm (T_FRAME) по тому же правилу; так она стоит
    # 0 байт данных вместо 222.  Здесь она считается заново, независимо от
    # ассемблера, и попадает в ожидаемую картинку гейта.  Знакоместа под
    # заголовком в ряду 0 из ОЖИДАЕМОЙ картинки исключены: на экране их
    # стирает запись пробелов (см. ниже), и орнамента там нет.
    frame = []
    for col in range(COLS):
        for row in FRAME_ROWS:
            if row == HEAD_ROW and col in head_span:
                continue
            frame.append((row, col))
    for row in range(INNER_ROW0, INNER_ROW1 + 1):
        for col in FRAME_COLS:
            frame.append((row, col))
    frame_cells = [(row, col, FRAME_CODES[(row + col) & 1], PLANE_ORN)
                   for row, col in sorted(frame)]
    # 1) стереть орнамент под заголовком: пробелы в плоскость орнамента
    for k in range(len(head)):
        cells.append((HEAD_ROW, hcol + k, " ", PLANE_ORN))
    # 2) сам заголовок — БЕЛЫМ (плоскость текста), без крайних пробелов
    for k, ch in enumerate(head.strip()):
        cells.append((HEAD_ROW, hcol + len(HEAD_PAD) + k, ch, PLANE_TEXT))
    # остальные строки подряд, с BODY_ROW; левый отступ строки сохраняется,
    # ПУСТАЯ СТРОКА ОСТАВЛЯЕТ ПУСТОЙ РЯД
    row = BODY_ROW
    empty = 0
    for line in up[1:]:
        text = line.rstrip()
        if text == "":
            empty += 1
        lead = len(text) - len(text.lstrip())
        for k, ch in enumerate(text.strip()):
            cells.append((row, INNER_COL0 + lead + k, ch, PLANE_TEXT))
        row += 1
    if row - 1 > INNER_ROW1:
        sys.exit(f"mk_help: текст кончился на ряду {row - 1}, а рамка на {INNER_ROW1}")
    rep["заголовок"] = f"ряд {HEAD_ROW}, колонки {hcol}..{hcol + len(head) - 1}: {head!r}"
    rep["пустых рядов-разделителей"] = empty
    rep["рядов под текстом"] = f"{BODY_ROW}..{row - 1} из {INNER_ROW0}..{INNER_ROW1}"
    rep["знакомест текста"] = len(cells)
    rep["знакомест рамки"] = len(frame_cells)
    return cells, frame_cells, rep


def stream(cells) -> bytes:
    """Знакоместа -> поток записей [флаги][колонка][длина][коды...], 0xFF."""
    out = bytearray()
    runs: list[tuple[int, int, int, list[int]]] = []
    for row, col, ch, plane in cells:
        code = ch if isinstance(ch, int) else char_code(ch)
        if runs and runs[-1][0] == row and runs[-1][3] == plane \
                and runs[-1][1] + len(runs[-1][2]) == col:
            runs[-1][2].append(code)
        else:
            runs.append((row, col, [code], plane))
    for row, col, codes, plane in runs:
        while codes:
            take, codes = codes[:255], codes[255:]
            out += bytes([row | plane, col, len(take)]) + bytes(take)
    out.append(0xFF)
    return bytes(out)


def build() -> tuple[bytes, dict, dict]:
    """(блок для образа, ожидаемая картинка для гейта, отчёт цифрами).

    Блок = таблица дорисованных знаков, за ней поток.  Оба лежат рядом, одним
    куском, потому что и адрес таблицы, и адрес потока title.asm получает
    через equ — сдвинуть блок целиком можно одной строкой.
    """
    cells, frame_cells, rep = layout(read_text())
    punct = punct_table()
    body = stream(cells)
    blob = punct + body
    expect = {
        "punct_count": len(PUNCT_ORDER),
        "punct_first_code": PUNCT_FIRST,
        "punct_glyphs": [list(rows_to_bytes(PUNCT[ch])) for ch in PUNCT_ORDER],
        "stream_offset": len(punct),
        "frame_codes": list(FRAME_CODES),
        "cells": [[r, c, (ch if isinstance(ch, int) else char_code(ch)), pl]
                  for r, c, ch, pl in cells + frame_cells],
    }
    rep["таблица знаков"] = f"{len(punct)} б ({len(PUNCT_ORDER)} глифов)"
    rep["поток"] = f"{len(body)} б"
    rep["всего блок"] = f"{len(blob)} б"
    return blob, expect, rep


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    blob, expect, rep = build()
    for k, v in rep.items():
        print(f"  {k}: {v}")
    if a.json:
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / "help-expect.json").write_text(
            json.dumps(expect, ensure_ascii=False), encoding="utf-8")
        (OUT / "help.bin").write_bytes(blob)
        print(f"  записано: {OUT}/help.bin, help-expect.json")


if __name__ == "__main__":
    main()
