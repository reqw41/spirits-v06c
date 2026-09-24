#!/usr/bin/env python3
"""Round-trip: disasm/msx/*.asm → zasm → байт-в-байт против payload.

  python3 tools/verify_disasm.py

Красный прогон означает, что дизасм разошёлся с каноном: либо мнемоника
собралась в другую кодировку, либо поехали адреса. Молча не чинить —
сначала найти, какая инструкция.
"""
from __future__ import annotations

import os

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from disasm_msx import SEGMENTS, seg_bytes  # noqa: E402

ASM = Path(os.environ["ZASM"]) if "ZASM" in os.environ else (Path.home() / "projects/kvalley-v06c/tools/bin/sjasm")  # zasm 4.5.0

FAILED = False


def fail(msg: str):
    global FAILED
    FAILED = True
    print(f"  FAIL {msg}")


def check(key: str):
    seg = SEGMENTS[key]
    asm = ROOT / seg["out"]
    binout = ROOT / seg["bin"]
    expect = seg_bytes(seg)
    print(f"=== сегмент {key}: {asm.relative_to(ROOT)}")
    if not asm.is_file():
        fail(f"нет {asm} — сначала python3 tools/disasm_msx.py")
        return
    binout.parent.mkdir(parents=True, exist_ok=True)
    if binout.exists():
        binout.unlink()
    r = subprocess.run([str(ASM), "-b", "-l0", str(asm), "-o", str(binout)],
                       cwd=str(asm.parent), capture_output=True, text=True)
    if r.returncode != 0:
        fail(f"zasm:\n{r.stdout}\n{r.stderr}")
        return
    if not binout.is_file():
        fail(f"zasm не создал {binout}")
        return
    got = binout.read_bytes()
    if len(got) != len(expect):
        fail(f"размер {len(got)} != {len(expect)}")
        return
    if got != expect:
        i = next(k for k in range(len(got)) if got[k] != expect[k])
        addr = seg["load"] + i
        fail(f"первое расхождение по смещению {i} (адрес {addr:04X}): "
             f"собрано {got[i]:02X}, канон {expect[i]:02X}\n"
             f"       собрано  {got[max(0,i-4):i+8].hex(' ')}\n"
             f"       канон    {expect[max(0,i-4):i+8].hex(' ')}")
        return
    print(f"  OK  {len(got)} байт, {seg['load']:04X}..{seg['load']+len(got)-1:04X}")


def main():
    if not ASM.is_file():
        print(f"нет ассемблера: {ASM}")
        sys.exit(2)
    for key in sorted(SEGMENTS):
        check(key)
    if FAILED:
        print("\nround-trip КРАСНЫЙ")
        sys.exit(1)
    print("\nround-trip зелёный: оба payload собираются байт-в-байт")


if __name__ == "__main__":
    main()
