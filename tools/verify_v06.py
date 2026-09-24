#!/usr/bin/env python3
"""Сборка Spirits в раскладке Вектора-06Ц и доказательства её верности.

  python3 tools/verify_v06.py            # всё
  python3 tools/verify_v06.py --write    # плюс build/v06/*.bin для стенда

Исходная точка — ВОССТАНОВЛЕННЫЙ ОРИГИНАЛ (ref/msx/orig/, раскладка
9000/82A0), а не канон +0x100: в оригинале стухших адресов нет по
построению (docs/msx-relocation.md, § 7).

Раскладка Вектора — docs/v06-memory.md; таблицы — V06_LAYOUT / V06_MAP в
tools/disasm_msx.py.

ПЯТЬ ПРОВЕРОК:

  1. Геометрия. Куски не перекрываются (кроме одного байта D000, как в
     оригинале), покрывают весь образ целиком и ложатся ровно туда, куда
     обещает карта. Ничего не потеряно и не продублировано.

  2. Байт в байт против оригинала. Образ Вектора обязан быть образом
     оригинала, в котором изменились РОВНО переехавшие операнды и ничего
     кроме. Множество различающихся байтов сверяется поимённо со списком,
     который вёл генератор, и каждое отличие проверяется на равенство
     новому значению карты.

  3. Ни одного числа на старое место. Собранный образ Вектора
     дизассемблируется ЗАНОВО, от своих точек входа, и каждый адресный
     операнд сверяется с операндом оригинала: либо он переехал ровно на
     карту, либо остался числом — и тогда это число обязано не попадать
     внутрь бывшего образа. Исключения перечислены поимённо (мёртвая на
     Векторе голова стадии 2).

  4. Адреса, собранные из байтов. Их ассемблер не двигает (§ 5.3
     docs/msx-relocation.md). Раз все поправки карты кратны 0x100, нужная
     новая константа считается однозначно — она выписывается, чтобы её не
     забыли. Починка — работа следующего шага.

  5. Прежние проверки зелёные: round-trip канона и оригинала.

  6. Банки образов перепакованы ПО СТОЛБЦАМ (этап E) и тело адаптера
     влезло в свою зону обеими схемами.

  7. ПЕРЕВОД (--i18n).  Собираются ОБА образа, `--lang es` и `--lang ru`.
     Испанский обязан нести нетронутый образ игры (сверяется с vmem этой же
     сборки), русский — отличаться от испанского РОВНО в зонах, которые
     объявил tools/i18n_ru.py, и в каждой зоне обязан лежать ровно выход
     этой программы.  Ни одного «лишнего» изменённого байта.
"""
from __future__ import annotations

import os

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools/vendor"))
import disasm_msx as D  # noqa: E402
import repack_banks  # noqa: E402
from disasm_msx import (SEGMENTS, V06_LAYOUT, V06_SFX,  # noqa: E402
                        V06_MAP_ORIG, V06_ENTRY, V06_STACK_TOP,
                        V06_LOW_TILE, V06_STACK_BOT, V06_WORK_END,
                        IMM_LO, IMM_HI, PAGE1, LOWMEM,
                        disasm_reachable, v06_addr)
from z80dis import decode  # noqa: E402

ASM = Path(os.environ["ZASM"]) if "ZASM" in os.environ else (Path.home() / "projects/kvalley-v06c/tools/bin/sjasm")  # zasm 4.5.0

# Образ оригинала в 64K: что где лежит после загрузки.
ORIG_RUNTIME = (0x82A0, 0xFAC5)     # игра + резидент + банк + рабочая RAM
ORIG_SFX = (0x64AA, 0x6521)         # таблица эффектов в копии page 1
ORIG_ENTRY = 0xBB89                 # игровой цикл
ORIG_STACK_TOP = 0x61A8
# Точка синхронизации для сравнения двух прогонов — VDP_SET_WADDR, самая
# горячая резидентная процедура: она вызывается и в титрах, и в игре, то
# есть годится как «программные часы» на любой фазе. Оба прогона
# останавливаются на N-м её проходе, а НЕ «через N секунд»: по времени они
# расходятся на доли кадра, и дампы снимались бы в разных местах отрисовки.
ORIG_SYNC = 0xD306

# Адреса, которые НЕ переезжают, и почему это законно. Все они встречаются
# только в голове стадии 2 (82A0..82EA), которая на Векторе не исполняется:
# точка входа — игровой цикл, а не начало образа.
KNOWN_FIXED = {
    0x0024: "BIOS_ENASLT — вызов BIOS MSX, 82CF",
    0x0072: "BIOS_CHGCLR — вызов BIOS MSX, 82B8",
    0xF3E0: "RG1SAV — системная переменная MSX, 82AE",
    0xF3EB: "BDRCLR — системная переменная MSX, 82B3",
    0xFD9F: "H_KEYI — хук MSX, 82A3 и 82AB",
    0xFFFF: "SSLOT_REG — регистр субслотов MSX, 82C2",
    0x5000: "P1_RESIDENT — копия в page 1, 82D5",
    0x61A8: "P1_STACK_TOP — стек в page 1, 82D2",
    0x6522: "P1_HIMEM — копия в page 1, 82E0",
}

FAILED: list[str] = []


def _help_punct():
    """Зона знаков препинания справки — ИЗ САМОЙ СБОРКИ (адрес и длина).

    Числом здесь она уже стояла и молчала: сдвиг HELP_PUNCT_ORG в
    tools/build_port_rom.py клал справку внутрь байт-кода хода объектов,
    а этот сторож продолжал сверять старое число сам с собой.
    """
    import sys as _s
    _s.path.insert(0, str(Path(__file__).resolve().parent))
    import build_port_rom as _b
    import mk_help
    npunct = mk_help.build()[1]["stream_offset"]
    return _b.HELP_PUNCT_ORG, _b.HELP_PUNCT_ORG + npunct - 1


def _scr_blobs():
    """Куски байт-кода хода объектов — из самого раскладчика.

    ГОЛОВА БЛОКА (кусок по STAGE) в список НЕ идёт: она делит место с
    буфером атрибутов игры и разведена с ним ВО ВРЕМЕНИ — лежит там только
    до V_START, который переносит её в зону заставки (тот же приём, что у
    MIRBUF с хвостом заставки, docs/v06-memory.md § 8).
    """
    import sys as _s
    _s.path.insert(0, str(Path(__file__).resolve().parent))
    import mk_scripts
    r = mk_scripts.build()
    stage = r["copy"][0]
    return [(a, b) for a, b in r["blobs"] if a != stage]


def fail(msg: str):
    FAILED.append(msg)
    print(f"  FAIL {msg}")


def v06_mapped(a: int) -> bool:
    return v06_addr(a) is not None


# --- сборка ---------------------------------------------------------------

