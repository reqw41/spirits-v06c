#!/usr/bin/env python3
"""Сборка i8080 воспроизводима и чиста: гейт перекомпилированного образа.

  python3 tools/verify_i8080.py

ПЯТЬ ПРОВЕРОК (docs/recompilation.md, §3д):

  1. ВОСПРОИЗВОДИМОСТЬ.  Вся цепочка гоняется заново — рекомпиляция
     (tools/recompile_i8080.py), сборка адаптерного образа и полного порта —
     и результат сверяется с лежащими на диске build/adapter/spirits-i8080.rom
     и build/port/spirits-port-i8080.rom БАЙТ В БАЙТ.  Разошлось — значит
     образ собран не из этих исходников.

  2. ЧИСТОТА i8080 по ВСЕМУ образу: tools/check_i8080.py по листингу каждого
     куска, который собирает эта сборка — код игры, рантайм рекомпиляции,
     адаптер экрана, адаптер ввода/звука, связка, читы, заставка.

  3. ЭТАЛОН Z80 НЕ ТРОНУТ.  build/adapter/spirits.rom пересобирается и
     сверяется с собой же; verify_v06 / verify_disasm / verify_orig обязаны
     остаться зелёными (их гоняет verify_v06.py, здесь только код возврата).

  4. ПРИКОЛОЧЕННОЕ ЛЕЖИТ НА МЕСТЕ.  Куски, которые рекомпиляция обязана была
     оставить БАЙТ В БАЙТ на прежних адресах (глифы логотипа, читаемые как
     графика по LOW_TILE_SRC, и таблица reverse на странице 1E00, которую
     адаптер адресует старшим байтом), сверяются с эталонным образом Z80.

  5. ВНЕ ЗАНЯТЫХ КУСКОВ — НИЧЕГО.  Байты 02A0..294A, которых нет в карте
     занятого (build/i8080/labels.json, "used"), обязаны быть нулями, а
     294B..43C5 (банк спрайтов и рабочая RAM) — совпадать с эталоном Z80.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FAIL: list[str] = []


def run(*args) -> tuple[int, str]:
    r = subprocess.run([sys.executable] + [str(a) for a in args],
                       capture_output=True, text=True, cwd=ROOT)
    return r.returncode, r.stdout + r.stderr


def fail(m: str):
    FAIL.append(m)
    print("  FAIL " + m)


def main() -> int:
    print("=== 1. цепочка сборки воспроизводима")
    keep = {}
    for p in ("build/adapter/spirits-i8080.rom", "build/port/spirits-port-i8080.rom",
              "build/adapter/spirits.rom", "build/port/spirits-port.rom"):
        f = ROOT / p
        if f.is_file():
            keep[p] = f.read_bytes()
    for args, what in (
            (["tools/recompile_i8080.py"], "рекомпиляция"),
            (["tools/build_v06_rom.py", "--cpu", "i8080"], "образ адаптера i8080"),
            (["tools/build_port_rom.py", "--cpu", "i8080"], "полный порт i8080"),
            (["tools/build_v06_rom.py"], "образ адаптера Z80"),
            (["tools/build_port_rom.py"], "полный порт Z80")):
        rc, out = run(*args)
        if rc:
            fail(f"{what}: сборка упала\n{out}")
            return 2
    for p, old in keep.items():
        new = (ROOT / p).read_bytes()
        if new != old:
            n = sum(1 for a, b in zip(old, new) if a != b) + abs(len(old) - len(new))
            fail(f"{p}: пересборка дала другой образ ({n} байт)")
        else:
            print(f"  OK  {p}  {len(new)} б, байт в байт")

    print("=== 2. чистота i8080 по всему образу")
    parts = [("код игры + рантайм", "build/i8080/game.bin", "build/i8080/game.lst"),
             ("адаптер экрана", "build/adapter/screen_adapter-i8080.bin",
              "build/adapter/screen_adapter-i8080.lst"),
             ("адаптер ввода и звука", "build/v06/adapter.bin", "build/v06/adapter.lst"),
             ("связка", "build/port/glue.bin", "build/port/glue.lst"),
             ("читы", "build/port/cheat.bin", "build/port/cheat.lst"),
             ("заставка", "build/port/title.bin", "build/port/title.lst")]
    for what, b, l in parts:
        if not (ROOT / b).is_file() or not (ROOT / l).is_file():
            fail(f"{what}: нет {b} или {l}")
            continue
        rc, out = run("tools/check_i8080.py", ROOT / b, ROOT / l)
        tail = [x for x in out.splitlines() if x.strip()][-1]
        if rc:
            fail(f"{what}: {tail}")
        else:
            print(f"  OK  {what:24s} {tail.strip()}")

    print("=== 3. эталон Z80 остался зелёным")
    rc, out = run("tools/verify_v06.py")
    tail = [x for x in out.splitlines() if x.strip()][-2:]
    print("  verify_v06.py: код %d — %s" % (rc, " / ".join(t.strip() for t in tail)))
    if rc:
        fail("verify_v06.py красный")

    print("=== 4. приколоченные куски совпали с эталоном Z80")
    import importlib.util
    spec = importlib.util.spec_from_file_location("rc8", ROOT / "tools/recompile_i8080.py")
    rc8 = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(rc8)
    z = (ROOT / "build/adapter/spirits.rom").read_bytes()
    i = (ROOT / "build/adapter/spirits-i8080.rom").read_bytes()
    for lo, hi in rc8.PIN + rc8.FIXED:
        d = sum(1 for a, b in zip(z[lo - 0x100:hi - 0x100 + 1],
                                  i[lo - 0x100:hi - 0x100 + 1]) if a != b)
        if d:
            fail(f"{lo:04X}..{hi:04X}: {d} байт разошлись с эталоном")
        else:
            print(f"  OK  {lo:04X}..{hi:04X}  {hi - lo + 1:4d} б байт в байт")

    print("=== 5. вне занятых кусков — нули, выше 294B — эталон")
    used = [(int(a, 16), int(b, 16)) for a, b in
            json.loads((ROOT / "build/i8080/labels.json").read_text())["used"]]
    used += rc8.PIN
    nz = [a for a in range(0x02A0, 0x294B)
          if i[a - 0x100] and not any(lo <= a <= hi for lo, hi in used)]
    if nz:
        fail("вне занятых кусков ненулевые байты: "
             + " ".join("%04X" % a for a in nz[:16]))
    else:
        print("  OK  02A0..294A вне занятого — нули")
    d = sum(1 for a, b in zip(z[0x294B - 0x100:0x43C6 - 0x100],
                              i[0x294B - 0x100:0x43C6 - 0x100]) if a != b)
    if d:
        fail(f"294B..43C5: {d} байт разошлись с эталоном Z80")
    else:
        print("  OK  294B..43C5 (банк спрайтов и рабочая RAM) байт в байт")

    print()
    if FAIL:
        print("КРАСНЫЙ: %d проверок не прошли" % len(FAIL))
        return 1
    print("зелёный: образ i8080 воспроизводим, чист по i8080, эталон Z80 цел")
    return 0


if __name__ == "__main__":
    sys.exit(main())
