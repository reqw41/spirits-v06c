"""
z80dis.py — полный декодер Z80 с выводом в СИНТАКСИСЕ sjasm (Zilog).

Отличие от tools/recompiler/disasm.py короля-долины: тот печатает мнемоники
в стиле i8080 (MOV/JMP/ANA) для транслятора, а нам нужен текст, который
ассемблер соберёт ОБРАТНО байт-в-байт. Декодирование алгоритмическое
(x/y/z/p/q по Cristian Dinu «Decoding Z80 opcodes»), поэтому покрыто ВСЁ
пространство опкодов, включая недокументированные (sll, ixh/ixl, ED-дыры).

Ключевое для round-trip: инструкция отдаётся не готовой строкой, а шаблоном
`fmt` со слотом `%s` под операнд-адрес — эмиттер сам решает, подставить туда
метку или число.  Формы, которые ассемблер не воспроизводит байт-в-байт,
эмиттер вырождает в `db` (чёрный список строится прогоном tools/z80dis_probe.py).

    ins = decode(mem, addr)
      ins.length   — длина в байтах
      ins.fmt      — текст с не более чем одним '%s'
      ins.operand  — значение для '%s' (или None)
      ins.opkind   — 'abs16' | 'imm16' | 'imm8' | 'rel8' | 'port' | None
      ins.targets  — статически известные адреса переходов
      ins.flow     — 'cont' | 'jump' | 'cjump' | 'call' | 'ret' | 'dyn' | 'halt'
      ins.form     — ключ формы для чёрного списка (fmt с '%s'->'N')
"""
from __future__ import annotations
from dataclasses import dataclass, field


@dataclass
class Insn:
    length: int
    fmt: str
    operand: int | None = None
    opkind: str | None = None
    targets: list[int] = field(default_factory=list)
    flow: str = 'cont'
    prefix: int | None = None   # 0xDD/0xFD, если инструкция индексная

    @property
    def form(self) -> str:
        return self.fmt.replace('%s', 'N')

    def text(self, operand_str: str | None = None) -> str:
        if '%s' not in self.fmt:
            return self.fmt
        return self.fmt % (operand_str if operand_str is not None else _num(self.operand))


def _num(v: int) -> str:
    return f'0x{v:02X}' if v is not None and v < 256 else f'0x{v:04X}'


def _sdisp(d: int) -> str:
    """Смещение (ix+d): sjasm хочет знак явно."""
    return f'+0x{d:02X}' if d >= 0 else f'-0x{-d:02X}'


# --- таблицы ---------------------------------------------------------------
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '(hl)', 'a']
RP = ['bc', 'de', 'hl', 'sp']
RP2 = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c', 'po', 'pe', 'p', 'm']
ALU = ['add a,', 'adc a,', 'sub ', 'sbc a,', 'and ', 'xor ', 'or ', 'cp ']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'sll', 'srl']
IM = ['0', '0', '1', '2', '0', '0', '1', '2']
BLI = [
    ['ldi', 'cpi', 'ini', 'outi'],
    ['ldd', 'cpd', 'ind', 'outd'],
    ['ldir', 'cpir', 'inir', 'otir'],
    ['lddr', 'cpdr', 'indr', 'otdr'],
]
ROT_A = ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf']

# Опкоды x=0..3, на которые префикс DD/FD ВЛИЯЕТ (участвуют hl/h/l/(hl)).
# Всё остальное после DD/FD — префикс-пустышка, его надо выдать как `db 0xDD`,
# иначе round-trip развалится (ассемблер лишний префикс не воспроизведёт).