def assemble() -> dict[str, bytes]:
    """zasm по каждому куску disasm/msx/v06/*.asm."""
    out = {}
    names = [n for *_r, n in V06_LAYOUT] + [V06_SFX["name"]]
    for name in names:
        asm = D.v06_out(name, "out")
        binout = D.v06_out(name, "bin")
        if not asm.is_file():
            fail(f"нет {asm.relative_to(ROOT)} — сначала disasm_msx.py --v06")
            continue
        binout.parent.mkdir(parents=True, exist_ok=True)
        if binout.exists():
            binout.unlink()
        r = subprocess.run([str(ASM), "-b", "-l0", str(asm), "-o", str(binout)],
                           cwd=str(asm.parent), capture_output=True, text=True)
        if r.returncode != 0 or not binout.is_file():
            fail(f"zasm {asm.name}:\n{r.stdout}\n{r.stderr}")
            continue
        out[name] = binout.read_bytes()
    return out


def orig_image() -> tuple[bytearray, bytearray]:
    """64K-образ ОРИГИНАЛА после загрузки + маска заполненного."""
    p1 = (ROOT / "ref/msx/orig/SPIRITS.1.orig.payload").read_bytes()
    p2 = (ROOT / "ref/msx/orig/SPIRITS.2.orig.payload").read_bytes()
    mem, filled = bytearray(0x10000), bytearray(0x10000)

    def put(a: int, b: bytes):
        mem[a:a + len(b)] = b
        filled[a:a + len(b)] = b"\1" * len(b)

    put(SEGMENTS["2"]["orig"], p2)
    put(SEGMENTS["res"]["orig"], p1[:SEGMENTS["res"]["length"]])
    hi = SEGMENTS["hi"]
    put(hi["orig"], p1[hi["file_off"]:hi["file_off"] + hi["length"]])
    put(ORIG_SFX[0], p1[V06_SFX["src"]:V06_SFX["src"] + V06_SFX["length"]])
    return mem, filled


# --- проверка 1: геометрия ------------------------------------------------

