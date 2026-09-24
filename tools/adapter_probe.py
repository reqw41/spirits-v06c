#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Прогон адаптера (src/v06) на модели i8080: проверка поведения и цена в тактах.

Инструмент не «читает код глазами», а ИСПОЛНЯЕТ собранный образ на модели
процессора 8080 с подсчётом тактов и журналом обращений к портам. Отсюда
берутся и числа для бюджета кадра, и доказательство того, что перестановки
битов сделаны правильно.

Модель намеренно знает ТОЛЬКО команды 8080: любой опкод Z80 (префиксы, jr,
djnz, exx) валит прогон исключением — это второй, независимый от
check_i8080.py, сторож чистоты.

  python3 tools/adapter_probe.py build/v06/adapter.bin build/v06/adapter.lst
"""
import re
import sys
from pathlib import Path

# ------------------------------------------------------------------ модель 8080
R = ['b', 'c', 'd', 'e', 'h', 'l', 'm', 'a']


class Trap(Exception):
    pass


class CPU:
    def __init__(self, mem):
        self.m = bytearray(mem)
        self.r = dict(a=0, b=0, c=0, d=0, e=0, h=0, l=0)
        self.sp = 0x4A00
        self.pc = 0
        self.cy = self.z = self.s = self.p = self.ac = 0
        self.t = 0
        self.ports_out = []          # (порт, значение) по порядку
        self.ports_in = {}           # порт -> значение или список значений

    # --- доступ ---------------------------------------------------------
    def g(self, i):
        return self.m[self.hl()] if i == 6 else self.r[R[i]]

    def s_(self, i, v):
        if i == 6:
            self.m[self.hl()] = v & 0xFF
        else:
            self.r[R[i]] = v & 0xFF

    def hl(self):
        return (self.r['h'] << 8) | self.r['l']

    def rp(self, i):
        return [(self.r['b'] << 8) | self.r['c'], (self.r['d'] << 8) | self.r['e'],
                self.hl(), self.sp][i]

    def set_rp(self, i, v):
        v &= 0xFFFF
        if i == 0:
            self.r['b'], self.r['c'] = v >> 8, v & 0xFF
        elif i == 1:
            self.r['d'], self.r['e'] = v >> 8, v & 0xFF
        elif i == 2:
            self.r['h'], self.r['l'] = v >> 8, v & 0xFF
        else:
            self.sp = v

    def szp(self, v):
        self.z = int(v == 0)
        self.s = (v >> 7) & 1
        self.p = int(bin(v).count('1') % 2 == 0)

    def cond(self, i):
        return [not self.z, self.z, not self.cy, self.cy,
                not self.p, self.p, not self.s, self.s][i]

    def push(self, v):
        self.sp = (self.sp - 2) & 0xFFFF
        self.m[self.sp] = v & 0xFF
        self.m[self.sp + 1] = v >> 8

    def pop(self):
        v = self.m[self.sp] | (self.m[self.sp + 1] << 8)
        self.sp = (self.sp + 2) & 0xFFFF
        return v

    def inp(self, port):
        v = self.ports_in.get(port, 0xFF)
        return v.pop(0) if isinstance(v, list) else v

    # --- шаг ------------------------------------------------------------
    def step(self):
        op = self.m[self.pc]
        pc = self.pc
        self.pc += 1

        def d8():
            v = self.m[self.pc]
            self.pc += 1
            return v

        def d16():
            v = self.m[self.pc] | (self.m[self.pc + 1] << 8)
            self.pc += 2
            return v

        if op in (0xCB, 0xDD, 0xED, 0xFD, 0x08, 0x10, 0x18, 0x20,
                  0x28, 0x30, 0x38, 0xD9):
            raise Trap(f'{pc:04X}: опкод {op:02X} — это Z80, а не 8080')

        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        if op == 0x00:
            self.t += 4
        elif x == 1:                                    # MOV
            if op == 0x76:
                raise Trap('hlt')
            self.s_(y, self.g(z))
            self.t += 7 if (y == 6 or z == 6) else 5
        elif x == 0 and z == 6:                         # MVI
            self.s_(y, d8())
            self.t += 10 if y == 6 else 7
        elif x == 0 and z == 1 and y % 2 == 0:          # LXI
            self.set_rp(y >> 1, d16())
            self.t += 10
        elif x == 0 and z == 1:                         # DAD
            v = self.hl() + self.rp(y >> 1)
            self.cy = int(v > 0xFFFF)
            self.set_rp(2, v)
            self.t += 10
        elif x == 0 and z == 3:                         # INX/DCX
            self.set_rp(y >> 1, self.rp(y >> 1) + (1 if y % 2 == 0 else -1))
            self.t += 5
        elif x == 0 and z in (4, 5):                    # INR/DCR
            v = (self.g(y) + (1 if z == 4 else -1)) & 0xFF
            self.s_(y, v)
            self.szp(v)
            self.t += 10 if y == 6 else 5
        elif x == 0 and z == 2:                         # LDAX/STAX/LHLD/SHLD/LDA/STA
            if y == 0:
                self.m[self.rp(0)] = self.r['a']; self.t += 7
            elif y == 1:
                self.r['a'] = self.m[self.rp(0)]; self.t += 7
            elif y == 2:
                self.m[self.rp(1)] = self.r['a']; self.t += 7
            elif y == 3:
                self.r['a'] = self.m[self.rp(1)]; self.t += 7
            elif y == 4:
                a = d16(); self.m[a] = self.r['l']; self.m[a + 1] = self.r['h']
                self.t += 16
            elif y == 5:
                a = d16(); self.r['l'] = self.m[a]; self.r['h'] = self.m[a + 1]
                self.t += 16
            elif y == 6:
                self.m[d16()] = self.r['a']; self.t += 13
            else:
                self.r['a'] = self.m[d16()]; self.t += 13
        elif x == 0 and z == 7:                         # RLC/RRC/RAL/RAR/DAA/CMA/STC/CMC
            a = self.r['a']
            if y == 0:
                self.cy = a >> 7; a = ((a << 1) | self.cy) & 0xFF
            elif y == 1:
                self.cy = a & 1; a = (a >> 1) | (self.cy << 7)
            elif y == 2:
                nc = a >> 7; a = ((a << 1) | self.cy) & 0xFF; self.cy = nc
            elif y == 3:
                nc = a & 1; a = (a >> 1) | (self.cy << 7); self.cy = nc
            elif y == 4:
                raise Trap('daa в адаптере не используется')
            elif y == 5:
                a ^= 0xFF
            elif y == 6:
                self.cy = 1
            else:
                self.cy ^= 1
            self.r['a'] = a
            self.t += 4
        elif x == 2 or (x == 3 and z == 6):             # ALU r / ALU d8
            v = d8() if x == 3 else self.g(z)
            a, op2 = self.r['a'], y
            if op2 == 0:
                r = a + v; self.cy = int(r > 0xFF)
            elif op2 == 1:
                r = a + v + self.cy; self.cy = int(r > 0xFF)
            elif op2 == 2:
                r = a - v; self.cy = int(r < 0)
            elif op2 == 3:
                r = a - v - self.cy; self.cy = int(r < 0)
            elif op2 == 4:
                r = a & v; self.cy = 0
            elif op2 == 5:
                r = a ^ v; self.cy = 0
            elif op2 == 6:
                r = a | v; self.cy = 0
            else:
                r = a - v; self.cy = int(r < 0)
            r &= 0xFF
            self.szp(r)
            if op2 != 7:
                self.r['a'] = r
            self.t += 7 if x == 3 else (7 if z == 6 else 4)
        elif x == 3 and z == 0:                         # Rcc
            if self.cond(y):
                self.pc = self.pop(); self.t += 11
            else:
                self.t += 5
        elif x == 3 and z == 1 and y % 2 == 0:          # POP
            v = self.pop()
            if y >> 1 == 3:
                self.r['a'] = v >> 8
                f = v & 0xFF
                self.cy, self.p, self.ac, self.z, self.s = (
                    f & 1, (f >> 2) & 1, (f >> 4) & 1, (f >> 6) & 1, (f >> 7) & 1)
            else:
                self.set_rp(y >> 1, v)
            self.t += 10
        elif x == 3 and z == 1:                         # RET/PCHL/SPHL
            if y == 1:
                self.pc = self.pop(); self.t += 10
            elif y == 5:
                self.pc = self.hl(); self.t += 5
            elif y == 7:
                self.sp = self.hl(); self.t += 5
            else:
                raise Trap(f'{pc:04X}: {op:02X}')
        elif x == 3 and z == 2:                         # Jcc
            a = d16()
            if self.cond(y):
                self.pc = a
            self.t += 10
        elif x == 3 and z == 3:                         # JMP/OUT/IN/XTHL/XCHG/DI/EI
            if y == 0:
                self.pc = d16(); self.t += 10
            elif y == 2:
                self.ports_out.append((d8(), self.r['a'])); self.t += 10
            elif y == 3:
                self.r['a'] = self.inp(d8()); self.t += 10
            elif y == 4:
                h, l = self.r['h'], self.r['l']
                self.r['l'] = self.m[self.sp]; self.r['h'] = self.m[self.sp + 1]
                self.m[self.sp], self.m[self.sp + 1] = l, h
                self.t += 18
            elif y == 5:
                self.r['h'], self.r['d'] = self.r['d'], self.r['h']
                self.r['l'], self.r['e'] = self.r['e'], self.r['l']
                self.t += 4
            else:
                self.t += 4
        elif x == 3 and z == 4:                         # Ccc
            a = d16()
            if self.cond(y):
                self.push(self.pc); self.pc = a; self.t += 17
            else:
                self.t += 11
        elif x == 3 and z == 5 and y % 2 == 0:          # PUSH
            if y >> 1 == 3:
                f = (self.s << 7) | (self.z << 6) | (self.ac << 4) | \
                    (self.p << 2) | 2 | self.cy
                self.push((self.r['a'] << 8) | f)
            else:
                self.push(self.rp(y >> 1))
            self.t += 11
        elif x == 3 and z == 5 and y == 1:              # CALL
            a = d16(); self.push(self.pc); self.pc = a; self.t += 17
        elif x == 3 and z == 7:                         # RST
            self.push(self.pc); self.pc = y * 8; self.t += 11
        else:
            raise Trap(f'{pc:04X}: нераспознанный опкод {op:02X}')

    def call(self, addr, **regs):
        """Выполнить процедуру до её ret. Возвращает число тактов."""
        self.r.update({k: v for k, v in regs.items() if k in self.r})
        self.sp = 0x4A00
        self.push(0xFFFF)
        self.pc = addr
        self.t = 0
        guard = 0
        while self.pc != 0xFFFF:
            self.step()
            guard += 1
            if guard > 200000:
                raise Trap('зациклилось')
        return self.t


# ------------------------------------------------------------------ обвязка
def symbols(lst: Path) -> dict:
    pat = re.compile(r'^([A-Za-z_][A-Za-z_0-9]*)\s*=\s*\$?([0-9A-Fa-f]{1,4})\b')
    out = {}
    for line in lst.read_text(errors='replace').splitlines():
        m = pat.match(line.strip())
        if m:
            out[m.group(1)] = int(m.group(2), 16)
    return out


FAIL = []


def check(name, got, want):
    ok = got == want
    if not ok:
        FAIL.append(f'{name}: получено {got!r}, ожидалось {want!r}')
    print(f'  [{"ok " if ok else "БЕДА"}] {name}')
    return ok


def main() -> int:
    binf, lstf = Path(sys.argv[1]), Path(sys.argv[2])
    S = symbols(lstf)
    img = binf.read_bytes()
    ORG = S['V_PSG_WR']

    def fresh():
        mem = bytearray(0x10000)
        mem[ORG:ORG + len(img)] = img
        c = CPU(mem)
        c.call(S['V_SND_INIT'])
        c.call(S['V_KBD_INIT'])
        c.ports_out.clear()
        return c

    cost = {}

    # ---------------------------------------------------------- ДЖОЙСТИК
    print('ДЖОЙСТИК: перестановка порта 0x0E -> RDPSG(14)')
    c = fresh()
    ok = True
    for v in range(256):
        c.ports_in[0x0E] = v
        c.call(S['V_JOY_RD'])
        vec = v ^ 0xFF                       # 1 = нажато
        msx = ((vec >> 2) & 1) | (((vec >> 3) & 1) << 1) | (((vec >> 1) & 1) << 2) \
            | ((vec & 1) << 3) | (((vec >> 6) & 1) << 4) | (((vec >> 7) & 1) << 5)
        if c.r['a'] != (msx ^ 0xFF):
            ok = False
            break
    check('все 256 состояний порта 0x0E', ok, True)
    c.ports_in[0x0E] = 0xFF
    cost['V_JOY_RD (один опрос)'] = c.call(S['V_JOY_RD'])
    # регистры целы?
    c.r.update(b=0x11, c=0x22, d=0x33, e=0x44, h=0x55, l=0x66)
    c.call(S['V_JOY_RD'])
    check('bc/de/hl не портятся',
          (c.r['b'], c.r['c'], c.r['d'], c.r['e'], c.r['h'], c.r['l']),
          (0x11, 0x22, 0x33, 0x44, 0x55, 0x66))

    # -------------------------------------------------------- КЛАВИАТУРА
    print('КЛАВИАТУРА: клавиша Вектора -> строка/бит MSX')
    # (имя, ряд Вектора, бит Вектора, строка MSX, бит MSX)
    KEYS = [('1', 2, 1, 0, 1), ('2', 2, 2, 0, 2), ('3', 2, 3, 0, 3),
            ('4', 2, 4, 0, 4), ('5', 2, 5, 0, 5),
            ('ВК (пауза)', 0, 2, 3, 5), ('ПРОБЕЛ', 7, 7, 8, 0),
            ('ВЛЕВО (-> O)', 0, 4, 4, 4), ('ВВЕРХ (-> Q)', 0, 5, 4, 6),
            ('ВПРАВО (-> P)', 0, 6, 4, 5), ('ВНИЗ (-> A)', 0, 7, 2, 6)]
    rowsel = {0xFE: 0, 0xFD: 1, 0xFB: 2, 0xF7: 3, 0xEF: 4,
              0xDF: 5, 0xBF: 6, 0x7F: 7}

    def poll(pressed_vec=(), ss=False, c=None):
        """pressed_vec = список (ряд, бит) нажатых клавиш Вектора.

        c = None — свежая модель; иначе следующий КАДР на той же (нужно
        читам: фронт нажатия виден только по сравнению с прошлым кадром).
        """
        c = fresh() if c is None else c
        mat = [0xFF] * 8
        for r_, b_ in pressed_vec:
            mat[r_] &= ~(1 << b_) & 0xFF
        seq = []

        def hook(port):
            if port == 0x02:
                return mat[seq[-1]] if seq else 0xFF
            if port == 0x01:
                return 0xFF & ~(0x20 if ss else 0)
            return 0xFF
        # порт 0x02 зависит от последнего out в 0x03 — эмулируем через список
        c2 = c
        outs = []
        orig_step = c2.step

        def step():
            op = c2.m[c2.pc]
            if op == 0xD3 and c2.m[c2.pc + 1] == 0x03:
                outs.append(rowsel.get(c2.r['a'], None))
            if op == 0xDB and c2.m[c2.pc + 1] == 0x02:
                seq.append(outs[-1] if outs and outs[-1] is not None else 0)
                c2.ports_in[0x02] = hook(0x02)
                seq.pop()
                seq.append(outs[-1])
            orig_step()
        c2.step = step
        c2.ports_in[0x01] = hook(0x01)
        try:
            t = c2.call(S['V_KBD_POLL'])
        finally:
            # ВЕРНУТЬ ПОДМЕНУ НА МЕСТО. Читам нужен ВТОРОЙ кадр на той же
            # модели (фронт виден только в сравнении с прошлым), а без
            # восстановления обёртки вкладываются друг в друга: старая
            # перебивает ports_in[0x02] прошлой матрицей, и новое нажатие
            # модель не видит. Найдено собственным замером читов.
            c2.step = orig_step
        return c2, t

    ok = True
    detail = []
    for name, vr, vb, mr, mb in KEYS:
        cpu, _ = poll([(vr, vb)])
        row = cpu.m[S['v_msxrow'] + mr]
        good = (row & (1 << mb)) == 0
        # никакие другие строки не должны просесть
        others = all(cpu.m[S['v_msxrow'] + i] == 0xFF
                     for i in range(9) if i != mr)
        same = row | (1 << mb) == 0xFF
        if not (good and others and same):
            ok = False
            detail.append(f'{name}: строка {mr} = {row:02X}')
    check(f'{len(KEYS)} клавиш ложатся ровно в свой бит и ничего лишнего', ok, True)
    if detail:
        print('      ' + '; '.join(detail))
    cpu, _ = poll([], ss=True)
    check('SHIFT (СС, порт 0x01 бит 5) -> строка 6 бит 0',
          cpu.m[S['v_msxrow'] + 6], 0xFE)
    cpu, t_poll = poll([])
    cost['V_KBD_POLL (скан, раз в кадр)'] = t_poll
    # Цена ОТКРЫТОГО окна читов: пока идут титры, скан читает лишний ряд 1
    # (docs/cheats.md § 6).  Меряется на той же модели, отдельным прогоном.
    cw = fresh()
    cw.call(S['V_CHEAT_ARM'])
    _, t_arm = poll([], c=cw)
    cost['V_KBD_POLL (окно читов открыто: титры)'] = t_arm
    check('в покое все 9 строк MSX = FF',
          [cpu.m[S['v_msxrow'] + i] for i in range(9)], [0xFF] * 9)
    check('строки MSX 9..15 = FF (перебор «любая клавиша» их тоже трогает)',
          [cpu.m[S['v_msxrow'] + i] for i in range(9, 16)], [0xFF] * 7)
    # хвост: порядок восстановления
    outs = [p for p, _ in cpu.ports_out]
    check('хвост скана: ППА 0x88 -> порт C -> развёртка -> кайма',
          outs[-4:], [0x00, 0x01, 0x03, 0x02])
    check('в порт 0 ушли ровно 0x8A и 0x88',
          [v for p, v in cpu.ports_out if p == 0x00], [0x8A, 0x88])

    # V_KBD_ROW / V_KBD_SCAN на реальной таблице игры D_1595
    print('КЛАВИАТУРА: KBD_SCAN на таблице игры D_1595 = 80,45,44,26,46')
    D1595 = [(0x80, 'ПРОБЕЛ', 7, 7), (0x45, 'ВПРАВО', 0, 6),
             (0x44, 'ВЛЕВО', 0, 4), (0x26, 'ВНИЗ', 0, 7),
             (0x46, 'ВВЕРХ', 0, 5)]
    ok, worst = True, 0
    for code, nm, vr, vb in D1595:
        cpu, _ = poll([(vr, vb)])
        t = cpu.call(S['V_KBD_SCAN'], c=code)
        worst = max(worst, t)
        if cpu.cy != 1:
            ok = False
        cpu2, _ = poll([])
        cpu2.call(S['V_KBD_SCAN'], c=code)
        if cpu2.cy != 0:
            ok = False
    check('нажата -> CF=1, отпущена -> CF=0 (все пять клавиш)', ok, True)
    cost['V_KBD_SCAN (худший код 0x46)'] = worst
    cpu, _ = poll([])
    cost['V_KBD_ROW (одна строка)'] = cpu.call(S['V_KBD_ROW'], a=0xF0)

    # ---------------------------------------------------------- ЧИТЫ
    # Скан читов живёт в V_KBD_POLL, поэтому проверяется здесь же, на
    # модели 8080, а не только на стенде: стенд показывает, что чит
    # СРАБОТАЛ, а тут видно, что он не трогает ничего чужого.
    print('ЧИТЫ: клавиши, фронты, окно включения (docs/cheats.md)')
    CK = [('G', 4, 7, 0x20), ('8', 3, 0, 0x01), ('9', 3, 1, 0x02),
          ('6', 2, 6, 0x04), ('7', 2, 7, 0x08), ('K', 5, 3, 0x10)]
    ok = True
    for nm, vr, vb, _bit in CK:
        cpu, _ = poll([(vr, vb)])
        if [cpu.m[S['v_msxrow'] + i] for i in range(16)] != [0xFF] * 16:
            ok = False
    check('G/8/9/6/7/K в тень MSX не попадают вовсе', ok, True)

    # без F1+F3 фронты не копятся и god не щёлкает
    cpu = fresh()
    for _ in range(3):
        poll([(4, 7), (3, 0), (2, 6)], c=cpu)
        poll([], c=cpu)
    check('без режима читов: v_cpend и v_god остались 0',
          [cpu.m[S['v_cpend']], cpu.m[S['v_god']], cpu.m[S['v_cheat']]],
          [0, 0, 0])

    # ОКНО ВКЛЮЧЕНИЯ: F1+F3 (ряд 1, биты 3 и 5).  Логика 2026-09-23:
    # V_CHEAT_ARM (её зовёт V_START, дальше идут ТИТРЫ) открывает окно БЕЗ
    # СРОКА — v_carm = V_CHEAT_INF; срок V_CHEAT_WIN окну ставит ПЕРВЫЙ ВИТОК
    # игрового цикла, то есть V_JOY_PACE связки (docs/cheats.md).  Связки в
    # образе адаптера нет, поэтому её единственное действие — запись
    # v_carm := V_CHEAT_WIN — здесь воспроизводится руками; что связка
    # действительно её делает, проверяет tools/cheat_probe_v06js.js.
    INF, WIN = S['V_CHEAT_INF'], S['V_CHEAT_WIN']
    cpu = fresh()
    cpu.call(S['V_CHEAT_ARM'])
    win0 = cpu.m[S['v_carm']]
    poll([(1, 3)], c=cpu)              # одна F1 — мало
    a1 = cpu.m[S['v_cheat']]
    poll([(1, 3), (1, 5)], c=cpu)      # F1 + F3
    check('окно открыто, F1 одна не включает, F1+F3 включают',
          [win0, a1, cpu.m[S['v_cheat']], cpu.m[S['v_carm']]],
          [INF, 0, 1, INF])

    # ТИТРЫ ДЛЯТСЯ СКОЛЬКО УГОДНО: бессрочное окно не истекает само.
    # 600 кадров = 12 с, вчетверо больше прежнего срока.
    cpu1 = fresh()
    cpu1.call(S['V_CHEAT_ARM'])
    for _ in range(600):
        poll([], c=cpu1)
    still = cpu1.m[S['v_carm']]
    poll([(1, 3), (1, 5)], c=cpu1)
    check('600 кадров титров — окно всё ещё открыто, F1+F3 включают',
          [still, cpu1.m[S['v_cheat']]], [INF, 1])

    # ПОСЛЕ НАЧАЛА ПАРТИИ окно живёт ровно V_CHEAT_WIN кадров.
    cpu2 = fresh()
    cpu2.call(S['V_CHEAT_ARM'])
    poll([], c=cpu2)                   # ещё титры
    cpu2.m[S['v_carm']] = WIN          # первый виток игры (V_JOY_PACE связки)
    for _ in range(WIN - 1):
        poll([], c=cpu2)
    left = cpu2.m[S['v_carm']]
    poll([(1, 3), (1, 5)], c=cpu2)     # на последнем кадре окна — ещё успеваем
    check(f'на {WIN}-м кадре игры F1+F3 ещё включают',
          [left, cpu2.m[S['v_cheat']]], [1, 1])

    cpu3 = fresh()
    cpu3.call(S['V_CHEAT_ARM'])
    poll([], c=cpu3)
    cpu3.m[S['v_carm']] = WIN
    for _ in range(WIN):
        poll([], c=cpu3)
    check(f'после {WIN} кадров игры F1+F3 уже не включают',
          [cpu3.m[S['v_carm']], cpu3.m[S['v_cheat']]], [0, 0])
    poll([(1, 3), (1, 5)], c=cpu3)
    check('и на следующих кадрах тоже не включают',
          [cpu3.m[S['v_carm']], cpu3.m[S['v_cheat']]], [0, 0])

    # фронты: удержание даёт ОДИН бит, копилка не чистится сканом
    ok = True
    for nm, vr, vb, bit in CK:
        if nm == 'G':
            continue
        c3 = cpu = fresh()
        c3.m[S['v_cheat']] = 1
        poll([(vr, vb)], c=c3)
        one = c3.m[S['v_cpend']]
        c3.m[S['v_cpend']] = 0
        poll([(vr, vb)], c=c3)         # держим дальше — фронта больше нет
        held = c3.m[S['v_cpend']]
        poll([], c=c3)                 # отпустили
        poll([(vr, vb)], c=c3)         # нажали снова
        again = c3.m[S['v_cpend']]
        if (one, held, again) != (bit, 0, bit):
            ok = False
            print(f'      {nm}: {one:02X} {held:02X} {again:02X}, ждали'
                  f' {bit:02X} 00 {bit:02X}')
    check('8/9/6/7/K: один фронт на нажатие, удержание не повторяет', ok, True)

    # копилка НЕ теряет фронт между витками игрового цикла
    c4 = fresh()
    c4.m[S['v_cheat']] = 1
    poll([(3, 0)], c=c4)               # 8 (вверх) нажата
    poll([], c=c4)                     # отпущена — а витка ещё не было
    poll([], c=c4)
    check('фронт 8 дожил до потребителя через 3 кадра', c4.m[S['v_cpend']], 0x01)

    # G: переключатель god mode по фронту
    c5 = fresh()
    c5.m[S['v_cheat']] = 1
    poll([(4, 7)], c=c5)
    g1 = c5.m[S['v_god']]
    poll([(4, 7)], c=c5)               # держим — второго щелчка нет
    g2 = c5.m[S['v_god']]
    poll([], c=c5)
    poll([(4, 7)], c=c5)               # нажали снова — выключилось
    check('G: вкл по фронту, удержание не мигает, второе нажатие выключает',
          [g1, g2, c5.m[S['v_god']]], [1, 1, 0])
    check('G в копилку направлений не попадает', c5.m[S['v_cpend']], 0)

    # ----------------------------------------------------------- ЗВУК
    print('ЗВУК: пересчёт периода AY -> делитель ВИ53')
    cpu = fresh()

    def ay2vi(p):
        cpu.r['h'], cpu.r['l'] = p >> 8, p & 0xFF
        cpu.call(S['V_AY2VI'])
        return (cpu.r['h'] << 8) | cpu.r['l']

    worst_abs, worst_err, worst_p = 0.0, 0.0, 0
    for p in range(1, 4096):
        div = ay2vi(p)
        worst_abs = max(worst_abs, abs(div - 13.375 * p))
        if div < 64:
            continue              # такие делители код сам глушит (выше 23 кГц)
        f_msx = 1789772.5 / (16 * p)
        err = abs(1497600.0 / div - f_msx) / f_msx
        if err > worst_err:
            worst_err, worst_p = err, p
    # три деления пополам с отбрасыванием остатка дают недобор меньше 2 единиц
    check('формула 13P + P/4 + P/8 + 1: отклонение от точного 13.375P < 1.1',
          worst_abs < 1.1, True)
    check('слышимый диапазон (делитель >= 64): расхождение частоты < 1 %',
          worst_err < 0.01, True)
    print(f'      худшее расхождение {worst_err * 100:.3f} % при периоде {worst_p}'
          f' (это делитель {ay2vi(worst_p)}, то есть {1497600 / ay2vi(worst_p):.0f} Гц)')
    # реальные периоды игры: таблица нот плеера и все шесть дескрипторов эффектов
    real = [0x8B, 0xBC, 0x034A, 0x010F, 0x004A] + list(range(0xBE, 0x0DE6))
    worst_real = max(abs(1497600.0 / ay2vi(p) - 1789772.5 / (16 * p)) /
                     (1789772.5 / (16 * p)) for p in real)
    check('периоды, которые игра реально выдаёт: расхождение < 0.15 %',
          worst_real < 0.0015, True)
    print(f'      худшее на реальных периодах {worst_real * 100:.3f} % '
          f'({worst_real / 0.000578:.1f} цента)')

    def psg(cpu, pairs):
        t = 0
        for reg, val in pairs:
            t += cpu.call(S['V_PSG_WR'], a=reg, c=val)
        return t

    # -- мелодия: ровно то, что делает плеер 2478..24BE для канала A
    print('ЗВУК: нота мелодии (последовательность плеера Вектор 2478..24BE)')
    cpu = fresh()
    psg(cpu, [(7, 0x3F), (8, 0x0F), (9, 0x0E), (10, 0x00)])   # дамп из 256F
    cpu.ports_out.clear()
    # канал A: гасим -> период 0x011D (нота) -> включаем
    psg(cpu, [(7, 0x3F | 0x01), (0, 0x1D), (1, 0x01), (7, 0x3F & 0xFE)])
    outs = cpu.ports_out
    ctrl = [v for p, v in outs if p == 0x08]
    div0 = [v for p, v in outs if p == 0x0B]
    check('канал A -> счётчик 0 (порт 0x0B), управляющее слово 0x36',
          (ctrl, len(div0)), ([0x36], 2))
    want = div0[0] | (div0[1] << 8)
    check('делитель = 13.375 * период (с точностью до отбрасывания остатков)',
          abs(want - 0x11D * 13.375) < 1.1, True)
    print(f'      период 0x011D -> делитель {want} -> '
          f'{1497600 / want:.1f} Гц (на MSX {1789772.5 / (16 * 0x11D):.1f} Гц)')
    # канал C: громкость 0 -> обязан молчать. Третий голос мелодии — заглушка
    # FF FE («пауза, повтор»), нот ему не пишут вовсе, поэтому период остаётся
    # нулём и канал глушится ещё и правилом «делитель < 64».
    cpu.ports_out.clear()
    psg(cpu, [(4, 0x1D), (5, 0x01), (7, 0x3B)])
    check('канал C при громкости 0 молчит (счётчик 2 не трогаем)',
          [v for p, v in cpu.ports_out if p == 0x09], [])

    print('ЗВУК: эффект 64AA (дескриптор игры целиком)')
    cpu = fresh()
    sfx = [(0x00, 0x8B), (0x01, 0x00), (0x08, 0x10), (0x0B, 0xC8),
           (0x0C, 0x00), (0x0D, 0x01), (0x07, 0x3E)]
    t_sfx = psg(cpu, sfx)
    cost['эффект 64AA целиком (7 пар)'] = t_sfx
    div0 = [v for p, v in cpu.ports_out if p == 0x0B]
    check('громкость 0x10 (огибающая) считается максимальной — нота звучит',
          len(div0), 2)
    check('делитель = 13.375 * 0x8B (с точностью до отбрасывания остатков)',
          abs((div0[0] | (div0[1] << 8)) - 0x8B * 13.375) < 2.0, True)
    life = cpu.m[S['v_life']]
    check('срок жизни = полный проход огибающей, округлённый к ближайшему '
          'кадру: (0x00C8+64)/128 = 2 кадра (на AY 28.6 мс = 1.43 кадра)',
          life, 2)
    cpu.ports_out.clear()
    for _ in range(1):
        cpu.call(S['V_SND_TICK'])
    check('1 кадр — нота ещё звучит', cpu.ports_out, [])
    t_tick = cpu.call(S['V_SND_TICK'])
    check('2-й кадр — счётчик остановлен управляющим словом',
          cpu.ports_out, [(0x08, 0x36)])
    cost['V_SND_TICK (кадр без событий)'] = cpu.call(S['V_SND_TICK'])
    cost['V_SND_TICK (кадр, гасящий ноту)'] = t_tick
    cpu.ports_out.clear()
    psg(cpu, [(0x07, 0x3E)])
    check('после истечения срока запись в микшер ноту НЕ поднимает',
          cpu.ports_out, [])
    cpu.ports_out.clear()
    psg(cpu, sfx)
    check('следующий эффект звучит (метка «погашено» снята записью периода)',
          len([v for p, v in cpu.ports_out if p == 0x0B]), 2)

    # СТОРОЖ ДЛИТЕЛЬНОСТИ: срок жизни КАЖДОГО эффекта против огибающей AY.
    #
    # На AY ноту эффекта гасит огибающая: один проход = 256*EP/fclk, на MSX
    # (fclk = 1 789 772.5 Гц) это EP/139.8 кадра 50 Гц.  У ВИ53 огибающей нет,
    # и длину ноты задаёт срок жизни V_LIFE_SET — значит срок ОБЯЗАН сходиться
    # с проходом огибающей, иначе эффект звучит не столько, сколько в
    # оригинале.  Порог 2 кадра — цена округления до целого кадра плюс 9 %
    # от деления на 128 вместо 139.8.
    #
    # Этот сторож ловит правило «четверть прохода» (EP/512 + 2), стоявшее
    # здесь до 2026-09-23: оно давало 64E6 (потеря жизни) 5 кадров вместо
    # 12.82 и 64C8 (выстрел) 7 вместо 18.31.  ЗАМЕРЫ длительности на живых
    # машинах — tools/snd_sfx_msx.tcl и tools/snd_sfx_v06js.js.
    print('ЗВУК: срок жизни ноты против прохода огибающей AY — все дескрипторы')
    AY_FRAME = 1789772.5 / 50.0            # тактов AY в кадре 50 Гц
    SFX_ALL = [
        ('64AA шаг 1',    [(0, 0x8B), (1, 0x00), (8, 0x10), (11, 0xC8),
                           (12, 0x00), (13, 0x01), (7, 0x3E)]),
        ('64B9 шаг 2',    [(0, 0xBC), (1, 0x00), (8, 0x10), (11, 0xC8),
                           (12, 0x00), (13, 0x01), (7, 0x3E)]),
        ('64C8 выстрел',  [(0, 0x4A), (1, 0x03), (8, 0x10), (11, 0x00),
                           (12, 0x0A), (13, 0x01), (7, 0x3E)]),
        ('64E6 потеря',   [(0, 0x4A), (1, 0x00), (8, 0x10), (11, 0x00),
                           (12, 0x07), (13, 0x01), (7, 0x3E)]),
    ]
    for name, pairs in SFX_ALL:
        c = fresh()
        psg(c, pairs)
        ep = dict(pairs)[11] | (dict(pairs)[12] << 8)
        want = 256.0 * ep / AY_FRAME       # проход огибающей в кадрах 50 Гц
        got = c.m[S['v_life']]
        check(f'{name}: срок {got} кадров против прохода огибающей AY '
              f'{want:.2f} кадра (расхождение {got - want:+.2f})',
              abs(got - want) <= 2.0, True)

    print('ЗВУК: эффект 64F5 = команда «замолчать»')
    cpu = fresh()
    psg(cpu, sfx)
    cpu.ports_out.clear()
    psg(cpu, [(0x00, 0x00), (0x01, 0x00), (0x06, 0x00), (0x0B, 0x00),
              (0x0C, 0x00), (0x0D, 0x00), (0x07, 0x36), (0x07, 0x3F)])
    check('все три счётчика остановлены, делители не писались',
          ([v for p, v in cpu.ports_out if p == 0x08],
           [p for p, _ in cpu.ports_out if p in (0x09, 0x0A, 0x0B)]),
          ([0x36], []))

    print('ЗВУК: цена записи в PSG')
    cpu = fresh()
    cost['V_PSG_WR (регистр, кроме микшера)'] = cpu.call(
        S['V_PSG_WR'], a=0x00, c=0x8B)
    cost['V_PSG_WR (микшер, ничего не изменилось)'] = cpu.call(
        S['V_PSG_WR'], a=0x07, c=0x3F)
    cpu = fresh()
    psg(cpu, sfx[:-1])
    cost['V_PSG_WR (микшер, поднимает ноту)'] = cpu.call(
        S['V_PSG_WR'], a=0x07, c=0x3E)

    # ------------------------------------------------------------- итог
    print('\nЦЕНА В ТАКТАХ i8080 (модель, не оценка):')
    for k in sorted(cost):
        print(f'  {k:<44} {cost[k]:5d}')
    print('  для сравнения: оригинальная PSG_WR (out/ld/out/ret) = 35 тактов')

    if FAIL:
        print(f'\nПРОВАЛ, расхождений {len(FAIL)}:')
        for f in FAIL:
            print('  ' + f)
        return 1
    print('\nВСЁ СОШЛОСЬ')
    return 0


if __name__ == '__main__':
    sys.exit(main())
