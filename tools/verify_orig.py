#!/usr/bin/env python3
"""Сборка оригинальной раскладки Spirits и ТРИ доказательства её верности.

  python3 tools/verify_orig.py            # всё
  python3 tools/verify_orig.py --write    # плюс записать ref/msx/orig/

Что собирается. `tools/disasm_msx.py --orig` печатает тот же разбор, что и
канон, но с `org` на 0x100 ниже и с починенными стухшими операндами (в
оригинальной раскладке они уже верны — см. шапку disasm_msx.py). zasm
пересчитывает все 929 адресов сам.

Раскладка оригинала:

    SPIRITS.1  load 9000  entry BB40      SPIRITS.2  load 82A0  entry 82A0
    резидентный слой D000..E04A           банк спрайтов E04B..FAC5

SPIRITS.1 — контейнер: один и тот же файл живёт в трёх раскладках сразу,
поэтому его payload склеивается из трёх сборок (см. compose_1).

ТРИ ПРОВЕРКИ, независимые друг от друга:

  1. Кассета. ref/msx/Spirits-1987-TopoSoft-ES.tsx — оригинал, не сдвинут.
     Его блок B540..E04A покрывает хвост игры и весь резидентный слой.
     В перекрытии собранный образ обязан совпасть с кассетой БАЙТ В БАЙТ.
     Это единственная проверка, не зависящая от наших таблиц.

  2. Аудит стухших. Собранный образ дизассемблируется ЗАНОВО, от своих
     точек входа, и каждый адресный операнд сверяется с кассетой по ТОМУ ЖЕ
     адресу (сдвига нет). Стухших должно быть 0.

  3. Обратная проверка. Из того же исходника собирается версия +0x100
     (`--reshift`): в ней пересчитаны ВСЕ адреса, включая 114, которые
     пропустил прежний инструмент сдвига. Она обязана отличаться от
     ref/msx/*.payload ровно в этих 114 байтах и нигде больше. Адреса
     байтов берутся из STALE/STALE_LIKELY/STALE_PTR — то есть проверяется
     не «примерно столько же», а поимённо.
"""
from __future__ import annotations

import os

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools/vendor"))
import disasm_msx as D  # noqa: E402
from disasm_msx import (SEGMENTS, SYSTEM, LOWMEM, NO_FOLLOW,  # noqa: E402
                        disasm_reachable, load_mem, seg_bytes)
from tsx import TSX, binaries  # noqa: E402

ASM = Path(os.environ["ZASM"]) if "ZASM" in os.environ else (Path.home() / "projects/kvalley-v06c/tools/bin/sjasm")  # zasm 4.5.0

# Оригинальная раскладка рантайма: что где лежит в 64K после загрузки.
RUNTIME = ("2", "res", "hi")
# Диапазон «похоже на адрес внутри образа» в координатах оригинала.
LO, HI = 0x82A0, 0xFAC6
# Плюс поимённые адреса ниже образа (LOWMEM задан в координатах канона).
LOW_ORIG = {a - 0x100 for a in LOWMEM}

FAILED: list[str] = []


def cassette() -> tuple[bytearray, bytearray, int, int]:
    """Эталон: ОДИН кассетный блок, описывающий рантайм-раскладку.

    Лента грузится в несколько приёмов, блоки перекрываются, и склеенный
    64K-образ (tsx.memory) мешает разные куски: по адресу DAEC, например,
    лежат сразу два — из блока B540..E04A и из C2D8..DDCA, и они разные.
    Поэтому берётся ровно тот блок, который покрывает резидентный слой
    (D000..E04A) целиком, — он же покрывает и хвост игры.
    """
    lo, hi = SEGMENTS["res"]["orig"], SEGMENTS["res"]["orig"] + 0x104A
    cand = [b for b in binaries() if b[0] <= lo and b[0] + len(b[3]) > hi]
    if len(cand) != 1:
        raise SystemExit(f"кассета: блоков, покрывающих {lo:04X}..{hi:04X},"
                         f" не один, а {len(cand)}")
    s, _e, _x, body = cand[0]
    mem, filled = bytearray(0x10000), bytearray(0x10000)
    mem[s:s + len(body)] = body
    filled[s:s + len(body)] = b"\1" * len(body)
    return mem, filled, s, s + len(body) - 1