def check_geometry(bins: dict[str, bytes]) -> tuple[bytearray, bytearray]:
    print("\n=== 1. геометрия: куски легли туда, куда обещает карта")
    mem, filled = bytearray(0x10000), bytearray(0x10000)
    pieces = [(name, lo, hi, org) for key, lo, hi, org, name in V06_LAYOUT]
    pieces.append((V06_SFX["name"], ORIG_SFX[0] + 0x100, ORIG_SFX[1] + 0x100,
                   V06_SFX["org"]))
    covered = 0
    for name, lo, hi, org in pieces:
        b = bins.get(name)
        if b is None:
            continue
        want = hi - lo + 1
        if len(b) != want:
            fail(f"{name}: собрано {len(b)} байт, ожидалось {want}")
            continue
        over = [a for a in range(org, org + len(b)) if filled[a]]
        # D000 оригинала: последний байт SPIRITS.2 затирается первым байтом
        # резидентного слоя — ровно как в оригинале (docs/msx-memory.md).
        if over and not (len(over) == 1 and over[0] == v06_addr(0xD000)):
            fail(f"{name}: перекрытие с уже уложенным, {len(over)} байт"
                 f" c {over[0]:04X}")
        mem[org:org + len(b)] = b
        filled[org:org + len(b)] = b"\1" * len(b)
        covered += len(b)
        print(f"  {name:14s} {org:04X}..{org + len(b) - 1:04X}"
              f"  {len(b):5d} б   (оригинал {lo - 0x100:04X}..{hi - 0x100:04X})")
    # Схема цвета «Exolon»: ВИДИМЫ три верхние плоскости A000..FFFF, невидима
    # нижняя 8000..9FFF (палитра: pal[i] == pal[i & 7]). Блок данных игры
    # 14 146 б в одну плоскость не влезает, поэтому лежит 6847..9F88 —
    # головой в обычной RAM, хвостом в невидимой плоскости.
    V06_VISIBLE = 0xA000
    DATA_PIECE = "spirits2_data"
    dorg = next(org for n, _l, _h, org in pieces if n == DATA_PIECE)
    dend = next(org + (hi - lo) for n, lo, hi, org in pieces if n == DATA_PIECE)
    lo_lo = min(org for _n, _l, _h, org in pieces)
    lo_hi = max(org + (hi - lo) for n, lo, hi, org in pieces if n != DATA_PIECE)
    # Рабочая область игры шире, чем блок из файла: теневые таблицы спрайтов
    # живут до 48FF, плюс страница заворота 4900..49FF (disasm_msx.py,
    # V06_WORK_END).  Ничего постороннего туда класть нельзя.
    work_hi = max(org + (hi - lo) for _n, lo, hi, org in pieces
                  if org + (hi - lo) <= V06_WORK_END)
    print(f"  рабочая RAM  {work_hi + 1:04X}..{V06_WORK_END:04X}"
          f"  теневые таблицы спрайтов и заворот (пусто в образе)")
    # --- ЗОНЫ В НИЗКОЙ ПАМЯТИ.  Всё, что порт кладёт поверх образа игры,
    # перечислено здесь поимённо.  Две проверки: зона не смеет пересечься
    # с ЖИВОЙ рабочей областью игры 39C6..407D и зоны не смеют пересечься
    # между собой.
    # ГРАНИЦА СДВИНУТА С 49FF НА 407D (слияние E + F, 2026-09-22).  Этап E
    # выбросил обе чистки в D0F2 (патч BYTE_TAB 1A02: jp 1D90) и вместе с
    # ними убил теневую SAT 407E..40FD, теневые образы 40FE..48FD и страницу
    # заворота 4900..49FF: объект попадает на экран прямо из D0A0, а образ —
    # прямо из перепакованного банка.  Доказательство — счётчик SHADOW в
    # tools/trap_stale_v06js.js: код игры за 3000 кадров читал эту зону
    # 0 раз и писал 0 раз.  Списки объектов SPRL/SPRO теперь живут ТАМ
    # (4400/4510): тело адаптера после слияния не влезало в 5000..60E3 и
    # зону пришлось продлить до 631F, а списки стояли ровно над ней.
    V06_WORK_LIVE = 0x407D      # живая рабочая RAM игры кончается здесь
    # КУСКИ РАБОЧЕЙ RAM ИГРЫ, ДОКАЗАННО МЁРТВЫЕ (2026-09-23).  Ловушка на
    # чтение И запись по каждому байту (tools/zonewatch.js) на сценариях,
    # где игра идёт разными путями: playthrough MODE=full и MODE=sphere,
    # allrooms (77 комнат, 929 рычагов, 20 тьма, 20 вспышек, 160 A_COPY,
    # 20 смертей), потеря всех жизней с выходом на экран итога — оба
    # образа, везде 0 чтений и 0 записей.  Только эти куски внутри
    # 39C6..407D разрешено занимать чужим данным.
    V06_WORK_DEAD = [
        (0x3AA8, 0x3B2E),   # байт-код хода объектов, кусок 2
        (0x3B32, 0x3BB8),   # байт-код хода объектов, кусок 3
        (0x3BB9, 0x3C00),   # знаки препинания страницы справки
        (0x3F55, 0x407D),   # байт-код хода объектов, кусок «остался на месте»
    ]
    # Новую зону (теневая таблица, кэш, буфер) ОБЯЗАТЕЛЬНО вписывать сюда,
    # иначе она молча ляжет на чужую.
    zones = [
        ("адаптер ввода и звука", 0x4A00, 0x4DE7),   # src/v06/adapter.asm
        ("связка", 0x4DE8, 0x4EA9),                  # src/v06/glue.asm
        # ЧИТЫ (docs/cheats.md, 2026-09-22): src/v06/cheat.asm, org 4F3E.
        # Кладёт в образ tools/build_port_rom.py, в build/adapter/spirits.rom
        # модуля нет — зона объявлена здесь ради сверки перекрытий.
        ("модуль читов", 0x4F3E, 0x4FD7),            # src/v06/cheat.asm
        # Ячейки рантайма рекомпиляции i8080 (z80_ix, z80_iy, il_tmp...):
        # docs/v06-memory.md § 16.  В образе Z80 они не нужны, но зона
        # объявлена всегда — чтобы её никто не занял.
        ("ячейки рантайма i8080", 0x4FD8, 0x4FE6),
        # Таблица эффектов уехала с 5BAA в дырку за связкой: адаптеру экрана
        # на этапе C (три плоскости, карта чернил, палитра на комнату) нужна
        # вся зона до стека.  org обязан кончаться на 0xAA — поправка от
        # оригинала 64AA кратна странице (docs/v06-memory.md, § 3).
        ("таблица эффектов", V06_SFX["org"],
         V06_SFX["org"] + V06_SFX["length"] - 1),
        # Слияние E + F: зона продлена с 60E3 до 631F.  Тело «2 + 1» стало
        # 4495 б (E дал +759, F дал +353 к 3355 б схемы до обоих этапов),
        # а 5000..60E3 держала 4324.  Освободили её списки объектов —
        # они уехали в мёртвые теневые таблицы (4400/4510), а вторая зона
        # переменных и приёмник 2:CE83 — в ничейную дырку 4F22..4FFF.
        ("адаптер экрана", 0x5000, 0x6425),          # src/v06/screen_adapter.asm
        ("стек", V06_STACK_BOT, V06_STACK_TOP - 1),
        # ЭТАП E: слоты SPRST (33 x 4), копии образов SPRSAV (32 x 32) и
        # столбцы героя HR_SAV умерли вместе с теневыми таблицами игры:
        # объект попадает на экран прямо из D0A0 и прямо из перепакованного
        # банка.  Вместо них — два СПИСКА ОБЪЕКТОВ по 8 байт на запись
        # (что рисуем в этом кадре и что стоит на экране) и буфер
        # зеркального столбца.
        # Третья зона переменных адаптера экрана (2026-09-22, слияние
        # стирания и рисования): дырка между страницей справки полного
        # порта (407E..42F2) и списком объектов.  В ОТЛИЧИЕ от зон 6800 и
        # 4F22 она НЕ пуста в образе — 02A0..43C5 это блок игры целиком, —
        # поэтому SCR_INIT чистит её нулями (V_VAR3_LEN байт).
        ("переменные адаптера экрана 3 (V_VAR3)", 0x4300, 0x4394),
        ("список объектов кадра (SPRL)", 0x4400, 0x450F),   # 34 x 8
        ("нарисовано сейчас (SPRO)", 0x4510, 0x461F),       # 34 x 8
        ("буфер зеркального столбца (MIRBUF)", 0x4864, 0x488B),
        # Слияние стирания и рисования (SPR_MERGE, 2026-09-22):
        # сорок нулей «столбца образа здесь нет» и карта переноса
        # (хвост страницы 49, до 40 б).  Обе в мёртвых теневых
        # таблицах спрайтов игры; MG_ZBUF не инициализируется —
        # образ .rom кладёт сюда нули, и никто сюда не пишет.
        ("нули слияния (MG_ZBUF)", 0x4990, 0x49B7),
        ("карта переноса слияния (MG_CARRY)", 0x49D8, 0x49FF),
        # Таблицы адресов записей банков (58*2 + 53*2): их кладёт в образ
        # tools/build_v06_rom.py, считает tools/repack_banks.py.  В теле
        # адаптера им места нет — оно упирается в 5F7F.
        ("адреса записей банков (BKP)", repack_banks.BKP_ORG,
         repack_banks.BKP_END),
        # Карта чернил этапа C: код цвета (0..7) на каждое из 32x24
        # знакомест.  Адрес = 6400 + (l>>3)*32 + столбец, то есть карте
        # нужны 768 подряд идущих байт с выравниванием на страницу.
        ("карта чернил (INKMAP)", 0x6500, 0x67FF),
        # Этап D: ячейки адаптера экрана, которым не хватило места в
        # теле (5000..5F7F).  Дырка между картой чернил и блоком
        # данных игры; образ .rom кладёт туда нули, поэтому
        # инициализация не нужна — как у SPRST/SPRSAV.
        ("переменные адаптера экрана", 0x6800, 0x6845),
        # 2:CE83 `ld de,0x7F9C / ld bc,8 / ldir` — 8 байт в адрес, которого на
        # MSX нет ни в одном сегменте (образ начинается с 82A0), читателей у
        # него в живом коде нет. Пока блок данных лежал на 8847, 7F9C попадал
        # в свободную зону; после переезда на 6847 он пришёлся бы на карты
        # комнат (оригинал 9B9C). Адаптер правит старший байт операнда
        # (BYTE_TAB), и запись уходит сюда.
        ("приёмник мёртвой записи 2:CE83", 0x4F36, 0x4F3D),
        # Этап D: вторая горсть ячеек адаптера экрана — дырка между
        # приёмником 2:CE83 и SPRSAV.
        ("переменные адаптера экрана 2", 0x4F22, 0x4F35),
        ("LOW_TILE_SRC", V06_LOW_TILE, V06_LOW_TILE + 7),
        # БАЙТ-КОД ХОДА БРОДЯЧИХ ОБЪЕКТОВ (tools/mk_scripts.py,
        # docs/known-issues-ballview.md).  Раскладку считает сам модуль —
        # зоны берутся оттуда, чтобы список не разъехался с образом.
        *[(f"байт-код хода объектов {k}", a, a + len(b) - 1)
          for k, (a, b) in enumerate(_scr_blobs())],
        # Страница справки: знаки препинания и поток текста.  Обе зоны
        # свободны ДО старта игры, а после его старта первую переиспользует
        # игра, вторую — списки объектов SPRL/SPRO (разведены во времени,
        # как MIRBUF с заставкой).
        # Адрес берётся ИЗ САМОЙ СБОРКИ, а не числом: пока он стоял здесь
        # копией, сдвиг HELP_PUNCT_ORG клал справку внутрь байт-кода, и ни
        # сборка, ни этот сторож не падали (проверено 2026-09-23).
        ("справка: знаки препинания", *_help_punct()),
    ]
    def _dead_ok(a: int, b: int) -> bool:
        """Весь кусок [a,b] внутри живой области покрыт мёртвыми кусками?"""
        for x in range(max(a, 0x39C6), min(b, V06_WORK_LIVE) + 1):
            if not any(d0 <= x <= d1 for d0, d1 in V06_WORK_DEAD):
                return False
        return True

    for nm, lo_a, hi_a in zones:
        if not (hi_a < 0x39C6 or lo_a > V06_WORK_LIVE) and not _dead_ok(lo_a, hi_a):
            fail(f"{nm} {lo_a:04X}..{hi_a:04X} попал в ЖИВУЮ рабочую область"
                 f" игры 39C6..{V06_WORK_LIVE:04X} (буферы объектов, буфер"
                 f" зеркалирования, массив ix)")
        if not (hi_a < dorg or lo_a > dend):
            fail(f"{nm} {lo_a:04X}..{hi_a:04X} попал в блок данных игры"
                 f" {dorg:04X}..{dend:04X}")
    for i, (n1, l1, h1) in enumerate(zones):
        for n2, l2, h2 in zones[i + 1:]:
            if l1 <= h2 and l2 <= h1:
                fail(f"зоны пересекаются: {n1} {l1:04X}..{h1:04X}"
                     f" и {n2} {l2:04X}..{h2:04X}")
    for nm, lo_a, hi_a in sorted(zones, key=lambda z: z[1]):
        print(f"  зона         {lo_a:04X}..{hi_a:04X}"
              f"  {hi_a - lo_a + 1:5d} б   {nm}")
    print(f"  низкая RAM   {lo_lo:04X}..{lo_hi:04X}"
          f"  ({lo_hi - lo_lo + 1} байт, без блока данных)")
    print(f"  блок данных  {dorg:04X}..{dend:04X}"
          f"  ({dend - dorg + 1} байт; хвост {0x8000:04X}..{dend:04X} —"
          f" НЕВИДИМАЯ плоскость)")
    st_lo = V06_STACK_BOT
    print(f"  стек         {st_lo:04X}..{V06_STACK_TOP - 1:04X}"
          f"  (вершина {V06_STACK_TOP:04X}, {V06_STACK_TOP - st_lo} байт)")
    # Свободное место между вершиной стека и блоком данных — по факту, а не
    # «от последней зоны»: зоны адаптера экрана стоят там с дырками.
    busy = bytearray(0x10000)
    for _n, lo_a, hi_a in zones:
        for a in range(lo_a, hi_a + 1):
            busy[a] = 1
    gaps, a = [], V06_STACK_TOP
    while a < dorg:
        if busy[a]:
            a += 1
            continue
        b = a
        while b < dorg and not busy[b]:
            b += 1
        gaps.append((a, b - 1))
        a = b
    free = sum(hi_a - lo_a + 1 for lo_a, hi_a in gaps)
    print(f"  свободно     {free} байт между {V06_STACK_TOP:04X} и блоком"
          f" данных: " + ", ".join(f"{l:04X}..{h:04X}" for l, h in gaps))
    print(f"               + {dend + 1:04X}..{V06_VISIBLE - 1:04X}"
          f" ({V06_VISIBLE - dend - 1} б, хвост невидимой плоскости)")
    print(f"  занято всего {covered} байт")
    for name, lo, hi, org in pieces:
        if org + (hi - lo) >= V06_VISIBLE:
            fail(f"{name} залез в ВИДИМЫЕ плоскости"
                 f" ({V06_VISIBLE:04X}..FFFF)")
    if lo_hi >= dorg:
        fail("низкий блок налез на блок данных")
    return mem, filled


