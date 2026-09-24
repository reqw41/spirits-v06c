#!/usr/bin/env python3
"""Мёртвый код игры: что рекомпиляция Z80 -> i8080 НЕ собирает.

  python3 tools/i8080_dead.py            # печать
  python3 tools/i8080_dead.py --write    # плюс tools/i8080_dead.json

КРИТЕРИЙ — статическая недостижимость В УЖЕ ПРОПАТЧЕННОМ ОБРАЗЕ.  Адаптер
экрана (SCR_PATCH: JP_TAB/CALL_TAB/BYTE_TAB) заменяет собой почти весь
резидентный слой MSX, и после этих врезок половина слоя недостижима ни по
одному пути.  Образ берётся готовый (build/port/spirits-port.rom), врезки
накладываются ТОЙ ЖЕ таблицей, что лежит в нём, обход — рекурсивный
дизассемблер tools/disasm_msx.py от полного списка входов: игровой цикл,
всё, что зовут адаптер/связка/читы/заставка, и tools/entries.json.

НЕГАТИВНЫЙ КОНТРОЛЬ: множество адресов, которые ИСПОЛНЯЛ профиль
(tools/prof_pc_v06js.js), обязано целиком лежать внутри достижимых.  Не
лежит — значит список входов неполон, и резать нельзя; программа падает.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools/vendor"))
import disasm_msx as D  # noqa: E402

LO, HI = 0x02A0, 0x294B
MINRUN = 8                       # мельче не режем: не окупается

# Входы, которые зовут НЕ из кода игры.  Каждый — из живого источника:
# src/v06/screen_adapter.asm (jp/call внутрь игры), src/v06/glue.asm,
# src/v06/cheat.asm (CHEAT_GAME в tools/build_port_rom.py), src/v06/title.asm.
EXTRA = {
    0x0489: "игровой цикл (boot -> SCR_INIT -> GAME_ENTRY)",
    0x1A8B: "адаптер: A_ROOMDRAW возвращается в тело D184",
    0x1ABD: "адаптер: D1BD — цвет элемента",
    0x18CA: "адаптер: A_TITSTART/A_ENDSTART зовут 2:CFCA",
    0x1841: "адаптер: A_TITSTART уходит в оригинал титров",
    0x1510: "адаптер: A_ENDSTART уходит в оригинал экрана итога",
    0x1828: "адаптер: A_ICONCOL зовёт CF28",
    0x1B44: "адаптер: SPR_HDR — заголовок записи банка",
    0x1B4C: "адаптер: SPR_BANK_A89C — банк цвета",
    0x1B52: "адаптер: SPR_BANK_VAR — база банка",
    0x1CE2: "адаптер ввода: V_KBD_SCAN возвращается в тело KBD_SCAN",
    0x1CE3: "то же, второй вход",
    0x20A8: "адаптер: HERO_ERASEF (он же вход D7A8)",
    0x0C2C: "читы: GM_EDGE",
    0x0C6F: "читы: GM_LEAVE",
    0x1F19: "читы: GM_TAIL",
    0x1D08: "читы: GM_NB",
    0x1233: "читы: GM_ENERGO",
    0x0F2A: "читы: хвост записи флага смерти",
    0x2478: "связка: MUS_AFTER_WAIT",
    0x255C: "связка: MUS_KEY_EXIT",
    0x0374: "голова: поворот окна (жива)",
    0x03EA: "голова: хвост копира",
    0x03F5: "голова: плеер эффектов PSG",
}


def patched() -> bytearray:
    rom = bytearray(0x10000)
    d = (ROOT / "build/port/spirits-port.rom").read_bytes()
    rom[0x100:0x100 + len(d)] = d
    L = {}
    for m in re.finditer(r"^(\w+)\s+= \$([0-9A-F]{4}) =",
                         (ROOT / "build/adapter/screen_adapter.lst")
                         .read_text(errors="replace"), re.M):
        L[m.group(1)] = int(m.group(2), 16)
    rd16 = lambda a: rom[a] | (rom[a + 1] << 8)
    for i in range((L["JP_END"] - L["JP_TAB"]) // 4):
        a = L["JP_TAB"] + i * 4
        dst, tgt = rd16(a), rd16(a + 2)
        rom[dst:dst + 3] = bytes([0xC3, tgt & 255, tgt >> 8])
    for i in range(4):
        a = L["CALL_TAB"] + i * 5
        dst, tgt, n = rd16(a), rd16(a + 2), rom[a + 4]
        rom[dst:dst + 3] = bytes([0xCD, tgt & 255, tgt >> 8])
        rom[dst + 3:dst + 3 + n] = bytes(n)
    for i in range((L["BYTE_END"] - L["BYTE_TAB"]) // 3):
        a = L["BYTE_TAB"] + i * 3
        rom[rd16(a)] = rom[a + 2]
    return rom


# Байтовые врезки BYTE_TAB, которые ГЛУШАТ процедуру целиком (ret / xor a+ret):
# под них надо оставить столько байт, сколько адаптер пишет, а тело процедуры
# при этом мертво.  Остальные записи BYTE_TAB правят ОПЕРАНД живой команды —
# их трогать нельзя, команда обязана остаться на месте целиком.
STUB_BYTES = {0xC9, 0xAF}

# ЯЧЕЙКИ ВНУТРИ КОДА, которые читает или пишет адаптер.  Это не входы —
# исполнения там нет, — но команда, в которой лежит байт, обязана уцелеть:
# иначе адаптер прочитает чужое.  Источник — src/v06/screen_adapter.asm.
KEEP = {
    0x1AA5: "смещение Y: операнд `add a,0` по 1AA4, пишет 1A8B, читает адаптер",
    0x174D: "адаптер: ld a,(0x174D)",
    0x1A23: "адаптер: ld a,(0x1A23)",
    0x1969: "адаптер: флаг чередования веток",
    0x1737: "адаптер: база образов, операнд `ld hl,nn` по 1736",
    0x1B54: "адаптер: старший байт базы банка, операнд по 1B52",
    0x1C0D: "MASKW: самомодифицируемый операнд `or 0x40` по 1C0C",
    0x1FA9: "первый байт D6A9: 1907 кладёт C9, 1917 возвращает CD — сама"
            " процедура заглушена (1F92/1F9F -> ret), но запись жива",
}


def zones(rom: bytearray, L: dict) -> dict[int, int]:
    """Адрес -> сколько байт адаптер перезаписывает своей врезкой."""
    rd16 = lambda a: rom[a] | (rom[a + 1] << 8)
    z = {}
    for i in range((L["JP_END"] - L["JP_TAB"]) // 4):
        z[rd16(L["JP_TAB"] + i * 4)] = 3
    for i in range(4):
        a = L["CALL_TAB"] + i * 5
        z[rd16(a)] = 3 + rom[a + 4]
    # BYTE_TAB: записи, которые ГЛУШАТ процедуру (C9 / AF C9), тоже зона —
    # тело за заглушкой мертво, и врезке нужен ровно её размер.
    stub = {}
    for i in range((L["BYTE_END"] - L["BYTE_TAB"]) // 3):
        a = L["BYTE_TAB"] + i * 3
        if rom[a + 2] in STUB_BYTES:
            stub[rd16(a)] = rom[a + 2]
    for a in sorted(stub):
        if a - 1 in stub:
            continue
        n = 1
        while a + n in stub:
            n += 1
        z.setdefault(a, n)
    return z


def adapter_labels() -> dict:
    L = {}
    for m in re.finditer(r"^(\w+)\s+= \$([0-9A-F]{4}) =",
                         (ROOT / "build/adapter/screen_adapter.lst")
                         .read_text(errors="replace"), re.M):
        L[m.group(1)] = int(m.group(2), 16)
    return L


def entries() -> list[int]:
    out = list(EXTRA)
    cfg = json.loads((ROOT / "tools/entries.json").read_text())
    for k in ("2", "res", "hi"):
        for x in cfg.get(k, []):
            v = D.v06_addr(int(x, 16) - 0x100)
            if v is not None:
                out.append(v)
    return out


def code_bytes() -> set[int]:
    """Байты, которые дизасм считает КОДОМ (db-островки — данные)."""
    out = set()
    for f in ("spirits2_head", "spirits2_tail", "resident"):
        for ln in (ROOT / f"disasm/msx/v06/{f}.asm").read_text().splitlines():
            i = ln.find(";")
            body, cmt = (ln[:i], ln[i:]) if i >= 0 else (ln, "")
            m = re.match(r"^(?:[\w.$]+:)?\s+(\S+)", body)
            if not m or m.group(1).lower() in ("org", "equ", "db", "dw"):
                continue
            am = re.search(r";\s*([0-9A-F]{4})\s+((?:[0-9A-F]{2} )*[0-9A-F]{2})",
                           cmt)
            if not am:
                continue
            a = int(am.group(1), 16)
            out.update(range(a, a + len(am.group(2).split())))
    return out


def main() -> None:
    mem = patched()
    code = D.disasm_reachable(mem, entries(), LO, HI)
    live = set()
    for a, ins in code.items():
        live.update(range(a, a + ins.length))
    # --- негативный контроль профилем
    pf = ROOT / "build/analysis/prof-z80.json"
    if pf.is_file():
        ex = {int(k) for k in json.loads(pf.read_text())["pc"] if LO <= int(k) < HI}
        miss = sorted(ex - live)
        if miss:
            sys.exit("ИСПОЛНЯЛОСЬ, но недостижимо статически — список входов "
                     "неполон: " + " ".join("%04X" % a for a in miss[:40]))
        print(f"негативный контроль: {len(ex)} исполнявшихся адресов, все внутри"
              f" достижимых")
    # ячейки, которые читает адаптер: уцелеть обязана вся команда
    items = {}
    for f in ("spirits2_head", "spirits2_tail", "resident"):
        for ln in (ROOT / f"disasm/msx/v06/{f}.asm").read_text().splitlines():
            i = ln.find(";")
            am = re.search(r";\s*([0-9A-F]{4})\s+((?:[0-9A-F]{2} )*[0-9A-F]{2})",
                           ln[i:] if i >= 0 else "")
            if am:
                a = int(am.group(1), 16)
                items[a] = len(am.group(2).split())
    for cell in KEEP:
        st = max(a for a in items if a <= cell)
        live.update(range(st, st + items[st]))
    dead = sorted(code_bytes() - live)
    runs, cur = [], None
    for a in dead:
        if cur and a == cur[1] + 1:
            cur[1] = a
        else:
            if cur:
                runs.append(tuple(cur))
            cur = [a, a]
    if cur:
        runs.append(tuple(cur))
    runs = [r for r in runs if r[1] - r[0] + 1 >= MINRUN]
    tot = sum(hi - lo + 1 for lo, hi in runs)
    print(f"достижимо {len(live)} байт из {HI - LO}; НЕ СОБИРАЕМ {tot} байт в "
          f"{len(runs)} кусках")
    for lo, hi in runs:
        print(f"  {lo:04X}..{hi:04X}  {hi - lo + 1:5d}")
    z = zones(mem, adapter_labels())
    print(f"зон под врезки адаптера: {len(z)} "
          + " ".join("%04X:%d" % (a, n) for a, n in sorted(z.items())))
    if "--write" in sys.argv:
        (ROOT / "tools/i8080_dead.json").write_text(json.dumps(
            {"_": "СГЕНЕРИРОВАНО tools/i8080_dead.py --write",
             "cut": [["%04X" % lo, "%04X" % hi] for lo, hi in runs],
             "reserve": {"%04X" % a: n for a, n in sorted(z.items())}}, indent=1))
        print("записано tools/i8080_dead.json")


if __name__ == "__main__":
    main()