def fail(msg: str):
    FAILED.append(msg)
    print(f"  FAIL {msg}")


def assemble(tag: str) -> dict[str, bytes]:
    """Собрать disasm/msx/<tag>/*.asm zasm'ом. Возвращает {сегмент: байты}."""
    out = {}
    for key, seg in SEGMENTS.items():
        D.set_mode(**D.MODES[tag])
        asm = D.out_path(seg, "out")
        binout = D.out_path(seg, "bin")
        D.set_mode()
        if not asm.is_file():
            fail(f"нет {asm.relative_to(ROOT)} — сначала disasm_msx.py --{tag}")
            continue
        binout.parent.mkdir(parents=True, exist_ok=True)
        if binout.exists():
            binout.unlink()
        r = subprocess.run([str(ASM), "-b", "-l0", str(asm), "-o", str(binout)],
                           cwd=str(asm.parent), capture_output=True, text=True)
        if r.returncode != 0 or not binout.is_file():
            fail(f"zasm {asm.name}:\n{r.stdout}\n{r.stderr}")
            continue
        out[key] = binout.read_bytes()
    return out


def compose_1(bins: dict[str, bytes]) -> bytes:
    """Payload SPIRITS.1 из трёх сборок одного и того же файла.

    Файл лежит по 9000 (сегмент «1»), но исполняется в двух других местах:
    0000..104A едет в D000 (резидентный слой), 10C3..2B3D — в E04B (банк
    спрайтов). Сегмент «1» эти куски печатает как db, то есть байтами
    канона, поэтому поверх кладутся их настоящие сборки. Собственно код
    стадии 1 (2B40..2B80) есть только в сегменте «1» — он остаётся.
    """
    p = bytearray(bins["1"])
    res, hi = SEGMENTS["res"], SEGMENTS["hi"]
    p[0:res["length"]] = bins["res"]
    p[hi["file_off"]:hi["file_off"] + hi["length"]] = bins["hi"]
    return bytes(p)


def runtime_image(p1: bytes, p2: bytes) -> tuple[bytearray, bytearray]:
    """64K-образ оригинала после полной загрузки + маска заполненного."""
    mem, filled = bytearray(0x10000), bytearray(0x10000)

    def put(a: int, b: bytes):
        mem[a:a + len(b)] = b
        filled[a:a + len(b)] = b"\1" * len(b)

    # Порядок важен: SPIRITS.2 кончается ровно на D000, а стадия 2 кладёт
    # туда резидентный слой — последний байт игры затирается (так и в каноне).
    put(SEGMENTS["2"]["orig"], p2)
    put(SEGMENTS["res"]["orig"], p1[:SEGMENTS["res"]["length"]])
    hi = SEGMENTS["hi"]
    put(hi["orig"], p1[hi["file_off"]:hi["file_off"] + hi["length"]])
    return mem, filled


# --- проверка 1: сверка с кассетой ---------------------------------------

def check_cassette(mem: bytearray, filled: bytearray) -> int:
    print("\n=== 1. сверка с кассетным эталоном (оригинал, не сдвинут)")
    orig, ofill, lo, hi = cassette()
    print(f"  кассетный блок {lo:04X}..{hi:04X} ({hi - lo + 1} байт)")
    both = [a for a in range(0x10000) if filled[a] and ofill[a]]
    diff = [a for a in both if mem[a] != orig[a]]
    print(f"  перекрытие: {len(both)} байт "
          f"({min(both):04X}..{max(both):04X})")
    print(f"  расхождений: {len(diff)}")
    for a in diff[:40]:
        print(f"    {a:04X}  собрано {mem[a]:02X}, кассета {orig[a]:02X}")
    if diff:
        fail(f"кассета: {len(diff)} расхождений")
    return len(diff)


# --- проверка 2: аудит стухших в оригинальной раскладке -------------------