# --- проверка 2: байт в байт против оригинала -----------------------------

def relocated_bytes() -> dict[int, int]:
    """{адрес байта в ОРИГИНАЛЕ: каким он обязан стать в образе Вектора}.

    Строится по списку, который вёл генератор: (адрес канона, длина, было,
    стало). 16-битный операнд z80 — всегда два последних байта элемента;
    «было» тут не нужно: сверяется то, что реально лежит в обоих образах.
    """
    out: dict[int, int] = {}
    for pc, ln, _old, new in D.RELOCATED:
        a = pc - 0x100 + ln - 2
        out[a] = new & 0xFF
        out[a + 1] = new >> 8
    return out


def check_bytes(omem: bytearray, ofill: bytearray,
                vmem: bytearray, vfill: bytearray) -> int:
    print("\n=== 2. образ Вектора = образ оригинала + РОВНО переехавшие"
          " операнды")
    want = relocated_bytes()
    diff, bad, wrong = [], [], []
    n = 0
    for a in range(0x10000):
        if not ofill[a] or not v06_mapped(a):
            continue
        va = v06_addr(a)
        if not vfill[va]:
            fail(f"оригинальный байт {a:04X} никуда не лёг")
            continue
        n += 1
        if a in want and vmem[va] != want[a]:
            wrong.append((a, vmem[va], want[a]))
        if omem[a] != vmem[va]:
            diff.append(a)
            if a not in want:
                bad.append((a, omem[a], vmem[va]))
    print(f"  сверено байт: {n}")
    print(f"  переехавших операндов: {len(D.RELOCATED)},"
          f" затронуто байтов {len(want)}")
    print(f"  байтов реально различается: {len(diff)}")
    if bad:
        fail(f"{len(bad)} различий не объяснены переездом операнда: "
             + ", ".join(f"{a:04X}({o:02X}->{v:02X})" for a, o, v in bad[:20]))
    if wrong:
        fail(f"{len(wrong)} переехавших байтов собрались не так: "
             + ", ".join(f"{a:04X}: {g:02X} вместо {w:02X}"
                         for a, g, w in wrong[:20]))
    if not bad and not wrong:
        print(f"    все {len(diff)} различий — ровно байты переехавших"
              " операндов, и каждый равен значению карты")
        print(f"    остальные {n - len(diff)} байт совпали с оригиналом"
              " дословно")
    return len(bad) + len(wrong)


# --- проверка 3: ни одного числа на старое место --------------------------

