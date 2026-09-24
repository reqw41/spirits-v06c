#!/usr/bin/env python3
"""СЦЕНАРИИ ХОДА БРОДЯЧИХ ОБЪЕКТОВ: перенос блока page 1 в образ порта.

    python3 tools/mk_scripts.py          # отчёт числами
    (как стадия сборки — вызывается из tools/build_port_rom.py)

ЧТО ЭТО.  Доспех, орёл и принцесса ходят по замку не кодом, а БАЙТ-КОДОМ:
`OBJ_ARRAY_CBBF+1/+2` — указатель на сценарий, интерпретатор `CB12..CBBC`.
Сценарии лежат в НИЖНЕЙ копии `SPIRITS.1` в page 1 MSX (`7828..7F9B`,
`SPIRITS.1[0x23C9..]`), которой на Векторе нет, и порт её не переносил —
объекты исполняли чужие данные (docs/known-issues-ballview.md § 1..4).

КАК ПЕРЕНОСИМ.  Байты блока УЖЕ ЛЕЖАТ в образе по `3C51..43C5` (это верхняя
копия того же куска `SPIRITS.1`, содержимое то же).  Часть из них игра
затирает своими буферами, часть — нет (замер § 8.1):

    3C51..3F54  буфер атрибутов + буфер D4EF   -> ПЕРЕНОСИТЬ (772 б)
    3F55..42FF  никем не тронуто                -> остаётся на месте
    4300..4394  зона 3 переменных адаптера      -> ПЕРЕНОСИТЬ (149 б)
    4395..43C4  никем не тронуто                -> остаётся на месте

Указатели внутри сценариев переписываются ЗДЕСЬ, НА СБОРКЕ, поэтому в
рантайме не нужно ни врезок, ни сдвигов, ни таблиц: интерпретатор игры
работает нетронутым.  Там, где кусок разорван, дописывается штатная
команда перехода `00 lo hi` (3 б) — интерпретатор её понимает.

ЧТО ЕЩЁ ПРАВИТСЯ:
  * 11 мест команды `0x0C`: в них лежит АДРЕС ФЛАГА в блоке данных игры
    (`8648 89DE 8EAC 91AE 9D7A A23A`), а блок переехал на -0x1C00;
  * три стартовых указателя в заготовке `OBJ_ARRAY_INIT` (`CBE6`, порт
    `14E6`) и в самом массиве `CBBF` (порт `14BF`);
  * один указатель целится на `0019` — ВНЕ блока.  Так в оригинале (тот же
    байт лежит и в RAM живого картриджа), поэтому он не трогается.

ОДИН КУСОК КОПИРУЕТСЯ В РАНТАЙМЕ.  Зона заставки `4620..4863` в игре
свободна (замер: 0 чтений, 0 записей), но в ОБРАЗЕ там лежит код заставки.
Поэтому первые байты блока остаются в образе на своём месте (`3C51..`) и
переносятся одним `ldir` в `V_START` (src/v06/glue.asm) — там заставка уже
отработала, а игра ещё не рисовала комнату.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD = ROOT / "ref/msx/orig/SPIRITS.1.orig.payload"

# --- блок сценариев в адресах page 1 MSX и его место в SPIRITS.1
MSX_LO, MSX_HI = 0x7828, 0x7F9B          # включительно, 1908 б
P1_BIAS = 0x545F                         # смещение: файл = адрес - 0x545F
PORT_BIAS = 0x3BD7                       # порт = MSX - 0x3BD7 (верхняя копия)
DATA_SHIFT = 0x1C00                      # блок данных игры 8447..BB88 -> -0x1C00
STARTS = (0x7828, 0x782E, 0x782B)        # стартовые указатели трёх объектов

# ЕДИНСТВЕННЫЙ УКАЗАТЕЛЬ, ЦЕЛЯЩИЙ ВНЕ БЛОКА.  Хвост цепочки 7F7D..7F97
# кончается командой `00 19 00` — переходом на 0019.  Так в оригинале: тот
# же байт лежит и в RAM живого картриджа.  На MSX по 0019 — ПЗУ BIOS, и
# интерпретатор просто читает его как байт-код (объект ходит случайно);
# на Векторе по 0019 ноль, а `00 00 00` — переход САМ НА СЕБЯ, то есть
# вечный цикл и зависание игры.  Замер на картридже: за 2500 витков
# указатель сценария НИ РАЗУ не вышел за блок (SCRIPTOUT 0), то есть до
# этой команды оригинал не доходит.  Чтобы у нас она тоже никуда не
# уводила, переход заворачивается на РАЗВИЛКУ 7F78, с которой эта цепочка
# и начинается: объект заново бросает жребий и ходит дальше.
OUT_FIX = {0x0019: 0x7F78}

# --- где байты блока НИКТО не трогает (порт), docs § 8.1
STAY = ((0x3F55, 0x42FF), (0x4395, 0x43C4))

# --- куда класть перенесённое.  Первая запись — «через ldir в V_START»:
# в образе кусок остаётся по STAGE, в игре живёт по адресу региона.
STAGE = 0x3C51                           # где кусок лежит в образе до V_START
REGIONS = (
    (0x4620, 0x4863, "зона заставки (копия в V_START из 3C51)"),
    (0x3AA8, 0x3B2E, "рабочая RAM игры, мертва (замер § 8.5)"),
    (0x3B32, 0x3BB8, "рабочая RAM игры, мертва (замер § 8.5)"),
    (0x496A, 0x498F, "дырка между BKP и MG_ZBUF"),
    (0x49B8, 0x49D7, "дырка перед MG_CARRY"),
    (0x4FE7, 0x4FFF, "хвост дырки модуля читов"),
    (0x43C6, 0x43F6, "дырка перед SPRL (остаток отдан потоку справки)"),
)


def _load() -> bytes:
    return PAYLOAD.read_bytes()


def parse(p1: bytes):
    """Разбор байт-кода от трёх стартовых указателей.

    Возвращает (cmds, ptrs, flags):
      cmds  — {адрес: (длина, вид, адрес следующей по потоку или None)}
      ptrs  — список позиций 2-байтовых указателей ПЕРЕХОДА
      flags — список позиций 2-байтовых адресов флага (команда 0x0C)
    """
    def mem(a: int) -> int:
        return p1[a - P1_BIAS]

    def w(a: int) -> int:
        return mem(a) | (mem(a + 1) << 8)

    cmds: dict[int, tuple[int, str, int | None]] = {}
    ptrs: list[int] = []
    flags: list[int] = []
    outside: set[int] = set()
    queue = list(STARTS)
    while queue:
        a = queue.pop()
        while True:
            if a in cmds:
                break
            if not (MSX_LO <= a <= MSX_HI):
                outside.add(a)
                break
            op = mem(a)
            if op == 0x0F:                       # случайная развилка: две цели
                cmds[a] = (5, "rnd", None)
                ptrs += [a + 1, a + 3]
                queue += [w(a + 1), w(a + 3)]
                break
            if op == 0x0C:                       # адрес флага + две цели
                cmds[a] = (7, "cond", None)
                flags.append(a + 1)
                ptrs += [a + 3, a + 5]
                queue += [w(a + 3), w(a + 5)]
                break
            if op == 0x00:                       # переход
                cmds[a] = (3, "jmp", None)
                ptrs.append(a + 1)
                queue.append(w(a + 1))
                break
            cmds[a] = (2, "move", a + 2)         # ход: команда + длительность
            a += 2
    return cmds, ptrs, flags, outside


def _stay_ok(a: int, n: int) -> bool:
    lo, hi = a - PORT_BIAS, a + n - 1 - PORT_BIAS
    return any(s <= lo and hi <= e for s, e in STAY)


def build(verbose: bool = False):
    p1 = _load()
    cmds, ptrs, flags, outside = parse(p1)
    order = sorted(cmds)

    # --- кто остаётся на месте.  ВАЖНО: последняя команда каждого «остаётся»
    # куска обязана быть ТУПИКОВОЙ (rnd/cond/jmp): у сквозной пришлось бы
    # дописать переход сразу за ней, а там уже затираемая память.
    stay = {a for a in order if _stay_ok(a, cmds[a][0])}
    changed = True
    while changed:
        changed = False
        for a in sorted(stay):
            nxt = cmds[a][2]
            if nxt is None:
                continue
            if nxt not in stay:          # сквозная и последняя в куске
                stay.discard(a)
                changed = True
    move = [a for a in order if a not in stay]

    # --- раскладка перенесённых кусков.
    # ЦЕПОЧКА — подряд идущие СКВОЗНЫЕ команды, падающие одна в другую.  Её
    # можно рвать где угодно, но на каждом разрыве дописывается штатная
    # команда перехода `00 lo hi` (3 б).  Тупиковая команда (rnd/cond/jmp)
    # перехода за собой не требует.
    place: dict[int, int] = {a: a - PORT_BIAS for a in stay}
    moveset = set(move)
    runs = []
    i = 0
    while i < len(move):
        run = [move[i]]
        while True:
            nxt = cmds[run[-1]][2]
            if nxt is None or nxt not in moveset:
                break
            run.append(nxt)
        runs.append((run, cmds[run[-1]][2] is not None))
        i += len(run)

    regions = [[lo, hi, why, lo] for lo, hi, why in REGIONS]
    jumps: list[tuple[int, int]] = []     # (адрес перехода, MSX-адрес цели)
    ri = 0
    for run, tail_jump in runs:
        idx = 0
        while idx < len(run):
            if ri >= len(regions):
                for lo, hi, why, cur in regions:
                    print(f"  {lo:04X}..{hi:04X} ({hi - lo + 1} б): занято {cur - lo},"
                          f" свободно {hi - cur + 1}  {why}")
                sys.exit("сценарии: не хватило места")
            lo, hi, why, cur = regions[ri]
            c, n = cur, 0
            while idx + n < len(run) and c + cmds[run[idx + n]][0] - 1 <= hi:
                c += cmds[run[idx + n]][0]
                n += 1
            need_jump = (idx + n < len(run)) or tail_jump
            if need_jump:
                while n > 0 and c + 2 > hi:
                    n -= 1
                    c -= cmds[run[idx + n]][0]
            if n == 0:
                ri += 1
                continue
            for k in range(n):
                place[run[idx + k]] = cur
                cur += cmds[run[idx + k]][0]
            idx += n
            if idx < len(run):
                jumps.append((cur, run[idx]))     # переход на продолжение
                cur += 3
            elif tail_jump:
                jumps.append((cur, cmds[run[-1]][2]))
                cur += 3
            regions[ri][3] = cur

    # --- собрать байты
    out: dict[int, int] = {}

    def put(addr: int, val: int) -> None:
        """Первичная укладка байта: пересечения кусков — ошибка сборки."""
        if addr in out and out[addr] != val:
            sys.exit(f"сценарии: два значения по {addr:04X}")
        out[addr] = val & 0xFF

    def fix(addr: int, val: int) -> None:
        """Переписать уже уложенный байт (указатель/адрес флага)."""
        if addr not in out:
            sys.exit(f"сценарии: правка по пустому адресу {addr:04X}")
        out[addr] = val & 0xFF

    for a in order:
        n, kind, _ = cmds[a]
        new = place[a]
        for k in range(n):
            put(new + k, p1[a + k - P1_BIAS])
        if kind == "rnd":
            for off in (1, 3):
                t = p1[a + off - P1_BIAS] | (p1[a + off + 1 - P1_BIAS] << 8)
                nt = place.get(OUT_FIX.get(t, t), OUT_FIX.get(t, t))
                fix(new + off, nt & 0xFF)
                fix(new + off + 1, nt >> 8)
        elif kind == "cond":
            fl = p1[a + 1 - P1_BIAS] | (p1[a + 2 - P1_BIAS] << 8)
            nf = fl - DATA_SHIFT
            fix(new + 1, nf & 0xFF)
            fix(new + 2, nf >> 8)
            for off in (3, 5):
                t = p1[a + off - P1_BIAS] | (p1[a + off + 1 - P1_BIAS] << 8)
                nt = place.get(OUT_FIX.get(t, t), OUT_FIX.get(t, t))
                fix(new + off, nt & 0xFF)
                fix(new + off + 1, nt >> 8)
        elif kind == "jmp":
            t = p1[a + 1 - P1_BIAS] | (p1[a + 2 - P1_BIAS] << 8)
            nt = place.get(OUT_FIX.get(t, t), OUT_FIX.get(t, t))
            fix(new + 1, nt & 0xFF)
            fix(new + 2, nt >> 8)
    for addr, tgt in jumps:
        nt = place[tgt]
        put(addr, 0x00)
        put(addr + 1, nt & 0xFF)
        put(addr + 2, nt >> 8)

    # --- САМОПРОВЕРКА: пройти переложенный байт-код и сверить с исходным.
    # Ошибка раскладки должна валить СБОРКУ, а не всплывать в игре.
    for a in order:
        n, kind, nxt = cmds[a]
        new = place[a]
        if out.get(new) != p1[a - P1_BIAS]:
            sys.exit(f"сценарии: код команды {a:04X} не совпал")
        def rdw(x):
            return out[x] | (out[x + 1] << 8)
        if kind == "move":
            if out[new + 1] != p1[a + 1 - P1_BIAS]:
                sys.exit(f"сценарии: длительность {a:04X} не совпала")
        elif kind == "jmp":
            t = OUT_FIX.get(p1[a + 1 - P1_BIAS] | (p1[a + 2 - P1_BIAS] << 8),
                            p1[a + 1 - P1_BIAS] | (p1[a + 2 - P1_BIAS] << 8))
            if rdw(new + 1) != place.get(t, t):
                sys.exit(f"сценарии: цель перехода {a:04X} не совпала")
        elif kind == "rnd":
            for off in (1, 3):
                t0 = p1[a + off - P1_BIAS] | (p1[a + off + 1 - P1_BIAS] << 8)
                t = OUT_FIX.get(t0, t0)
                if rdw(new + off) != place.get(t, t):
                    sys.exit(f"сценарии: цель развилки {a:04X}+{off} не совпала")
        elif kind == "cond":
            fl = p1[a + 1 - P1_BIAS] | (p1[a + 2 - P1_BIAS] << 8)
            if rdw(new + 1) != fl - DATA_SHIFT:
                sys.exit(f"сценарии: адрес флага {a:04X} не совпал")
            for off in (3, 5):
                t0 = p1[a + off - P1_BIAS] | (p1[a + off + 1 - P1_BIAS] << 8)
                t = OUT_FIX.get(t0, t0)
                if rdw(new + off) != place.get(t, t):
                    sys.exit(f"сценарии: цель условия {a:04X}+{off} не совпала")
        if nxt is not None:
            if place[nxt] != new + n:
                # разрыв: сразу за командой обязан стоять переход на нужный адрес
                if out.get(new + n) != 0x00 or rdw(new + n + 1) != place[nxt]:
                    sys.exit(f"сценарии: за {a:04X} нет перехода на продолжение")

    # --- куски байтов подряд
    blobs: list[tuple[int, bytes]] = []
    for a in sorted(out):
        if blobs and a == blobs[-1][0] + len(blobs[-1][1]):
            blobs[-1] = (blobs[-1][0], blobs[-1][1] + bytes([out[a]]))
        else:
            blobs.append((a, bytes([out[a]])))

    # --- кусок, который копируется в рантайме (первый регион)
    copy_lo, copy_hi = REGIONS[0][0], REGIONS[0][1]
    copy = [(a, b) for a, b in blobs if copy_lo <= a <= copy_hi]
    if len(copy) != 1:
        sys.exit(f"сценарии: копируемый кусок разорван ({len(copy)} частей)")
    copy_addr, copy_bytes = copy[0]
    if copy_addr != copy_lo:
        sys.exit(f"сценарии: копируемый кусок начинается не с {copy_lo:04X}")
    # в образе он лежит по STAGE
    blobs = [(STAGE, copy_bytes) if a == copy_addr else (a, b) for a, b in blobs]

    if set(outside) - set(OUT_FIX):
        sys.exit("сценарии: новая цель вне блока: "
                 + " ".join(f"{a:04X}" for a in sorted(set(outside) - set(OUT_FIX))))
    res = {
        "place": {f"{a:04X}": place[a] for a in order},   # MSX -> порт
        "blobs": blobs,
        "copy": (STAGE, copy_lo, len(copy_bytes)),
        "starts": [place[s] for s in STARTS],
        "cmds": len(cmds), "ptrs": len(ptrs), "flags": len(flags),
        "stay": len(stay), "move": len(move),
        "jumps": len(jumps), "outside": sorted(outside),
        "regions": [(lo, hi, why, cur) for lo, hi, why, cur in regions],
    }
    if verbose:
        report(res)
    return res


def report(r) -> None:
    print(f"команд {r['cmds']}, из них остаются на месте {r['stay']},"
          f" переносятся {r['move']}; дописано переходов {r['jumps']}")
    print(f"указателей перехода {r['ptrs']}, адресов флага {r['flags']};"
          f" цели вне блока: {[f'{a:04X}' for a in r['outside']]}")
    print("регионы:")
    for lo, hi, why, cur in r["regions"]:
        print(f"  {lo:04X}..{hi:04X} ({hi - lo + 1:4} б) занято {cur - lo:4} б,"
              f" свободно {hi - cur + 1:4}  — {why}")
    print(f"копия в V_START: {r['copy'][2]} б из {r['copy'][0]:04X} в {r['copy'][1]:04X}")
    print("стартовые указатели объектов:", [f"{a:04X}" for a in r["starts"]])
    tot = sum(len(b) for _, b in r["blobs"])
    print(f"кусков в образ: {len(r['blobs'])}, байт {tot}")
    for a, b in r["blobs"]:
        print(f"   {a:04X}..{a + len(b) - 1:04X}  {len(b)} б")


if __name__ == "__main__":
    build(verbose=True)
