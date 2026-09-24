#!/usr/bin/env python3
"""Заставка: картинка CPC 256x256 -> три ВИДИМЫЕ плоскости Вектора + палитра.

  python3 tools/mk_title.py                     → build/title/{title-planes.bin,
                                                   title-pal.inc, preview.png}
  python3 tools/mk_title.py --dither            → то же, с рассеиванием ошибки
  python3 tools/mk_title.py --preview-only      → только preview.png и цифры

ПОЧЕМУ ВОСЕМЬ ЦВЕТОВ, А НЕ ШЕСТНАДЦАТЬ.  У Вектора четыре плоскости, но одна
(8000..9FFF) отдана ХВОСТУ БЛОКА ДАННЫХ игры (docs/v06-memory.md § 2), и
палитра построена так, что pal[i] == pal[i & 7] — плоскость 8 невидима.
Освободить её на время заставки значило бы где-то сохранить 8073 байта
8000..9F88.  ЗАМЕР: ZX0 сжимает этот хвост до 7120 б (88.2 %), deflate -9 —
до 6049 б (74.9 %); свободной памяти на время заставки 2405 б (6100..67FF
1792 б + 5D1B..5F7F 613 б).  Не влезает втрое, поэтому 8 цветов.

РАСКЛАДКА ПЛОСКОСТЕЙ (docs/v06-memory.md, tools/shot_v06js.js:240):
  адрес = плоскость + (x >> 3) * 256 + (255 - y),  бит = 0x80 >> (x & 7)
  код цвета пикселя = бит(A000)*4 + бит(C000)*2 + бит(E000)*1
Файл title-planes.bin — 24576 б, ровно A000..FFFF подряд.

БАЙТ ПАЛИТРЫ ВЕКТОРА — BBGGGRRR (tools/mk_room_pal.py:85): два бита синего,
три зелёного, три красного; 0x00 чёрный, 0xFF белый.

КВАНТОВАНИЕ.  Картинка — плоская пиксельная графика CPC (14 цветов, ни одного
градиента), поэтому по умолчанию РАССЕИВАНИЯ ОШИБКИ НЕТ: оно бы превратило
заливки в шум.  Выбор восьми цветов — не «первые восемь по гистограмме», а
k-медоиды по всем 14 исходным цветам с весом по числу пикселей: полный
перебор сочетаний (чёрный обязателен) плюс уточнение каждого представителя
по всем 256 цветам Вектора.  Метрика — «redmean», привычное приближение
зрительного расстояния.

ЗАПРЕТ «ПРОВАЛИТЬСЯ В ЧЁРНЫЙ» (--allow-black снимает).  Взвешенная ошибка по
ПИКСЕЛЯМ не видит, что предмет ИСЧЕЗ: тёмно-синий (0,0,85), 550 пикселей —
это летучая мышь над деревом, и свободный выбор палитры сводит её в чёрный,
то есть в фон.  Ошибка при этом наименьшая (1237 против 1430), а мыши на
картинке нет вовсе.  Поэтому перебор идёт с условием: НИ ОДИН исходный цвет,
кроме самого чёрного, не должен оказаться ближе всего к чёрному.  Цена —
восьмой слот уходит с яркой зелени (0,255,0) на синий (0,0,85): куст справа
становится тёмно-зелёным, зато мышь видна.
"""
from __future__ import annotations

import argparse
import itertools
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "ref/title/cpc-title-256.png"
OUT = ROOT / "build/title"
PLANES = (0xA0, 0xC0, 0xE0)     # веса 4, 2, 1


def v06_byte(rgb) -> int:
    """RGB -> байт палитры Вектора BBGGGRRR (та же формула, что mk_room_pal)."""
    r, g, b = rgb
    return ((b >> 6) << 6) | ((g >> 5) << 3) | (r >> 5)


def v06_rgb(v: int):
    """Байт палитры -> RGB, как его показывает экран (уровни 0..7 и 0..3)."""
    return (round((v & 7) * 255 / 7),
            round(((v >> 3) & 7) * 255 / 7),
            round(((v >> 6) & 3) * 255 / 3))


def dist(a, b) -> float:
    """«redmean» — дешёвое приближение зрительного расстояния."""
    rm = (a[0] + b[0]) / 2
    dr, dg, db = a[0] - b[0], a[1] - b[1], a[2] - b[2]
    return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db


def choose_palette(hist, allow_black: bool):
    """8 байт палитры Вектора: k-медоиды по исходным цветам, чёрный обязателен."""
    cols = [c for c, _ in hist]
    wts = [n for _, n in hist]
    cand = sorted({v06_byte(c) for c in cols} | {0x00})

    def cost(pal):
        rgbs = [v06_rgb(p) for p in pal]
        return sum(w * min(dist(c, r) for r in rgbs) for c, w in zip(cols, wts))

    def sinks(pal):
        """Сколько исходных цветов (кроме чёрного) провалилось в чёрный."""
        rgbs = [v06_rgb(p) for p in pal]
        n = 0
        for c in cols:
            if c == (0, 0, 0):
                continue
            if pal[min(range(len(pal)), key=lambda i: dist(c, rgbs[i]))] == 0x00:
                n += 1
        return n

    def rank(pal):
        return (0 if allow_black else sinks(pal), cost(pal))

    rest = [p for p in cand if p != 0x00]
    if len(rest) <= 16:                       # полный перебор: C(13,7) = 1716
        best = min((sorted((0x00,) + combo) for combo in
                    itertools.combinations(rest, min(7, len(rest)))), key=rank)
    else:                                     # запас на другую картинку
        best = [0x00]
        while len(best) < 8:
            best = sorted(best + [min((p for p in cand if p not in best),
                                      key=lambda p: rank(best + [p]))])
    pal = list(best) + [0x00] * (8 - len(best))
    # уточнение: представитель каждого скопления — лучший из ВСЕХ 256 цветов
    for _ in range(8):
        groups = {i: [] for i in range(8)}
        rgbs = [v06_rgb(p) for p in pal]
        for c, w in zip(cols, wts):
            groups[min(range(8), key=lambda i: dist(c, rgbs[i]))].append((c, w))
        new = list(pal)
        for i, grp in groups.items():
            if not grp or pal[i] == 0x00:
                continue
            new[i] = min(range(256),
                         key=lambda v: sum(w * dist(c, v06_rgb(v)) for c, w in grp))
        if new == pal or rank(new) > rank(pal):   # уточнение не имеет права
            break                                 # уронить цвет в чёрный
        pal = new
    # чёрный — код 0: экран после SCR_CLS нулевой, кайма тоже 0
    pal.remove(0x00)
    return [0x00] + sorted(pal, key=lambda v: sum(v06_rgb(v)))