# Окна разбора: [(база, конец, ключ сегмента)] в обеих раскладках. В
# оригинале сегменты лежат подряд; на Векторе голова и хвост SPIRITS.2 тоже
# оказываются рядом (0200..03A6 и 03A7..181E), а блок данных вынесен в
# плоскости — кода в нём нет, поэтому окно сегмента «2» остаётся одним.
def windows(v06: bool):
    out = []
    for key in ("2", "res"):
        seg = SEGMENTS[key]
        lo, hi = seg["orig"], seg["orig"] + len(D.seg_bytes(seg))
        if v06:
            if key == "2":
                lo, hi = v06_addr(0x82A0), v06_addr(0xD000) + 1
            else:
                lo, hi = v06_addr(0xD000), v06_addr(0xE04A) + 1
        out.append((lo, hi, key))
    return out


def runtime_code(mem: bytearray, v06: bool):
    """Разбор рантайма по сегментам: {адрес: Insn}."""
    code = {}
    for lo, hi, key in windows(v06):
        entries = [a - 0x100 for a in D.seg_entries(key)]
        if v06:
            entries = [v06_addr(a) for a in entries]
        code.update(disasm_reachable(mem, [e for e in entries if e], lo, hi))
    return code


def canon_image() -> bytearray:
    """64K-образ КАНОНА: по нему решается, адрес это или константа."""
    mem = bytearray(0x10000)
    for key in ("2", "res", "hi"):
        seg = SEGMENTS[key]
        b = D.seg_bytes(seg)
        mem[seg["load"]:seg["load"] + len(b)] = b
    return mem


def is_address(ins, pc: int, cmem: bytearray) -> bool:
    """Считал ли генератор этот операнд адресом.

    abs16 (`call nn`, `ld a,(nn)`) — всегда. imm16 (`ld hl,nn`) — только в
    диапазоне образа, и решается это по ЗНАЧЕНИЮ В КАНОНЕ: константа в
    каноне и в оригинале одна и та же, а адрес в каноне на 0x100 выше. Иначе
    ноты музыкального плеера (`ld de,0x82A6`) не отличить от адресов внутри
    образа оригинала, который начинается с 0x82A0.
    """
    if ins.opkind == "abs16":
        return True
    if ins.opkind != "imm16":
        return False
    ci = decode(cmem[pc + 0x100:], pc + 0x100)
    cv = ci.operand if ci.length == ins.length else ins.operand
    return (IMM_LO <= cv < IMM_HI) or cv in PAGE1 or cv in LOWMEM


def check_no_old(omem: bytearray, vmem: bytearray) -> int:
    print("\n=== 3. ни одного числа, указывающего на старое место")
    cmem = canon_image()
    ocode = runtime_code(omem, False)
    vcode = runtime_code(vmem, True)
    print(f"  инструкций: оригинал {len(ocode)}, Вектор {len(vcode)}")
    lost = sorted({v06_addr(pc) for pc in ocode} - set(vcode))
    if lost:
        fail(f"{len(lost)} инструкций оригинала не нашлись в образе Вектора: "
             + ", ".join(f"{a:04X}" for a in lost[:20]))
    extra = sorted(set(vcode) - {v06_addr(pc) for pc in ocode})
    if extra:
        fail(f"{len(extra)} инструкций образа Вектора нет в оригинале: "
             + ", ".join(f"{a:04X}" for a in extra[:20]))
    moved = const = 0
    stayed_old: list[tuple[int, int, str]] = []
    excused: dict[int, int] = {}
    border: list[tuple[int, int, int, int | None]] = []
    for pc, ins in sorted(ocode.items()):
        if ins.opkind not in ("abs16", "imm16") or ins.operand is None:
            continue
        vpc = v06_addr(pc)
        vins = vcode.get(vpc)
        if vins is None or vins.length != ins.length:
            fail(f"{pc:04X}: инструкция не совпала с {vpc:04X}")
            continue
        v, vv = ins.operand, vins.operand
        if not is_address(ins, pc, cmem):
            const += 1
            if vv != v:
                fail(f"{pc:04X}: константа {v:04X} поехала на {vv:04X}")
            continue
        want = v06_addr(v)
        # Граничный указатель (D.BORDER_PTRS) едет не по своему числу, а
        # вместе с областью-владельцем: `ROOM_MAPS-1` численно лежит в голове
        # стадии 2, а по смыслу принадлежит картам комнат. Адреса в таблице —
        # КАНОНА, здесь — оригинала, отсюда поправка на 0x100.
        owner = D.BORDER_PTRS.get(v + 0x100)
        if owner is not None:
            ow = v06_addr(owner - 0x100)
            want = None if ow is None else ow - (owner - 0x100 - v)
            border.append((pc, v, vv, want))
        if want is not None and vv == want:
            moved += 1
            continue
        if vv != v:
            fail(f"{pc:04X}: операнд {v:04X} -> {vv:04X}, а карта даёт"
                 f" {want if want is None else f'{want:04X}'}")
            continue
        # Адрес остался числом. Законно только для списка KNOWN_FIXED.
        if v in KNOWN_FIXED:
            excused[v] = excused.get(v, 0) + 1
        else:
            stayed_old.append((pc, v, ins.text(None)))
    for bpc, bv, bvv, bw in border:
        print(f"  граничный указатель {bpc:04X}: {bv:04X} -> {bvv:04X}"
              f" (едет с областью-владельцем, а не по своему числу)")
    print(f"  адресных операндов: переехало {moved},"
          f" осталось числом {sum(excused.values()) + len(stayed_old)}")
    print(f"  констант (не адреса, по значению в каноне): {const}")
    print("  остались числом — известные исключения, все в мёртвой на"
          " Векторе голове стадии 2:")
    for v, cnt in sorted(excused.items()):
        print(f"    {v:04X} x{cnt}  {KNOWN_FIXED[v]}")
    if stayed_old:
        fail(f"{len(stayed_old)} чисел смотрят на старое место: "
             + "; ".join(f"{pc:04X} {t} (={v:04X})"
                         for pc, v, t in stayed_old[:20]))
    else:
        print("  НЕИЗВЕСТНЫХ чисел на старое место: 0")
    return len(stayed_old)


