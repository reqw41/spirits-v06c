#!/usr/bin/env python3
"""Проверить, что собранный код — чистое подмножество i8080.

Два способа вызова:

  python3 tools/check_i8080.py файл.bin файл.lst
      Границы инструкций берутся из листинга zasm: проверяются только строки
      с мнемоникой, строки db/dw/defs (данные, а не код) пропускаются.

  python3 tools/check_i8080.py файл.bin 0xORG [начало конец] ...
      Проход дизассемблером tools/vendor/z80dis.py внутри явно заданных
      диапазонов кода (org — адрес, по которому лежит начало .bin).

Валит прогон на всём, чего у 8080 нет: префиксы DD/FD/ED/CB и одиночные
опкоды 08 (ex af,af'), 10 (djnz), 18/20/28/30/38 (jr), D9 (exx).
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))
import z80dis  # noqa: E402

BAD_PREFIX = {0xDD, 0xFD, 0xED, 0xCB}
BAD_OP = {0x08: "ex af,af'", 0x10: "djnz", 0x18: "jr", 0x20: "jr nz",
          0x28: "jr z", 0x30: "jr nc", 0x38: "jr c", 0xD9: "exx"}

RX_LST = re.compile(r"^([0-9A-F]{4}): ([0-9A-F]+)\s+(?:\[[^\]]*\])?\s*(.*)$")
SKIP = ("db", "dw", "defb", "defw", "defs", "ds", ";", "equ", "org", "#", ".")


def check_op(addr, op, bad):
    if op in BAD_PREFIX:
        bad.append((addr, op, "префикс %02X" % op))
    elif op in BAD_OP:
        bad.append((addr, op, BAD_OP[op]))


def from_listing(lst):
    bad, n = [], 0
    for line in Path(lst).read_text(encoding="utf-8", errors="replace").splitlines():
        m = RX_LST.match(line)
        if not m:
            continue
        by, txt = m.group(2), m.group(3).strip()
        if len(by) % 2 or not txt or txt.lower().startswith(SKIP):
            continue
        check_op(int(m.group(1), 16), int(by[:2], 16), bad)
        n += 1
    return bad, n, "по листингу " + Path(lst).name


def from_ranges(bin_path, org, rest):
    data = Path(bin_path).read_bytes()
    mem = bytearray(0x10000)
    mem[org:org + len(data)] = data
    ranges = ([(int(rest[i], 0), int(rest[i + 1], 0)) for i in range(0, len(rest), 2)]
              if rest else [(org, org + len(data))])
    bad, n = [], 0
    for lo, hi in ranges:
        addr = lo
        while addr < hi:
            ins = z80dis.decode(bytes(mem[addr:addr + 4]), addr)
            check_op(addr, mem[addr], bad)
            addr += ins.length
            n += 1
    return bad, n, " ".join(f"{a:04X}..{b - 1:04X}" for a, b in ranges)


def main() -> None:
    binp = Path(sys.argv[1])
    arg2 = sys.argv[2]
    if arg2.lower().endswith((".lst", ".lis", ".list")):
        bad, n, where = from_listing(arg2)
        if n == 0:
            # Листинг собран без -u (без байтов опкодов): границ инструкций в
            # нём нет, идём по всему .bin от org, взятого из того же листинга.
            txt = Path(arg2).read_text(encoding="utf-8", errors="replace")
            m = re.search(r"^\s*org\s+(0x[0-9A-Fa-f]+|[0-9A-Fa-f]+h?)\s*$",
                          txt, re.M)
            org = int(m.group(1).rstrip("hH"), 16 if m and not
                      m.group(1).startswith("0x") else 0) if m else 0
            bad, n, where = from_ranges(binp, org, [])
            where += "  (листинг без -u: разобран весь .bin от org)"
    else:
        bad, n, where = from_ranges(binp, int(arg2, 0), sys.argv[3:])
    print(f"{binp.name}: {where}, инструкций {n}")
    if bad:
        for a, op, why in bad:
            print(f"  ЧУЖОЕ {a:04X}: {op:02X}  {why}")
        sys.exit(f"НЕ i8080: {len(bad)} инструкций")
    print("  префиксов DD/FD/ED/CB: 0")
    print("  опкодов 08/10/18/20/28/30/38/D9: 0")
    print("  ЧИСТЫЙ i8080")


if __name__ == "__main__":
    main()