def quantize(im, pal, dither: bool):
    """-> список кодов 0..7 по пикселям (слева направо, сверху вниз)."""
    w, h = im.size
    rgbs = [v06_rgb(p) for p in pal]
    px = list(im.getdata())
    if not dither:
        cache = {}
        out = []
        for c in px:
            k = cache.get(c)
            if k is None:
                k = cache[c] = min(range(8), key=lambda i: dist(c, rgbs[i]))
            out.append(k)
        return out
    buf = [[float(v) for v in c] for c in px]
    out = [0] * (w * h)
    for y in range(h):
        for x in range(w):
            i = y * w + x
            cur = tuple(max(0.0, min(255.0, v)) for v in buf[i])
            k = min(range(8), key=lambda j: dist(cur, rgbs[j]))
            out[i] = k
            err = [cur[c] - rgbs[k][c] for c in range(3)]
            for dx, dy, f in ((1, 0, 7 / 16), (-1, 1, 3 / 16),
                              (0, 1, 5 / 16), (1, 1, 1 / 16)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and ny < h:
                    for c in range(3):
                        buf[ny * w + nx][c] += err[c] * f
    return out


def to_planes(codes, w, h) -> bytes:
    """Коды -> 24576 б, три плоскости подряд (A000, C000, E000)."""
    mem = bytearray(3 * 8192)
    for y in range(h):
        lo = 255 - y
        row = y * w
        for x in range(w):
            k = codes[row + x]
            if not k:
                continue
            off = (x >> 3) * 256 + lo
            bit = 0x80 >> (x & 7)
            for p, weight in enumerate((4, 2, 1)):
                if k & weight:
                    mem[p * 8192 + off] |= bit
    return bytes(mem)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dither", action="store_true",
                    help="рассеивание ошибки (по умолчанию нет: графика плоская)")
    ap.add_argument("--preview-only", action="store_true")
    ap.add_argument("--allow-black", action="store_true",
                    help="снять запрет «провалиться в чёрный» (см. шапку)")
    a = ap.parse_args()

    im = Image.open(SRC).convert("RGB")
    w, h = im.size
    assert (w, h) == (256, 256), f"нужна картинка 256x256, а не {w}x{h}"
    hist = Counter(im.getdata()).most_common()
    pal = choose_palette(hist, a.allow_black)
    codes = quantize(im, pal, a.dither)

    OUT.mkdir(parents=True, exist_ok=True)
    rgbs = [v06_rgb(p) for p in pal]
    prev = Image.new("RGB", (w, h))
    prev.putdata([rgbs[k] for k in codes])
    prev.save(OUT / "preview.png")

    tot = w * h
    used = Counter(codes)
    print(f"исходник {SRC.name}: {len(hist)} цветов, {tot} пикселей")
    print("палитра заставки (код: байт Вектора, RGB, доля пикселей):")
    for i, p in enumerate(pal):
        print("  %d: %02X  %3d %3d %3d  %6.2f%%"
              % (i, p, *rgbs[i], 100 * used.get(i, 0) / tot))
    err = sum(n * min(dist(c, r) for r in rgbs) for c, n in hist)
    moved = sum(n for c, n in hist if v06_byte(c) not in pal)
    print("пикселей, попавших не в свой цвет: %d (%.2f %%);"
          " средняя ошибка %.1f" % (moved, 100 * moved / tot, err / tot))
    print(f"предпросмотр {OUT / 'preview.png'}"
          f"{' (с рассеиванием)' if a.dither else ' (без рассеивания)'}")
    if a.preview_only:
        return 0

    planes = to_planes(codes, w, h)
    (OUT / "title-planes.bin").write_bytes(planes)
    inc = ["; СГЕНЕРИРОВАНО tools/mk_title.py — правки вносить ТУДА.",
           "; Палитра заставки: 8 цветов, записи 8..15 — зеркало"
           " (невидима плоскость 8000).",
           "TITLE_PAL:"]
    inc.append("\t\tdb\t" + ",".join("0x%02X" % p for p in pal))
    (OUT / "title-pal.inc").write_text("\n".join(inc) + "\n")
    nz = sum(1 for b in planes if b)
    print(f"{OUT / 'title-planes.bin'}  {len(planes)} б "
          f"(A000..FFFF, ненулевых {nz})")
    print(f"{OUT / 'title-pal.inc'}  палитра 8 байт")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