# --- проверка 4: адреса, собранные из байтов -------------------------------
#
# Ассемблер их не видит: старший байт адреса лежит однобайтовой константой,
# а младший приходит в регистре. Перечень — docs/msx-relocation.md, § 5.3.
# Автоматически их не починить, но проверить МОЖНО: раз все поправки карты
# кратны 0x100, нужная новая константа считается однозначно, и её можно
# выписать. Формат: адрес инструкции в ОРИГИНАЛЕ -> (смещение байта внутри
# инструкции, что адресует, комментарий).
# Ключ — адрес команды `ld r,const` в ОРИГИНАЛЕ; константа всегда байт
# pc+1. Значение — (что адресует, бесспорно ли, пояснение).
BYTE_ADDR = {
    0xD0AD: (0xF317, True,
             "res: add a,0x17 / ld l,a / ld h,0xF3 / ld a,(hl)"
             " — таблица F317..F396 в рабочей RAM"),
    0xD2E7: (0xD508, True,
             "res: ld c,(hl) / ld b,0xD5 / ld a,(bc)"
             " — таблица D5xx в резидентном слое"),
    # Три бывших «спорных» РАЗОБРАНЫ и закрыты как ЗНАЧЕНИЯ, а не адреса —
    # их нельзя ни чинить, ни патчить (правка меняла бы константу).
    0xC118: (None, False,
             "2: ld l,c / ld h,0xA8 — ЗНАЧЕНИЕ (координата): соседние ветки"
             " кладут в ту же пару ld h,b / ld l,0x60 / ld l,0x20 /"
             " ld h,0x00, а через четыре команды та же константа стоит"
             " порогом сравнения ld a,0xA8 / cp b; пара уходит в push hl"),
    0xBEC1: (None, False,
             "2: ld d,0x98 — ЗНАЧЕНИЕ (флаг): единственное употребление"
             " ld h,d в BE9B, дальше ld a,h / cpl / and 0x80 — читается"
             " только бит 7, а сам d тут же затирает ld a,r / ld d,a"),
    0xC3D3: (None, False,
             "2: ld d,0xF8 — ЗНАЧЕНИЕ (знаковое смещение): рядом"
             " ld d,0x10 и ld e,0xF6 по той же ветке"),
}


def check_byte_addr(omem: bytearray, vmem: bytearray) -> int:
    print("\n=== 4. адреса, собранные из байтов (ассемблер их не двигает)")
    print("  Поправки карты кратны 0x100, поэтому правка каждого такого"
          " места — РОВНО один байт:")
    bad = 0
    for pc, (what, sure, why) in sorted(BYTE_ADDR.items()):
        cur, va = omem[pc + 1], v06_addr(pc)
        if what is None:                      # разобрано: это не адрес
            if vmem[va + 1] != cur:
                fail(f"{pc:04X}: байт изменён ({cur:02X} ->"
                     f" {vmem[va + 1]:02X}), а это ЗНАЧЕНИЕ, не адрес")
                bad += 1
            print(f"  НЕ АДРЕС   оригинал {pc:04X} -> Вектор {va:04X}:"
                  f" байт {va + 1:04X} = {cur:02X} остаётся как есть")
            print(f"      {why}")
            continue
        new = v06_addr(what)
        if vmem[va + 1] != cur:
            fail(f"{pc:04X}: байт-страница уже изменён"
                 f" ({cur:02X} -> {vmem[va + 1]:02X}) — так не задумано")
            bad += 1
        if new is None:
            fail(f"{pc:04X}: цель {what:04X} вне карты переезда")
            bad += 1
            continue
        if (what & 0xFF) != (new & 0xFF):
            fail(f"{pc:04X}: поправка не кратна странице,"
                 f" одним байтом не починить")
            bad += 1
        mark = "БЕССПОРНО" if sure else "спорно   "
        print(f"  {mark}  оригинал {pc:04X} -> Вектор {va:04X}:"
              f" байт {va + 1:04X} = {cur:02X}, нужно {new >> 8:02X}"
              f"   ({what:04X} -> {new:04X})")
        print(f"      {why}")
    print("  Две бесспорные правит адаптер (BYTE_TAB в"
          " src/v06/screen_adapter.asm); три разобраны как значения и не"
          " правятся. Шестой адрес из байтов — res:D0FA/D0FE (F800,"
          " `ld (ix+d),n` парой) — тоже в BYTE_TAB; сплошной поиск всех"
          " форм: tools/find_byte_addrs.py, других пар в образе нет.")
    return bad


# --- проверка 5: прежние проверки ------------------------------------------

def check_old_green() -> int:
    print("\n=== 5. прежние проверки остались зелёными")
    bad = 0
    # В этом репозитории — только round-trip канона (+0x100).
    # verify_orig (кассета / reshift) живёт в полном исследовательском дереве.
    for name in ("verify_disasm.py",):
        r = subprocess.run([sys.executable, str(ROOT / "tools" / name)],
                           capture_output=True, text=True)
        lines = [x for x in r.stdout.strip().splitlines() if x.strip()]
        last = lines[-1] if lines else "(нет вывода)"
        print(f"  {name}: код {r.returncode} — {last}")
        if r.returncode != 0:
            bad += 1
            fail(f"{name} КРАСНЫЙ")
    print("  verify_orig.py: пропущен (нет кассеты/reshift в этом репо)")
    return bad


# --- выгрузка для стенда ---------------------------------------------------

# Загрузчик стенда. На MSX ровно те же действия, что стадия 2 оригинала
# делала через BIOS: RAM во всех страницах, экран в SCREEN 2 со спрайтами
# 16x16, стек, переход в игровой цикл. Отличие одно и намеренное: регистры
# VDP пишутся прямо в порт, а не через BIOS, потому что page 0 к этому
# моменту уже RAM и BIOS'а нет. Один и тот же загрузчик используется для
# ОБЕИХ раскладок — меняются только sp и точка входа.
STUB_ORG = 0xFB00
STUB_ASM = """; Загрузчик стенда openMSX (сгенерирован tools/verify_v06.py).
\torg\t0x{org:04X}
\tdi
\tld\ta,0xFF
\tout\t(0xA8),a\t\t; все четыре страницы -> слот 3 (RAM)
\tld\thl,VDPTAB
\tld\tb,0x00
NEXT:
\tld\ta,(hl)
\tout\t(0x99),a\t\t; значение
\tld\ta,b
\tor\t0x80
\tout\t(0x99),a\t\t; номер регистра
\tinc\thl
\tinc\tb
\tld\ta,b
\tcp\t0x08
\tjr\tnz,NEXT
\tld\tsp,0x{sp:04X}
\tim\t1
\tei
\tjp\t0x{entry:04X}
VDPTAB:
\t; R#0..R#7: SCREEN 2, спрайты 16x16, SAT 1B00, образы 3800, рамка чёрная
\tdb\t0x02,0xE2,0x06,0xFF,0x03,0x36,0x07,0x01
"""
# Обработчик прерывания MSX на месте RST 38h: BIOS'а больше нет, а флаг
# прерывания VDP снимать надо, иначе первое же прерывание зациклится.
ISR_ADDR = 0x0038
ISR_CODE = bytes([0xF5, 0xDB, 0x99, 0xF1, 0xFB, 0xED, 0x4D])  # push af/in
#   a,(99)/pop af/ei/reti


def build_stub(name: str, sp: int, entry: int) -> bytes:
    d = ROOT / "build/v06"
    d.mkdir(parents=True, exist_ok=True)
    asm = d / f"stub-{name}.asm"
    binout = d / f"stub-{name}.bin"
    asm.write_text(STUB_ASM.format(org=STUB_ORG, sp=sp, entry=entry))
    if binout.exists():
        binout.unlink()
    r = subprocess.run([str(ASM), "-b", "-l0", str(asm), "-o", str(binout)],
                       cwd=str(d), capture_output=True, text=True)
    if r.returncode != 0 or not binout.is_file():
        fail(f"zasm {asm.name}:\n{r.stdout}\n{r.stderr}")
        return b""
    return binout.read_bytes()


