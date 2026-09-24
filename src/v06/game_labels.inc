; СГЕНЕРИРОВАНО tools/build_v06_rom.py --cpu i8080 — правки вносить ТУДА.
; Адрес кода игры Z80 -> адрес в этом образе (docs/recompilation.md, §2).
G_0489:	equ	0x0483
G_062F:	equ	0x06AF
G_063B:	equ	0x06BB
G_0641:	equ	0x06C1
G_10D5:	equ	0x12AD
G_1266:	equ	0x150C
G_126F:	equ	0x1515
G_1334:	equ	0x1611
G_1344:	equ	0x1621
G_1345:	equ	0x1622
G_134D:	equ	0x162A
G_134E:	equ	0x162B
G_150D:	equ	0x1818
G_1510:	equ	0x181B
G_1635:	equ	0x199E
G_1636:	equ	0x199F
G_1694:	equ	0x1A0B
G_1737:	equ	0x1A9C
G_1746:	equ	0x1AAD
G_174D:	equ	0x1AB2
G_1784:	equ	0x1AF1
G_1785:	equ	0x1AF2
G_1807:	equ	0x1B7B
G_1828:	equ	0x1B9F
G_183E:	equ	0x1BCD
G_1841:	equ	0x1BD0
G_1874:	equ	0x1C03
G_1875:	equ	0x1C04
G_18CA:	equ	0x1C60
G_1921:	equ	0x1CB8
G_1969:	equ	0x1CBE
G_19A0:	equ	0x1CD1
G_1A02:	equ	0x1CEF
G_1A03:	equ	0x1CF0
G_1A04:	equ	0x1CF1
G_1A23:	equ	0x1CF6
G_1A50:	equ	0x1D32
G_1A84:	equ	0x1D4C
G_1A8B:	equ	0x1D54
G_1A9F:	equ	0x1D69
G_1AA5:	equ	0x1D6F
G_1ABD:	equ	0x1D70
G_1AD6:	equ	0x1D8C
G_1AD7:	equ	0x1D8D
G_1AE9:	equ	0x1D9F
G_1AEA:	equ	0x1DA0
G_1B02:	equ	0x1DBB
G_1B1D:	equ	0x1DBE
G_1B44:	equ	0x1DC1
G_1B4C:	equ	0x1DC9
G_1B52:	equ	0x1DD0
G_1B54:	equ	0x1DD2
G_1BFD:	equ	0x1F62
G_1C06:	equ	0x1F63
G_1C0D:	equ	0x1F65
G_1C11:	equ	0x1F69
G_1C20:	equ	0x1F6C
G_1C21:	equ	0x1F6D
G_1C28:	equ	0x1F73
G_1C33:	equ	0x1F74
G_1CB4:	equ	0x1F7C
G_1F64:	equ	0x211A
G_1F92:	equ	0x2156
G_1F9F:	equ	0x2157
G_1FC7:	equ	0x215B
G_200D:	equ	0x219C
G_204D:	equ	0x219E
G_2070:	equ	0x21B4
G_20A8:	equ	0x21EC
G_2168:	equ	0x232B
G_23CD:	equ	0x2392
; НЕТ В КАРТЕ (эти адреса рекомпиляция не собирает; обращения к ним обязаны стоять под #if CPU_I8080 == 0):
; G_169C
; G_16A4
; G_16AC
; G_19AE
; G_19F4
; G_1A01
; G_1BE8