def _idx_affected(op: int) -> bool:
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    p, q = y >> 1, y & 1
    if x == 0:
        if z == 1:
            return p == 2 or q == 1        # ld hl,nn / add hl,rp (обе части)
        if z == 2:
            return p == 2                   # ld (nn),hl / ld hl,(nn)
        if z == 3:
            return p == 2                   # inc/dec hl
        if z in (4, 5, 6):
            return y in (4, 5, 6)           # inc/dec/ld для h,l,(hl)
        return False
    if x == 1:
        if op == 0x76:
            return False                        # halt — префикс не влияет
        return y in (4, 5, 6) or z in (4, 5, 6)   # ld r,r' с участием h/l/(hl)
    if x == 2:
        return z in (4, 5, 6)               # alu h/l/(hl)
    # x == 3
    if z == 1:
        return p == 2 or (q == 1 and p in (2, 3))  # push/pop hl, jp (hl), ld sp,hl
    if z == 3:
        return y in (1, 4)                  # префикс CB, ex (sp),hl
    if z == 5:
        return p == 2 or (q == 1 and p in (1, 2, 3))  # push hl / вложенный префикс
    return False


def _r8(i: int, pre: int | None, disp: int | None, plain_hl: bool = False) -> str:
    """Имя 8-битного регистра с учётом индексного префикса.

    plain_hl=True — для `ld r,(ix+d)`/`ld (ix+d),r`, где ВТОРОЙ операнд
    остаётся обычным h/l (правило Z80: подмена h->ixh не действует, если в
    инструкции уже есть (ix+d)).
    """
    if pre is None or plain_hl:
        return R8[i]
    ix = 'ix' if pre == 0xDD else 'iy'
    if i == 4:
        return ix + 'h'
    if i == 5:
        return ix + 'l'
    if i == 6:
        return f'({ix}{_sdisp(disp)})'
    return R8[i]


def _hl(pre: int | None) -> str:
    return 'hl' if pre is None else ('ix' if pre == 0xDD else 'iy')


def _rp(i: int, pre: int | None) -> str:
    return _hl(pre) if i == 2 else RP[i]


def _rp2(i: int, pre: int | None) -> str:
    return _hl(pre) if i == 2 else RP2[i]


def _db(mem: bytes, n: int) -> Insn:
    return Insn(n, 'db ' + ','.join(f'0x{b:02X}' for b in mem[:n]))


def decode(mem: bytes, addr: int) -> Insn:
    """Декодировать одну инструкцию. mem — срез образа с текущего адреса."""
    if not mem:
        return Insn(1, 'db 0x00')
    op = mem[0]

    if op in (0xDD, 0xFD):
        if len(mem) < 2:
            return _db(mem, 1)
        nxt = mem[1]
        if nxt == 0xCB:
            return _decode_ddcb(mem, addr, op)
        if not _idx_affected(nxt):
            # префикс-пустышка: ассемблер её не выразит — отдаём сырым байтом
            return _db(mem, 1)
        ins = _decode_base(mem[1:], addr + 1, pre=op)
        if ins.fmt.startswith('db '):
            return _db(mem, 1)
        ins.length += 1
        ins.prefix = op
        return ins

    if op == 0xCB:
        return _decode_cb(mem, addr)
    if op == 0xED:
        return _decode_ed(mem, addr)
    return _decode_base(mem, addr, pre=None)