def write_stand(vmem, vfill, omem, ofill):
    """Плоские блоки для openMSX: что куда грузить и откуда стартовать."""
    d = ROOT / "build/v06"
    d.mkdir(parents=True, exist_ok=True)
    (d / "isr.bin").write_bytes(ISR_CODE)
    for nm, sp, entry in (("v06", V06_STACK_TOP, V06_ENTRY),
                          ("orig", ORIG_STACK_TOP, ORIG_ENTRY)):
        b = build_stub(nm, sp, entry)
        print(f"  загрузчик stub-{nm}.bin: {len(b)} байт по {STUB_ORG:04X},"
              f" sp {sp:04X}, entry {entry:04X}")
    # Границы блоков берутся из раскладки, а не вписаны руками: один
    # забытый литерал здесь — и на стенд уехал бы сдвинутый образ.
    ends = [(org, org + (hi - lo), n) for _k, lo, hi, org, n in V06_LAYOUT]
    # Таблица эффектов ОТДЕЛЬНЫМ блоком: она уехала за стек (5BAA), а между
    # ней и низким блоком стоят адаптеры (4A00..5BA9) — одним куском не выйдет.
    sfx_lo = V06_SFX["org"]
    sfx_hi = sfx_lo + V06_SFX["length"] - 1
    # Блок данных игры — тоже отдельным куском: между ним и низким блоком
    # лежат рабочая область игры, адаптеры, стек и таблицы адаптера экрана.
    DATA_PIECE = "spirits2_data"
    lo_lo = min(a for a, _b, n in ends if n != DATA_PIECE)
    lo_hi = max(b for _a, b, n in ends if n != DATA_PIECE)
    pl_lo = min(a for a, _b, n in ends if n == DATA_PIECE)
    pl_hi = max(b for _a, b, n in ends if n == DATA_PIECE)
    (d / "v06-low.bin").write_bytes(bytes(vmem[lo_lo:lo_hi + 1]))
    (d / "v06-sfx.bin").write_bytes(bytes(vmem[sfx_lo:sfx_hi + 1]))
    (d / "v06-plane.bin").write_bytes(bytes(vmem[pl_lo:pl_hi + 1]))
    (d / "orig-runtime.bin").write_bytes(
        bytes(omem[ORIG_RUNTIME[0]:ORIG_RUNTIME[1] + 1]))
    (d / "orig-sfx.bin").write_bytes(
        bytes(omem[ORIG_SFX[0]:ORIG_SFX[1] + 1]))
    man = {
        "isr": [ISR_ADDR, "isr.bin"],
        "stub_org": STUB_ORG,
        "fill": 0xA5,
        "v06": {
            "blocks": [["v06-low.bin", lo_lo], ["v06-sfx.bin", sfx_lo],
                       ["v06-plane.bin", pl_lo]],
            "stub": "stub-v06.bin",
            "entry": V06_ENTRY, "sp": V06_STACK_TOP,
            "stack_bot": V06_STACK_BOT,
            "sync": v06_addr(ORIG_SYNC),
            "footprint": [[lo_lo, lo_hi], [sfx_lo, sfx_hi], [pl_lo, pl_hi]],
        },
        "orig": {
            "blocks": [["orig-runtime.bin", ORIG_RUNTIME[0]],
                       ["orig-sfx.bin", ORIG_SFX[0]]],
            "stub": "stub-orig.bin",
            "entry": ORIG_ENTRY, "sp": ORIG_STACK_TOP,
            "sync": ORIG_SYNC,
            "footprint": [list(ORIG_RUNTIME), list(ORIG_SFX)],
        },
        "map": [[lo, hi, new] for lo, hi, new, _p1 in V06_MAP_ORIG],
    }
    (d / "manifest.json").write_text(json.dumps(man, indent=2))
    # Конфиг для стенда openMSX: tools/openmsx/run-layout.tcl его source'ит.
    for nm in ("v06", "orig"):
        m = man[nm]
        blocks = [f"{{{f} 0x{a:04X}}}" for f, a in m["blocks"]]
        blocks.append(f"{{{m['stub']} 0x{STUB_ORG:04X}}}")
        blocks.append(f"{{isr.bin 0x{ISR_ADDR:04X}}}")
        (d / f"load-{nm}.tcl").write_text(
            f"# сгенерировано tools/verify_v06.py --write\n"
            f"set ::LAYOUT {nm}\n"
            f"set ::ENTRY 0x{m['entry']:04X}\n"
            f"set ::SP 0x{m['sp']:04X}\n"
            f"set ::STUB 0x{STUB_ORG:04X}\n"
            f"set ::FILL 0x{man['fill']:02X}\n"
            f"set ::SYNC 0x{m['sync']:04X}\n"
            f"set ::BLOCKS {{ {' '.join(blocks)} }}\n")
    print(f"\nзаписано для стенда: build/v06/v06-low.bin"
          f" ({lo_hi - lo_lo + 1} б), v06-sfx.bin ({sfx_hi - sfx_lo + 1} б),"
          f" v06-plane.bin ({pl_hi - pl_lo + 1} б),"
          f" orig-runtime.bin, orig-sfx.bin, manifest.json")


def check_repacked() -> int:
    """ЭТАП E: зоны банков в собранном .rom — ровно выход repack_banks.py.

    Перепаковка делается СТАДИЕЙ СБОРКИ, а не правкой эталона: round-trip
    (проверки 2, 3, 5) сверяют дизасм и кассету с ИСХОДНЫМИ байтами, и
    трогать их нельзя.  Значит честность держится здесь: берём .rom, берём
    исходный образ, прогоняем через ту же программу и требуем побайтового
    совпадения в зонах банков.
    """
    print("\n=== 6. банки образов перепакованы ПО СТОЛБЦАМ (этап E)")
    # Тело адаптера в зону 5000..6425 — ОБЕИМИ схемами.  Раньше этого никто
    # не проверял, и «Exolon» молча вылез бы на списки объектов.
    for tag, nm in (("«2 + 1»", "screen_adapter.bin"),
                    ("«Exolon»", "screen_adapter-exolon.bin")):
        f = ROOT / "build/adapter" / nm
        if not f.is_file():
            continue
        n = f.stat().st_size
        lim = 0x6426 - 0x5000
        if n > lim:
            fail(f"тело адаптера {tag}: {n} б не влезает в зону"
                 f" 5000..6425 ({lim} б), лишних {n - lim}")
        else:
            print(f"  тело адаптера {tag:9s} {n:5d} б из {lim}"
                  f"  (свободно {lim - n})")
    rom_p = ROOT / "build/adapter/spirits.rom"
    if not rom_p.is_file():
        print("  build/adapter/spirits.rom не собран — проверка пропущена"
              " (сначала python3 tools/build_v06_rom.py)")
        return 0
    rom = bytearray(rom_p.read_bytes())
    base = 0x0100
    want = bytearray(0x10000)
    for nm, org in (("v06-low.bin", 0x02A0), ("v06-plane.bin", 0x6847)):
        f = ROOT / "build/v06" / nm
        b = f.read_bytes()
        want[org:org + len(b)] = b
    repack_banks.repack(want, 0, quiet=True)
    ok = True
    for name, (lo, _n, hi) in repack_banks.BANKS.items():
        got = bytes(rom[lo - base:hi + 1 - base])
        exp = bytes(want[lo:hi + 1])
        same = sum(1 for x, y in zip(got, exp) if x == y)
        if got != exp:
            fail(f"банк {name} {lo:04X}..{hi:04X} в .rom не совпал с выходом"
                 f" repack_banks.py: {hi - lo + 1 - same} байт")
            ok = False
        else:
            print(f"  банк {name:7s} {lo:04X}..{hi:04X}  {hi - lo + 1:5d} б"
                  f"  совпал с выходом repack_banks.py байт в байт")
    return 0 if ok else 1