def check_stale(mem: bytearray, filled: bytearray) -> int:
    """Дизасм собранного образа заново + сверка каждого операнда с кассетой.

    Проверка независима от таблиц STALE: она смотрит на БАЙТЫ собранного
    образа. NO_FOLLOW здесь пуст — в оригинальной раскладке все цели верны,
    как раз это и проверяется тем, что разбор не разъезжается с каноном.
    """
    print("\n=== 2. аудит стухших операндов в оригинальной раскладке")
    orig, ofill, _lo, _hi = cassette()
    total_stale = total_ops = 0
    for key in ("2", "res"):
        seg = SEGMENTS[key]
        base = seg["orig"]
        end = base + len(seg_bytes(seg))
        entries = [a - 0x100 for a in D.seg_entries(key)]
        code = disasm_reachable(mem, entries, base, end)
        # Разбор собранного образа обязан совпасть с разбором канона по
        # границам инструкций: иначе «совпало» ничего не значит — сверялись
        # бы разные инструкции. Лишние в оригинале допустимы и ожидаемы:
        # в каноне по стухшей цели ходить нельзя (NO_FOLLOW), а здесь она
        # верна, и за ней открывается ещё код.
        cmem, cb, ce = load_mem(seg)
        canon = disasm_reachable(cmem, D.seg_entries(key), cb, ce,
                                 NO_FOLLOW.get(key, set()))
        lost = sorted({pc - 0x100 for pc in canon} - set(code))
        gained = sorted(set(code) - {pc - 0x100 for pc in canon})
        rows = {"ok": 0, "СТУХШИЙ": [], "нет эталона": 0}
        for pc, ins in sorted(code.items()):
            if ins.opkind not in ("abs16", "imm16") or ins.operand is None:
                continue
            v = ins.operand
            if (not (LO <= v < HI) and v not in LOW_ORIG) or v in SYSTEM:
                continue
            total_ops += 1
            if not ofill[pc] or not ofill[pc + ins.length - 1]:
                rows["нет эталона"] += 1
                continue
            if bytes(mem[pc:pc + ins.length]) == bytes(orig[pc:pc + ins.length]):
                rows["ok"] += 1
            else:
                rows["СТУХШИЙ"].append((pc, ins))
        n = len(rows["СТУХШИЙ"])
        total_stale += n
        if lost:
            fail(f"сегмент {key}: {len(lost)} инструкций канона разъехались: "
                 + ", ".join(f"{a:04X}" for a in lost[:20]))
        print(f"  сегмент {key} (org {base:04X}): инструкций {len(code)} "
              f"(канон {len(canon)}, границы совпали, новых по бывшим стухшим"
              f" целям {len(gained)}"
              + (": " + ", ".join(f"{a:04X}" for a in gained) if gained else "")
              + ")")
        print(f"    адресных операндов: {rows['ok'] + n + rows['нет эталона']}")
        print(f"    совпало с кассетой: {rows['ok']}")
        print(f"    РАСХОДИТСЯ (стухший): {n}")
        print(f"    не сверить (нет эталона): {rows['нет эталона']}")
        for pc, ins in rows["СТУХШИЙ"][:40]:
            print(f"      {pc:04X}  {ins.text(None)}")
    print(f"  всего адресных операндов сверено: {total_ops}")
    if total_stale:
        fail(f"стухших в оригинале: {total_stale}")
    return total_stale


# --- проверка 3: обратная сборка +0x100 против канона ----------------------

def expected_fix_bytes() -> dict[str, set[int]]:
    """{payload: {смещение в файле}} — где обратная сборка обязана отличаться.

    Прибавление 0x100 меняет ровно один байт — старший байт операнда. У
    16-битного операнда z80 он всегда последний байт инструкции; у слова в
    данных — второй.
    """
    want: dict[str, set[int]] = {"1": set(), "2": set()}
    for key in ("2", "res"):
        seg = SEGMENTS[key]
        mem, base, end = D.load_mem(seg)
        code = disasm_reachable(mem, D.seg_entries(key), base, end,
                                D.NO_FOLLOW.get(key, set()))
        file_key = "1" if key == "res" else "2"
        off = seg["load"] - seg.get("file_off", 0)
        for pc in list(D.STALE.get(key, {})) + list(D.STALE_LIKELY.get(key, {})):
            want[file_key].add(pc + code[pc].length - 1 - off)
    for key, tbl in D.STALE_PTR.items():
        off = SEGMENTS[key]["load"] - SEGMENTS[key].get("file_off", 0)
        for a in tbl:
            want["2" if key == "2" else "1"].add(a + 1 - off)
    return want