def _decode_base(mem: bytes, addr: int, pre: int | None) -> Insn:
    op = mem[0]
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    p, q = y >> 1, y & 1
    # длина индексного смещения
    need_d = pre is not None and (
        (x == 0 and z in (4, 5, 6) and y == 6) or
        (x == 1 and (y == 6 or z == 6)) or
        (x == 2 and z == 6)
    )
    d = None
    if need_d:
        if len(mem) < 2:
            return _db(mem, len(mem))
        d = mem[1] if mem[1] < 128 else mem[1] - 256
    base = 2 if need_d else 1     # смещение до immediate-байтов

    def imm8():
        return mem[base] if len(mem) > base else 0

    def imm16():
        return (mem[1] | (mem[2] << 8)) if len(mem) > 2 else 0

    if x == 0:
        if z == 0:
            if y == 0:
                return Insn(1, 'nop')
            if y == 1:
                return Insn(1, "ex af,af'")
            if y == 2:
                t = (addr + 2 + (mem[1] if mem[1] < 128 else mem[1] - 256)) & 0xFFFF
                return Insn(2, 'djnz %s', t, 'rel8', [t], 'cjump')
            if y == 3:
                t = (addr + 2 + (mem[1] if mem[1] < 128 else mem[1] - 256)) & 0xFFFF
                return Insn(2, 'jr %s', t, 'rel8', [t], 'jump')
            t = (addr + 2 + (mem[1] if mem[1] < 128 else mem[1] - 256)) & 0xFFFF
            return Insn(2, f'jr {CC[y - 4]},%s', t, 'rel8', [t], 'cjump')
        if z == 1:
            if q == 0:
                return Insn(3, f'ld {_rp(p, pre)},%s', imm16(), 'imm16')
            return Insn(1, f'add {_hl(pre)},{_rp(p, pre)}')
        if z == 2:
            if q == 0:
                if p == 0:
                    return Insn(1, 'ld (bc),a')
                if p == 1:
                    return Insn(1, 'ld (de),a')
                if p == 2:
                    return Insn(3, f'ld (%s),{_hl(pre)}', imm16(), 'abs16')
                return Insn(3, 'ld (%s),a', imm16(), 'abs16')
            if p == 0:
                return Insn(1, 'ld a,(bc)')
            if p == 1:
                return Insn(1, 'ld a,(de)')
            if p == 2:
                return Insn(3, f'ld {_hl(pre)},(%s)', imm16(), 'abs16')
            return Insn(3, 'ld a,(%s)', imm16(), 'abs16')
        if z == 3:
            return Insn(1, f'{"inc" if q == 0 else "dec"} {_rp(p, pre)}')
        if z == 4:
            return Insn(base, f'inc {_r8(y, pre, d)}')
        if z == 5:
            return Insn(base, f'dec {_r8(y, pre, d)}')
        if z == 6:
            return Insn(base + 1, f'ld {_r8(y, pre, d)},%s', imm8(), 'imm8')
        return Insn(1, ROT_A[y])

    if x == 1:
        if y == 6 and z == 6:
            return Insn(1, 'halt', flow='halt')
        # правило: если один операнд — (ix+d), второй остаётся обычным h/l
        idx_mem = pre is not None and (y == 6 or z == 6)
        dst = _r8(y, pre, d, plain_hl=idx_mem and y != 6)
        src = _r8(z, pre, d, plain_hl=idx_mem and z != 6)
        return Insn(base, f'ld {dst},{src}')

    if x == 2:
        idx_mem = pre is not None and z == 6
        return Insn(base, f'{ALU[y]}{_r8(z, pre, d, plain_hl=False)}')

    # x == 3
    if z == 0:
        return Insn(1, f'ret {CC[y]}', flow='ret')
    if z == 1:
        if q == 0:
            return Insn(1, f'pop {_rp2(p, pre)}')
        if p == 0:
            return Insn(1, 'ret', flow='ret')
        if p == 1:
            return Insn(1, 'exx')
        if p == 2:
            return Insn(1, f'jp ({_hl(pre)})', flow='dyn')
        return Insn(1, f'ld sp,{_hl(pre)}')
    if z == 2:
        t = imm16()
        return Insn(3, f'jp {CC[y]},%s', t, 'abs16', [t], 'cjump')
    if z == 3:
        if y == 0:
            t = imm16()
            return Insn(3, 'jp %s', t, 'abs16', [t], 'jump')
        if y == 2:
            return Insn(2, 'out (%s),a', mem[1] if len(mem) > 1 else 0, 'port')
        if y == 3:
            return Insn(2, 'in a,(%s)', mem[1] if len(mem) > 1 else 0, 'port')
        if y == 4:
            return Insn(1, f'ex (sp),{_hl(pre)}')
        if y == 5:
            return Insn(1, 'ex de,hl')
        if y == 6:
            return Insn(1, 'di')
        return Insn(1, 'ei')
    if z == 4:
        t = imm16()
        return Insn(3, f'call {CC[y]},%s', t, 'abs16', [t], 'call')
    if z == 5:
        if q == 0:
            return Insn(1, f'push {_rp2(p, pre)}')
        if p == 0:
            t = imm16()
            return Insn(3, 'call %s', t, 'abs16', [t], 'call')
        return _db(mem, 1)      # вложенный префикс — сюда попасть не должны
    if z == 6:
        return Insn(2, f'{ALU[y]}%s', mem[1] if len(mem) > 1 else 0, 'imm8')
    return Insn(1, f'rst 0x{y * 8:02X}', flow='call')