# --- проверка 7: перевод ---------------------------------------------------

ROM_ORG = 0x0100
V06_PLANE_TOP = 0x9FFF      # выше — ВИДИМЫЕ плоскости, туда класть нельзя


def check_i18n(vmem: bytearray) -> int:
    """Русский образ отличается от испанского ровно на выход i18n_ru.py."""
    print("\n=== 7. перевод: зоны текста и шрифта == выход tools/i18n_ru.py")
    sys.path.insert(0, str(ROOT / "tools"))
    import i18n_ru  # noqa: E402
    d = ROOT / "build/adapter"
    roms = {}
    for lang in ("es", "ru"):
        out = d / f"verify-{lang}.rom"
        r = subprocess.run([sys.executable, str(ROOT / "tools/build_v06_rom.py"),
                            "--lang", lang, "-o", str(out)],
                           capture_output=True, text=True)
        if r.returncode != 0 or not out.is_file():
            fail(f"сборка --lang {lang}:\n{r.stdout}\n{r.stderr}")
            return 0
        roms[lang] = bytearray(out.read_bytes())
    es, ru = roms["es"], roms["ru"]

    # (а) испанский образ несёт НЕТРОНУТЫЙ образ игры: те же байты, что
    # собрала проверка 1 (vmem), по всем кускам раскладки.  Единственное
    # законное отличие — ПЕРЕПАКОВКА БАНКОВ этапа E (стадия сборки, не
    # правка эталона), поэтому vmem прогоняется через ту же программу;
    # сама перепаковка сверяется отдельно проверкой 6.
    ref = bytearray(vmem)
    repack_banks.repack(ref, 0, quiet=True)
    bad = 0
    for _k, lo, hi, org, name in V06_LAYOUT:
        n = hi - lo + 1
        o = org - ROM_ORG
        if o + n > len(es):
            continue
        if bytes(es[o:o + n]) != bytes(ref[org:org + n]):
            fail(f"--lang es: кусок {name} {org:04X} разошёлся с проверкой 1")
            bad += 1
    print(f"  --lang es: {len(es)} б, куски раскладки совпали с проверкой 1"
          f" ({len(V06_LAYOUT)} шт., банки — после repack_banks.py)")

    # (б) план перевода — по ИСПАНСКОМУ образу, как это и делает сборка.
    import build_v06_rom  # noqa: E402  (тот же FONT_RU_ADDR, что у сборки)
    plan = i18n_ru.build_plan(bytes(es), build_v06_rom.FONT_RU_ADDR)
    want = bytearray(es)
    i18n_ru.apply(want, plan)
    if bytes(want) != bytes(ru):
        fail("--lang ru: образ не равен «испанский + выход i18n_ru.py»")
    else:
        print(f"  --lang ru: {len(ru)} б == «испанский + выход i18n_ru.py»"
              f" байт в байт")

    # (в) отличий за пределами объявленных зон нет.
    zones = plan.zones()
    covered = set()
    for lo, hi, _n in zones:
        covered.update(range(lo, hi + 1))
    diff = set()
    for i in range(min(len(es), len(ru))):
        if es[i] != ru[i]:
            diff.add(i + ROM_ORG)
    diff.update(range(ROM_ORG + len(es), ROM_ORG + len(ru)))
    extra = sorted(diff - covered)
    if extra:
        fail(f"--lang ru: {len(extra)} изменённых байт вне объявленных зон,"
             f" первый {extra[0]:04X}")
    idle = sorted(covered - diff)
    print(f"  изменено {len(diff)} байт, все внутри {len(zones)} объявленных"
          f" зон ({sum(h - l + 1 for l, h, _ in zones)} б;"
          f" {len(idle)} байт зон совпали с испанскими)")
    for lo, hi, nm in zones:
        if hi > V06_PLANE_TOP:
            fail(f"зона перевода {nm} {lo:04X}..{hi:04X} залезла в ВИДИМЫЕ"
                 f" плоскости (выше {V06_PLANE_TOP:04X})")
        print(f"  зона ru     {lo:04X}..{hi:04X}  {hi - lo + 1:4d} б   {nm}")
    return bad


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true",
                    help="записать build/v06/*.bin для стенда openMSX")
    ap.add_argument("--i18n", action="store_true",
                    help="плюс проверка 7: перевод (собирает оба образа)")
    args = ap.parse_args()
    if not ASM.is_file():
        print(f"нет ассемблера: {ASM}")
        return 2

    print("=== 0. генерация и сборка раскладки Вектора-06Ц")
    D.generate("v06")
    bins = assemble()
    if FAILED:
        return 2

    vmem, vfill = check_geometry(bins)
    omem, ofill = orig_image()
    check_bytes(omem, ofill, vmem, vfill)
    check_no_old(omem, vmem)
    check_byte_addr(omem, vmem)
    check_old_green()
    check_repacked()

    if args.write:
        write_stand(vmem, vfill, omem, ofill)
    if args.i18n:
        check_i18n(vmem)

    if FAILED:
        print(f"\nКРАСНЫЙ: {len(FAILED)} проверок не прошло")
        return 1
    n_ops = len(D.RELOCATED)
    print(f"\nзелёный: раскладка Вектора собрана, переехало {n_ops} адресных"
          f" операндов, от оригинала отличаются ровно их старшие байты,"
          f" чисел на старое место нет")
    print(f"  entry {V06_ENTRY:04X}   sp {V06_STACK_TOP:04X}"
          f"   LOW_TILE_SRC {V06_LOW_TILE:04X}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