def check_reshift(bins: dict[str, bytes]) -> int:
    print("\n=== 3. обратная проверка: пересборка +0x100 против ref/msx/*.payload")
    got = {"1": compose_1(bins), "2": bins["2"]}
    want = expected_fix_bytes()
    bad = 0
    for fk, name in (("1", "SPIRITS.1"), ("2", "SPIRITS.2")):
        canon = (ROOT / f"ref/msx/{name}.payload").read_bytes()
        cur = got[fk]
        if len(cur) != len(canon):
            fail(f"{name}: размер {len(cur)} != {len(canon)}")
            continue
        diff = {i for i in range(len(canon)) if cur[i] != canon[i]}
        exp = want[fk]
        print(f"  {name}: отличий {len(diff)}, ожидалось {len(exp)}")
        extra, miss = sorted(diff - exp), sorted(exp - diff)
        if extra:
            bad += len(extra)
            fail(f"{name}: {len(extra)} лишних отличий: "
                 + ", ".join(f"+{i:04X}" for i in extra[:20]))
        if miss:
            bad += len(miss)
            fail(f"{name}: {len(miss)} ожидавшихся отличий нет: "
                 + ", ".join(f"+{i:04X}" for i in miss[:20]))
        if not extra and not miss:
            print(f"    совпало поимённо: все {len(diff)} отличий —"
                  " ровно стухшие адреса")
        # Каждое отличие обязано быть ровно +1 в старшем байте.
        odd = [i for i in sorted(diff) if (cur[i] - canon[i]) & 0xFF != 1]
        if odd:
            bad += len(odd)
            fail(f"{name}: отличие не на +0x100: "
                 + ", ".join(f"+{i:04X}" for i in odd[:20]))
    return bad


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true",
                    help="записать ref/msx/orig/*.orig.payload")
    args = ap.parse_args()
    if not ASM.is_file():
        print(f"нет ассемблера: {ASM}")
        return 2
    if not TSX.is_file():
        print(f"нет кассетного эталона: {TSX}")
        return 2

    print("=== 0. сборка оригинальной раскладки")
    ob = assemble("orig")
    if FAILED:
        return 2
    p1, p2 = compose_1(ob), ob["2"]
    print(f"  SPIRITS.1.orig  {len(p1)} байт: резидент D000..E04A,"
          f" банк E04B..{0xE04B + SEGMENTS['hi']['length'] - 1:04X},"
          f" стадия 1 BB40")
    print(f"  SPIRITS.2.orig  {len(p2)} байт: 82A0..{0x82A0 + len(p2) - 1:04X}")
    mem, filled = runtime_image(p1, p2)

    check_cassette(mem, filled)
    check_stale(mem, filled)
    check_reshift(assemble("reshift"))

    if args.write:
        d = ROOT / "ref/msx/orig"
        d.mkdir(parents=True, exist_ok=True)
        (d / "SPIRITS.1.orig.payload").write_bytes(p1)
        (d / "SPIRITS.2.orig.payload").write_bytes(p2)
        print(f"\nзаписано: {d.relative_to(ROOT)}/SPIRITS.{{1,2}}.orig.payload")

    if FAILED:
        print(f"\nКРАСНЫЙ: {len(FAILED)} проверок не прошло")
        return 1
    n_stale = sum(len(s) for s in expected_fix_bytes().values())
    print("\nзелёный: оригинальная раскладка совпала с кассетой,"
          f" стухших 0, обратная сборка отличается ровно в {n_stale} байтах")
    return 0


if __name__ == "__main__":
    sys.exit(main())