def _decode_cb(mem: bytes, addr: int) -> Insn:
    if len(mem) < 2:
        return _db(mem, len(mem))
    op = mem[1]
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    if x == 0:
        return Insn(2, f'{ROT[y]} {R8[z]}')
    if x == 1:
        return Insn(2, f'bit {y},{R8[z]}')
    if x == 2:
        return Insn(2, f'res {y},{R8[z]}')
    return Insn(2, f'set {y},{R8[z]}')


def _decode_ddcb(mem: bytes, addr: int, pre: int) -> Insn:
    if len(mem) < 4:
        return _db(mem, len(mem))
    d = mem[2] if mem[2] < 128 else mem[2] - 256
    op = mem[3]
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    ix = 'ix' if pre == 0xDD else 'iy'
    tgt = f'({ix}{_sdisp(d)})'
    if z != 6:
        # z!=6: недокументированные формы «операция + копия в регистр» (x!=1) и
        # дубли bit n,(ix+d) (x==1, 8 кодировок на одну инструкцию) — ассемблер
        # выдаёт каноническую z=6, round-trip не держится -> сырые байты
        return _db(mem, 4)
    if x == 0:
        return Insn(4, f'{ROT[y]} {tgt}', prefix=pre)
    if x == 1:
        return Insn(4, f'bit {y},{tgt}', prefix=pre)
    if x == 2:
        return Insn(4, f'res {y},{tgt}', prefix=pre)
    return Insn(4, f'set {y},{tgt}', prefix=pre)


def _decode_ed(mem: bytes, addr: int) -> Insn:
    if len(mem) < 2:
        return _db(mem, len(mem))
    op = mem[1]
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    p, q = y >> 1, y & 1
    if x == 1:
        if z == 0:
            return Insn(2, 'in (c)') if y == 6 else Insn(2, f'in {R8[y]},(c)')
        if z == 1:
            return Insn(2, 'out (c),0') if y == 6 else Insn(2, f'out (c),{R8[y]}')
        if z == 2:
            return Insn(2, f'{"sbc" if q == 0 else "adc"} hl,{RP[p]}')
        if z == 3:
            v = (mem[2] | (mem[3] << 8)) if len(mem) > 3 else 0
            if p == 2:
                # ED 63 / ED 6B — дубли обычных 22 / 2A (ld (nn),hl / ld hl,(nn))
                return _db(mem, 2)
            if q == 0:
                return Insn(4, f'ld (%s),{RP[p]}', v, 'abs16')
            return Insn(4, f'ld {RP[p]},(%s)', v, 'abs16')
        # у neg / retn / im есть недокументированные дубли-кодировки; ассемблер
        # умеет только канонические, остальные отдаём сырыми байтами
        if z == 4:
            return Insn(2, 'neg') if y == 0 else _db(mem, 2)
        if z == 5:
            if y == 0:
                return Insn(2, 'retn', flow='ret')
            if y == 1:
                return Insn(2, 'reti', flow='ret')
            return _db(mem, 2)
        if z == 6:
            return Insn(2, f'im {IM[y]}') if y in (0, 2, 3) else _db(mem, 2)
        # z == 7
        return [
            Insn(2, 'ld i,a'), Insn(2, 'ld r,a'), Insn(2, 'ld a,i'), Insn(2, 'ld a,r'),
            Insn(2, 'rrd'), Insn(2, 'rld'), _db(mem, 2), _db(mem, 2),
        ][y]
    if x == 2 and z <= 3 and y >= 4:
        return Insn(2, BLI[y - 4][z])
    return _db(mem, 2)          # дыры ED — сырые байты
