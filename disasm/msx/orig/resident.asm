; Spirits (Topo Soft, 1987), MSX — RESIDENT [ОРИГИНАЛЬНАЯ РАСКЛАДКА]
; Восстановлено из ref/msx/SPIRITS.1.payload (канон сдвинут на +0x100),
; проверки — tools/verify_orig.py.
; Диапазон D000..E04A (4171 байт), entry D2F8
; Достижимый код 2746 байт, остальное — db (графика/таблицы).
;
; Абсолютных адресов 282: символом 282, числом 0. Относительных 102.
; Стухших нет: в этой раскладке операнды канона, которые сдвиг пропустил,
; и есть правильные — они выписаны символом по своему настоящему адресу.
; Пояснения к областям данных цитируют адреса КАНОНА +0x100: это разбор,
; а не операнды, и переписывать его автоматически нельзя.
; Разбор — docs/msx-relocation.md, § 7.
;
; Сгенерировано tools/disasm_msx.py --orig — правки вносить туда или в tools/entries.json.
; Наложения (цель внутри предыдущей инструкции): D2F8

; Символы вне этого образа: резидентный слой (он копируется в верхнюю RAM
; из SPIRITS.1 — см. docs/msx-vdp-abi.md), копия в page 1, BIOS и цели,
; попавшие внутрь чужой инструкции. equ байтов не порождает — канон не
; трогается, а при смене org правится в одном месте.
P1_SFX_64AA:	equ	0x64AA
P1_SFX_64B9:	equ	0x64B9
P1_SFX_64C8:	equ	0x64C8
P1_SFX_64D7:	equ	0x64D7
P1_SFX_64E6:	equ	0x64E6
P1_SFX_64F5:	equ	0x64F5
LOW_TILE_SRC:	equ	0x81F4
L_83F5:	equ	0x83F5
ROOM_MAPS:	equ	0x8447
SPR_DATA_A79C:	equ	0xA79C
SPR_DATA_AA76:	equ	0xAA76
HUD_TILES:	equ	0xB756
L_BF34:	equ	0xBF34
GAME_VARS:	equ	0xC1EA
L_C38C:	equ	0xC38C
L_C64A:	equ	0xC64A
L_C698:	equ	0xC698
L_CC5D:	equ	0xCC5D
L_CC9A:	equ	0xCC9A
L_CCA7:	equ	0xCCA7
D_CCC4:	equ	0xCCC4
L_CDCD:	equ	0xCDCD
L_CDF9:	equ	0xCDF9
L_CE36:	equ	0xCE36
SPR_BANK_E04B:	equ	0xE04B
WORK_RAM:	equ	0xF1A8

	org	0xD000

D_D000:			; данные D000..D006 (7 байт)
	db	0x00,0x00,0xAF,0x00,0x00,0x00,0x01	; D000
L_D007:
	ld a,0xC9                     ; D007  3E C9
	ld (L_D6A9),a                 ; D009  32 A9 D6
	call L_BF34                   ; D00C  CD 34 BF
	call L_D49B                   ; D00F  CD 9B D4
	call L_C64A                   ; D012  CD 4A C6
	ld a,0xCD                     ; D015  3E CD
	ld (L_D6A9),a                 ; D017  32 A9 D6
	ret                           ; D01A  C9

D_D01B:			; данные D01B..D020 (6 байт)
	db	0x02,0xD2,0x32,0x11,0xD3,0xC9	; D01B
L_D021:
	ld a,(D_D069)                 ; D021  3A 69 D0
	cpl                           ; D024  2F
	ld (D_D069),a                 ; D025  32 69 D0
	and a                         ; D028  A7
	jr z,L_D06A                   ; D029  28 3F
	ld hl,0x00                    ; D02B  21 00 00
	ld d,0x80                     ; D02E  16 80
L_D030:
	push hl                       ; D030  E5
	ld bc,0x0800                  ; D031  01 00 08
L_D034:
	res 3,h                       ; D034  CB 9C
	set 4,h                       ; D036  CB E4
	call VDP_RD_BYTE              ; D038  CD 20 D3
	and d                         ; D03B  A2
	ld e,a                        ; D03C  5F
	res 4,h                       ; D03D  CB A4
	set 3,h                       ; D03F  CB DC
	call VDP_RD_BYTE              ; D041  CD 20 D3
	xor e                         ; D044  AB
	call VDP_WR_BYTE              ; D045  CD 28 D3
	inc hl                        ; D048  23
	dec bc                        ; D049  0B
	ld a,b                        ; D04A  78
	or c                          ; D04B  B1
	jr nz,L_D034                  ; D04C  20 E6
	ld h,0x0A                     ; D04E  26 0A
L_D050:
	dec h                         ; D050  25
	jr nz,L_D050                  ; D051  20 FD
	nop                           ; D053  00
	nop                           ; D054  00
	pop hl                        ; D055  E1
	rr d                          ; D056  CB 1A
	jr nc,L_D030                  ; D058  30 D6
	ld hl,0x0800                  ; D05A  21 00 08
	call VDP_RD_BYTE              ; D05D  CD 20 D3
	ld bc,0x0800                  ; D060  01 00 08
	ld hl,0x1001                  ; D063  21 01 10
	jp VDP_FILL                   ; D066  C3 11 D3

D_D069:			; данные D069..D069 (1 байт)
	db	0xFF	; D069
L_D06A:
	ld hl,0x0800                  ; D06A  21 00 08
	ld b,0x08                     ; D06D  06 08
L_D06F:
	push bc                       ; D06F  C5
	ld b,0x08                     ; D070  06 08
L_D072:
	dec bc                        ; D072  0B
	ld a,b                        ; D073  78
	or c                          ; D074  B1
	jr nz,L_D072                  ; D075  20 FB
	push hl                       ; D077  E5
L_D078:
	res 3,h                       ; D078  CB 9C
	set 4,h                       ; D07A  CB E4
	call VDP_RD_BYTE              ; D07C  CD 20 D3
	res 4,h                       ; D07F  CB A4
	set 3,h                       ; D081  CB DC
	call VDP_WR_BYTE              ; D083  CD 28 D3
	ld de,0x08                    ; D086  11 08 00
	add hl,de                     ; D089  19
	djnz L_D078                   ; D08A  10 EC
	pop hl                        ; D08C  E1
	inc hl                        ; D08D  23
	pop bc                        ; D08E  C1
	djnz L_D06F                   ; D08F  10 DE
	ret                           ; D091  C9

SCR_ADDR_BIT13:
	ld a,c                        ; D092  79
	and 0xF8                      ; D093  E6 F8
	rrca                          ; D095  0F
	rrca                          ; D096  0F
	rrca                          ; D097  0F
	ld h,a                        ; D098  67
	ld a,b                        ; D099  78
	and 0xF8                      ; D09A  E6 F8
	ld l,a                        ; D09C  6F
	set 5,h                       ; D09D  CB EC
	ret                           ; D09F  C9

L_D0A0:
	ld (L_D0E2+0x1),a             ; D0A0  32 E3 D0
	and 0x7F                      ; D0A3  E6 7F
	ld (ix+0x08),a                ; D0A5  DD 77 08
	push bc                       ; D0A8  C5
	ld b,a                        ; D0A9  47
	add a,0x17                    ; D0AA  C6 17
	ld l,a                        ; D0AC  6F
	ld h,0xF3                     ; D0AD  26 F3
	ld a,(hl)                     ; D0AF  7E
	ld (L_D0DA+0x1),a             ; D0B0  32 DB D0
	call SPR_HDR                  ; D0B3  CD 44 D2
	ld (L_D0DF+0x1),hl            ; D0B6  22 E0 D0
	ld (ix+0x02),b                ; D0B9  DD 70 02
	ld c,a                        ; D0BC  4F
	ld (ix+0x03),c                ; D0BD  DD 71 03
	call L_D381                   ; D0C0  CD 81 D3
	ld a,b                        ; D0C3  78
	neg                           ; D0C4  ED 44
	pop bc                        ; D0C6  C1
	add a,c                       ; D0C7  81
	ld c,a                        ; D0C8  4F
	ld (ix+0x00),c                ; D0C9  DD 71 00
	ld (ix+0x01),b                ; D0CC  DD 70 01
	push bc                       ; D0CF  C5
	call SCR_ADDR_BIT14           ; D0D0  CD 70 D2
	ld (ix+0x04),l                ; D0D3  DD 75 04
	ld (ix+0x05),h                ; D0D6  DD 74 05
	pop bc                        ; D0D9  C1
L_D0DA:
	ld a,0x0C                     ; D0DA  3E 0C
	call L_D340                   ; D0DC  CD 40 D3
L_D0DF:
	ld hl,SPR_BANK_E04B+0x8D7     ; D0DF  21 22 E9
L_D0E2:
	ld a,0x16                     ; D0E2  3E 16
	and 0x80                      ; D0E4  E6 80
	call nz,L_D2CC                ; D0E6  C4 CC D2
	call L_D447                   ; D0E9  CD 47 D4
	ld bc,0x09                    ; D0EC  01 09 00
	add ix,bc                     ; D0EF  DD 09
	ret                           ; D0F1  C9

L_D0F2:
	ld ix,WORK_RAM+0x81           ; D0F2  DD 21 29 F2  ; в каноне +0x100 этот операнд стухший
	ld (ix-0x01),0xFF             ; D0F6  DD 36 FF FF
	ld (ix-0x03),0x00             ; D0FA  DD 36 FD 00
	ld (ix-0x02),0xF8             ; D0FE  DD 36 FE F8
	ld hl,WORK_RAM+0x5D6          ; D102  21 7E F7  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x5D7          ; D105  11 7F F7  ; в каноне +0x100 этот операнд стухший
	ld bc,0x7F                    ; D108  01 7F 00
	ld (hl),0xD1                  ; D10B  36 D1
	ldir                          ; D10D  ED B0
	ld hl,WORK_RAM+0x656          ; D10F  21 FE F7  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x657          ; D112  11 FF F7  ; в каноне +0x100 этот операнд стухший
	ld bc,0x07FF                  ; D115  01 FF 07
	ld (hl),0x00                  ; D118  36 00
	ldir                          ; D11A  ED B0
	jp L_D490                     ; D11C  C3 90 D4

	ld (WORK_RAM+0x5D6),hl        ; D11F  22 7E F7  ; в каноне +0x100 этот операнд стухший
	ret                           ; D122  C9

D_D123:			; данные D123..D123 (1 байт)
	db	0x00	; D123
L_D124:
	ld a,(D_D123)                 ; D124  3A 23 D1
	and a                         ; D127  A7
	jp z,L_D664                   ; D128  CA 64 D6
	ld de,(D_D408+0xE)            ; D12B  ED 5B 16 D4
	ld hl,WORK_RAM+0x656          ; D12F  21 FE F7  ; в каноне +0x100 этот операнд стухший
	and a                         ; D132  A7
	sbc hl,de                     ; D133  ED 52
	srl l                         ; D135  CB 3D
	srl l                         ; D137  CB 3D
	ld b,l                        ; D139  45
	dec de                        ; D13A  1B
	ld hl,WORK_RAM+0x655          ; D13B  21 FD F7  ; в каноне +0x100 этот операнд стухший
	jp L_D655                     ; D13E  C3 55 D6

L_D141:
	push bc                       ; D141  C5
	dec c                         ; D142  0D
	sla c                         ; D143  CB 21
	sla c                         ; D145  CB 21
	sla c                         ; D147  CB 21
L_D149:
	ld b,0x00                     ; D149  06 00
	add hl,bc                     ; D14B  09
	pop bc                        ; D14C  C1
	nop                           ; D14D  00
L_D14E:
	push bc                       ; D14E  C5
	push hl                       ; D14F  E5
L_D150:
	push bc                       ; D150  C5
	call VDP_SET_WADDR            ; D151  CD 06 D3
	ld a,(de)                     ; D154  1A
	ld b,0x08                     ; D155  06 08
L_D157:
	rla                           ; D157  17
	rr c                          ; D158  CB 19
	djnz L_D157                   ; D15A  10 FB
	ld a,c                        ; D15C  79
	out (0x98),a                  ; D15D  D3 98
	inc de                        ; D15F  13
	ld bc,0xFFF8                  ; D160  01 F8 FF
	add hl,bc                     ; D163  09
	pop bc                        ; D164  C1
	dec c                         ; D165  0D
	jr nz,L_D150                  ; D166  20 E8
	pop hl                        ; D168  E1
	jp L_D434                     ; D169  C3 34 D4

L_D16C:
	ld hl,ROOM_MAPS-0x1           ; D16C  21 46 84
	ld b,0x00                     ; D16F  06 00
L_D171:
	and a                         ; D171  A7
	ret z                         ; D172  C8

	dec a                         ; D173  3D
	ld c,0x04                     ; D174  0E 04
	add hl,bc                     ; D176  09
	ld c,(hl)                     ; D177  4E
	inc hl                        ; D178  23
	inc hl                        ; D179  23
	add hl,bc                     ; D17A  09
	add hl,bc                     ; D17B  09
	add hl,bc                     ; D17C  09
	add hl,bc                     ; D17D  09
	jr L_D171                     ; D17E  18 F1

D_D180:			; данные D180..D183 (4 байт)
	db	0xC9,0x00,0x06,0x18	; D180
L_D184:
	xor a                         ; D184  AF
	bit 7,b                       ; D185  CB 78
	jr z,L_D18B                   ; D187  28 02
	ld a,0x60                     ; D189  3E 60
L_D18B:
	ld (L_D1A4+0x1),a             ; D18B  32 A5 D1
	ld a,b                        ; D18E  78
	and 0x7F                      ; D18F  E6 7F
	call L_D16C                   ; D191  CD 6C D1
	ld de,D_D408                  ; D194  11 08 D4
	ld bc,0x04                    ; D197  01 04 00
	ldir                          ; D19A  ED B0
	inc hl                        ; D19C  23
	ld b,(hl)                     ; D19D  46
	inc hl                        ; D19E  23
L_D19F:
	push bc                       ; D19F  C5
	ld a,(hl)                     ; D1A0  7E
	ex af,af'                     ; D1A1  08
	inc hl                        ; D1A2  23
	ld a,(hl)                     ; D1A3  7E
L_D1A4:
	add a,0x00                    ; D1A4  C6 00
	ld c,a                        ; D1A6  4F
	ex af,af'                     ; D1A7  08
	inc hl                        ; D1A8  23
	ld b,(hl)                     ; D1A9  46
	inc hl                        ; D1AA  23
	push bc                       ; D1AB  C5
	push hl                       ; D1AC  E5
	call L_D202                   ; D1AD  CD 02 D2
	pop hl                        ; D1B0  E1
	pop bc                        ; D1B1  C1
	ld a,(hl)                     ; D1B2  7E
	inc hl                        ; D1B3  23
	push hl                       ; D1B4  E5
	call L_D1BD                   ; D1B5  CD BD D1
	pop hl                        ; D1B8  E1
	pop bc                        ; D1B9  C1
	djnz L_D19F                   ; D1BA  10 E3
	ret                           ; D1BC  C9

L_D1BD:
	push af                       ; D1BD  F5
	call SCR_ADDR_BIT13           ; D1BE  CD 92 D0
	pop af                        ; D1C1  F1
L_D1C2:
	push hl                       ; D1C2  E5
	call L_D4B8                   ; D1C3  CD B8 D4
	cp 0x31                       ; D1C6  FE 31
	jr z,L_D1D2                   ; D1C8  28 08
	cp 0x51                       ; D1CA  FE 51
	jr c,L_D1D4                   ; D1CC  38 06
	cp 0x54                       ; D1CE  FE 54
	jr nc,L_D1D4                  ; D1D0  30 02
L_D1D2:
	ld (hl),0x20                  ; D1D2  36 20
L_D1D4:
	ld b,a                        ; D1D4  47
	call SPR_BANK_A89C            ; D1D5  CD 4C D2
	ld b,(hl)                     ; D1D8  46
	inc hl                        ; D1D9  23
	ld c,(hl)                     ; D1DA  4E
	inc hl                        ; D1DB  23
	ex de,hl                      ; D1DC  EB
	pop hl                        ; D1DD  E1
L_D1DE:
	push bc                       ; D1DE  C5
	push hl                       ; D1DF  E5
L_D1E0:
	push bc                       ; D1E0  C5
	call L_D4CF                   ; D1E1  CD CF D4
	ld a,(de)                     ; D1E4  1A
	ld bc,0x08                    ; D1E5  01 08 00
	call VDP_FILL                 ; D1E8  CD 11 D3
	ld a,0x08                     ; D1EB  3E 08
	add a,l                       ; D1ED  85
	ld l,a                        ; D1EE  6F
	inc de                        ; D1EF  13
	pop bc                        ; D1F0  C1
	dec c                         ; D1F1  0D
	jr nz,L_D1E0                  ; D1F2  20 EC
	pop hl                        ; D1F4  E1
	inc h                         ; D1F5  24
	pop bc                        ; D1F6  C1
	djnz L_D1DE                   ; D1F7  10 E5
	ret                           ; D1F9  C9

D_D1FA:			; данные D1FA..D201 (8 байт)
	db	0xE7,0xE1,0x24,0xC1,0x10,0xE0,0xC9,0xC9	; D1FA
L_D202:
	push af                       ; D202  F5
	call SCR_ADDR_BIT14           ; D203  CD 70 D2
	pop af                        ; D206  F1
	push af                       ; D207  F5
	and 0x7F                      ; D208  E6 7F
	push hl                       ; D20A  E5
	ld b,a                        ; D20B  47
	call SPR_BANK_VAR             ; D20C  CD 52 D2
	ld b,(hl)                     ; D20F  46
	inc hl                        ; D210  23
	ld c,(hl)                     ; D211  4E
	inc hl                        ; D212  23
	ex de,hl                      ; D213  EB
	pop hl                        ; D214  E1
	pop af                        ; D215  F1
	and 0x80                      ; D216  E6 80
	jp z,L_D141                   ; D218  CA 41 D1
	in a,(0x99)                   ; D21B  DB 99
VDP_WR_STRIDE8:
	push bc                       ; D21D  C5
	push hl                       ; D21E  E5
L_D21F:
	ld a,l                        ; D21F  7D
	out (0x99),a                  ; D220  D3 99
	ld a,h                        ; D222  7C
	push de                       ; D223  D5
	out (0x99),a                  ; D224  D3 99
	ld de,0x08                    ; D226  11 08 00
	add hl,de                     ; D229  19
	pop de                        ; D22A  D1
	ld a,(de)                     ; D22B  1A
	out (0x98),a                  ; D22C  D3 98
	inc de                        ; D22E  13
	dec c                         ; D22F  0D
	jr nz,L_D21F                  ; D230  20 ED
	pop hl                        ; D232  E1
	ld a,0x07                     ; D233  3E 07
	and l                         ; D235  A5
	cp 0x07                       ; D236  FE 07
	jr nz,L_D23F                  ; D238  20 05
	ld a,l                        ; D23A  7D
	sub 0x08                      ; D23B  D6 08
	ld l,a                        ; D23D  6F
	inc h                         ; D23E  24
L_D23F:
	inc l                         ; D23F  2C
	pop bc                        ; D240  C1
	djnz VDP_WR_STRIDE8           ; D241  10 DA
	ret                           ; D243  C9

SPR_HDR:
	call SPR_BANK_HI              ; D244  CD 58 D2
	ld b,(hl)                     ; D247  46
	inc hl                        ; D248  23
	ld a,(hl)                     ; D249  7E
	inc hl                        ; D24A  23
	ret                           ; D24B  C9

SPR_BANK_A89C:
	ld hl,SPR_DATA_A79C           ; D24C  21 9C A7
	xor a                         ; D24F  AF
	jr L_D25D                     ; D250  18 0B

SPR_BANK_VAR:
	ld hl,SPR_DATA_AA76           ; D252  21 76 AA
	xor a                         ; D255  AF
	jr L_D25D                     ; D256  18 05

SPR_BANK_HI:
	ld hl,SPR_BANK_E04B           ; D258  21 4B E0
	ld a,0x00                     ; D25B  3E 00
L_D25D:
	ld (L_D26A),a                 ; D25D  32 6A D2
	ld a,b                        ; D260  78
	ld d,0x00                     ; D261  16 00
L_D263:
	and a                         ; D263  A7
	ret z                         ; D264  C8

	dec a                         ; D265  3D
	ld e,(hl)                     ; D266  5E
	inc hl                        ; D267  23
	ld b,(hl)                     ; D268  46
	inc hl                        ; D269  23
L_D26A:
	nop                           ; D26A  00
	add hl,de                     ; D26B  19
	djnz L_D26A                   ; D26C  10 FC
	jr L_D263                     ; D26E  18 F3

SCR_ADDR_BIT14:
	ld a,c                        ; D270  79
	and 0xF8                      ; D271  E6 F8
	rrca                          ; D273  0F
	rrca                          ; D274  0F
	rrca                          ; D275  0F
	ld h,a                        ; D276  67
	ld a,b                        ; D277  78
	and 0xF8                      ; D278  E6 F8
	ld l,a                        ; D27A  6F
	ld a,c                        ; D27B  79
	and 0x07                      ; D27C  E6 07
	add a,l                       ; D27E  85
	ld l,a                        ; D27F  6F
	ld a,b                        ; D280  78
	and 0x07                      ; D281  E6 07
	ld b,a                        ; D283  47
	set 6,h                       ; D284  CB F4
	ret                           ; D286  C9

	ld hl,WORK_RAM+0x1A5          ; D287  21 4D F3  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x1A5          ; D28A  11 4D F3  ; в каноне +0x100 этот операнд стухший
	jr L_D295                     ; D28D  18 06

D_D28F:			; данные D28F..D294 (6 байт)
	db	0x21,0x6D,0xF4,0x11,0x6D,0xF4	; D28F
L_D295:
	ld bc,0x0120                  ; D295  01 20 01
	jr L_D2A3                     ; D298  18 09

D_D29A:			; данные D29A..D2A2 (9 байт)
	db	0x21,0x4D,0xF3,0x11,0x4D,0xF3,0x01,0x40,0x02	; D29A
L_D2A3:
	ldir                          ; D2A3  ED B0
	ret                           ; D2A5  C9

	ld e,(ix-0x03)                ; D2A6  DD 5E FD
	ld d,(ix-0x02)                ; D2A9  DD 56 FE
	ld a,(D_D408+0x18)            ; D2AC  3A 20 D4  ; в каноне +0x100 этот операнд стухший
	ld b,a                        ; D2AF  47
	ld a,(D_D408+0x10)            ; D2B0  3A 18 D4  ; в каноне +0x100 этот операнд стухший
	ld c,a                        ; D2B3  4F
L_D2B4:
	push bc                       ; D2B4  C5
	push de                       ; D2B5  D5
	ld b,0x00                     ; D2B6  06 00
	ldir                          ; D2B8  ED B0
	pop de                        ; D2BA  D1
	push hl                       ; D2BB  E5
	ld hl,(D_D408+0x12)           ; D2BC  2A 1A D4  ; в каноне +0x100 этот операнд стухший
	add hl,de                     ; D2BF  19
	ex de,hl                      ; D2C0  EB
	pop hl                        ; D2C1  E1
	pop bc                        ; D2C2  C1
	djnz L_D2B4                   ; D2C3  10 EF
	ld (ix+0x06),e                ; D2C5  DD 73 06
	ld (ix+0x07),d                ; D2C8  DD 72 07
	ret                           ; D2CB  C9

L_D2CC:
	ld b,(ix+0x02)                ; D2CC  DD 46 02
	ld a,(ix+0x03)                ; D2CF  DD 7E 03
	ld (L_D2E3+0x1),a             ; D2D2  32 E4 D2
	ld e,a                        ; D2D5  5F
	rlca                          ; D2D6  07
	ld (L_D2F1+0x1),a             ; D2D7  32 F2 D2
	dec e                         ; D2DA  1D
	ld d,0x00                     ; D2DB  16 00
	add hl,de                     ; D2DD  19
	ld de,WORK_RAM+0x1            ; D2DE  11 A9 F1  ; в каноне +0x100 этот операнд стухший
	ld c,b                        ; D2E1  48
L_D2E2:
	nop                           ; D2E2  00
L_D2E3:
	ld b,0x03                     ; D2E3  06 03
L_D2E5:
	push bc                       ; D2E5  C5
	ld c,(hl)                     ; D2E6  4E
	ld b,0xD5                     ; D2E7  06 D5
	ld a,(bc)                     ; D2E9  0A
	ld (de),a                     ; D2EA  12
	pop bc                        ; D2EB  C1
	inc de                        ; D2EC  13
	dec hl                        ; D2ED  2B
	djnz L_D2E5                   ; D2EE  10 F5
	push bc                       ; D2F0  C5
L_D2F1:
	ld bc,0x06                    ; D2F1  01 06 00
	add hl,bc                     ; D2F4  09
	pop bc                        ; D2F5  C1
	dec c                         ; D2F6  0D
	jr nz,L_D2E2                  ; D2F7  20 E9
	ld hl,WORK_RAM+0x1            ; D2F9  21 A9 F1  ; в каноне +0x100 этот операнд стухший
	ret                           ; D2FC  C9

VDP_SET_RADDR:
	ld a,l                        ; D2FD  7D
	out (0x99),a                  ; D2FE  D3 99
	ld a,h                        ; D300  7C
	and 0x3F                      ; D301  E6 3F
	out (0x99),a                  ; D303  D3 99
	ret                           ; D305  C9

VDP_SET_WADDR:
	ld a,l                        ; D306  7D
	out (0x99),a                  ; D307  D3 99
	ld a,h                        ; D309  7C
	and 0x3F                      ; D30A  E6 3F
L_D30C:
	or 0x40                       ; D30C  F6 40
	out (0x99),a                  ; D30E  D3 99
	ret                           ; D310  C9

VDP_FILL:
	push af                       ; D311  F5
	call VDP_SET_WADDR            ; D312  CD 06 D3
L_D315:
	pop af                        ; D315  F1
	out (0x98),a                  ; D316  D3 98
	push af                       ; D318  F5
	dec bc                        ; D319  0B
	ld a,c                        ; D31A  79
	or b                          ; D31B  B0
	jr nz,L_D315                  ; D31C  20 F7
	pop af                        ; D31E  F1
	ret                           ; D31F  C9

VDP_RD_BYTE:
	call VDP_SET_RADDR            ; D320  CD FD D2
	ex (sp),hl                    ; D323  E3
	ex (sp),hl                    ; D324  E3
	in a,(0x98)                   ; D325  DB 98
	ret                           ; D327  C9

VDP_WR_BYTE:
	push af                       ; D328  F5
	call VDP_SET_WADDR            ; D329  CD 06 D3
	ex (sp),hl                    ; D32C  E3
	ex (sp),hl                    ; D32D  E3
	pop af                        ; D32E  F1
	out (0x98),a                  ; D32F  D3 98
	ret                           ; D331  C9

L_D332:
	ex de,hl                      ; D332  EB
VDP_COPY_TO_VRAM:
	call VDP_SET_WADDR            ; D333  CD 06 D3
L_D336:
	ld a,(de)                     ; D336  1A
	out (0x98),a                  ; D337  D3 98
	inc de                        ; D339  13
	dec bc                        ; D33A  0B
	ld a,c                        ; D33B  79
	or b                          ; D33C  B0
	jr nz,L_D336                  ; D33D  20 F7
	ret                           ; D33F  C9

L_D340:
	ld (L_D372+0x1),a             ; D340  32 73 D3
	push bc                       ; D343  C5
	ld hl,(D_D408+0xE)            ; D344  2A 16 D4
	ld a,(D_D408+0x22)            ; D347  3A 2A D4
	rlca                          ; D34A  07
	rlca                          ; D34B  07
	ld e,a                        ; D34C  5F
	ld d,0x00                     ; D34D  16 00
	and a                         ; D34F  A7
	sbc hl,de                     ; D350  ED 52
	ld (D_D408+0xE),hl            ; D352  22 16 D4
	ld a,(D_D408+0x16)            ; D355  3A 1E D4
	ld b,a                        ; D358  47
	ld a,(D_D408+0x18)            ; D359  3A 20 D4
	ld c,a                        ; D35C  4F
	pop de                        ; D35D  D1
L_D35E:
	push bc                       ; D35E  C5
	push de                       ; D35F  D5
L_D360:
	ld (hl),e                     ; D360  73
	inc hl                        ; D361  23
	ld (hl),d                     ; D362  72
	ld a,0x10                     ; D363  3E 10
	add a,d                       ; D365  82
	ld d,a                        ; D366  57
	inc hl                        ; D367  23
	ld a,(D_D408+0x14)            ; D368  3A 1C D4
	ld (hl),a                     ; D36B  77
	add a,0x04                    ; D36C  C6 04
	ld (D_D408+0x14),a            ; D36E  32 1C D4
	inc hl                        ; D371  23
L_D372:
	ld (hl),0x0C                  ; D372  36 0C
	inc hl                        ; D374  23
	djnz L_D360                   ; D375  10 E9
	pop de                        ; D377  D1
	ld a,0x10                     ; D378  3E 10
	add a,e                       ; D37A  83
	ld e,a                        ; D37B  5F
	pop bc                        ; D37C  C1
	dec c                         ; D37D  0D
	jr nz,L_D35E                  ; D37E  20 DE
	ret                           ; D380  C9

L_D381:
	push bc                       ; D381  C5
	srl c                         ; D382  CB 39
	jr nc,L_D387                  ; D384  30 01
	inc c                         ; D386  0C
L_D387:
	ld a,c                        ; D387  79
	ld (D_D408+0x16),a            ; D388  32 1E D4
	ld a,b                        ; D38B  78
	srl b                         ; D38C  CB 38
	srl b                         ; D38E  CB 38
	srl b                         ; D390  CB 38
	srl b                         ; D392  CB 38
	and 0x0F                      ; D394  E6 0F
	jr z,L_D399                   ; D396  28 01
	inc b                         ; D398  04
L_D399:
	ld a,b                        ; D399  78
	ld (D_D408+0x18),a            ; D39A  32 20 D4
	xor a                         ; D39D  AF
L_D39E:
	add a,c                       ; D39E  81
	djnz L_D39E                   ; D39F  10 FD
	ld (D_D408+0x22),a            ; D3A1  32 2A D4
	ld b,c                        ; D3A4  41
	xor a                         ; D3A5  AF
L_D3A6:
	add a,0x20                    ; D3A6  C6 20
	djnz L_D3A6                   ; D3A8  10 FC
	ld (D_D408+0x12),a            ; D3AA  32 1A D4
	pop bc                        ; D3AD  C1
	ret                           ; D3AE  C9

D_D3AF:			; данные D3AF..D3B3 (5 байт)
	db	0x07,0x32,0x18,0xD4,0xC9	; D3AF
VDP_RD_STRIDE8:
	res 6,h                       ; D3B4  CB B4
L_D3B6:
	push bc                       ; D3B6  C5
	push hl                       ; D3B7  E5
L_D3B8:
	ld a,l                        ; D3B8  7D
	out (0x99),a                  ; D3B9  D3 99
	ld a,h                        ; D3BB  7C
	push de                       ; D3BC  D5
	out (0x99),a                  ; D3BD  D3 99
	ld de,0x08                    ; D3BF  11 08 00
	add hl,de                     ; D3C2  19
	pop de                        ; D3C3  D1
	ex (sp),hl                    ; D3C4  E3
	ex (sp),hl                    ; D3C5  E3
	in a,(0x98)                   ; D3C6  DB 98
	ld (de),a                     ; D3C8  12
	inc de                        ; D3C9  13
	dec c                         ; D3CA  0D
	jr nz,L_D3B8                  ; D3CB  20 EB
	pop hl                        ; D3CD  E1
	ld a,0x07                     ; D3CE  3E 07
	and l                         ; D3D0  A5
	cp 0x07                       ; D3D1  FE 07
	jr nz,L_D3DA                  ; D3D3  20 05
	ld a,l                        ; D3D5  7D
	sub 0x08                      ; D3D6  D6 08
	ld l,a                        ; D3D8  6F
	inc h                         ; D3D9  24
L_D3DA:
	inc l                         ; D3DA  2C
	pop bc                        ; D3DB  C1
	djnz L_D3B6                   ; D3DC  10 D8
	ret                           ; D3DE  C9

KBD_SCAN:
	push bc                       ; D3DF  C5
	ld a,c                        ; D3E0  79
	and 0x07                      ; D3E1  E6 07
	inc a                         ; D3E3  3C
	ld b,a                        ; D3E4  47
	ld a,c                        ; D3E5  79
	and 0xF0                      ; D3E6  E6 F0
	rrca                          ; D3E8  0F
	rrca                          ; D3E9  0F
	rrca                          ; D3EA  0F
	rrca                          ; D3EB  0F
	or 0xF0                       ; D3EC  F6 F0
	out (0xAA),a                  ; D3EE  D3 AA
	nop                           ; D3F0  00
	in a,(0xA9)                   ; D3F1  DB A9
	cpl                           ; D3F3  2F
L_D3F4:
	rrca                          ; D3F4  0F
	djnz L_D3F4                   ; D3F5  10 FD
	pop bc                        ; D3F7  C1
RET_STUB:
	ret                           ; D3F8  C9

D_D3F9:			; данные D3F9..D3FD (5 байт)
	db	0xC9,0x48,0x09,0xD6,0x08	; D3F9
THUNK_CDC5_D00:
	ld d,0x00                     ; D3FE  16 00
	jp D_CCC4+0x1                 ; D400  C3 C5 CC

THUNK_CDC5_D60:
	ld d,0x60                     ; D403  16 60
	jp D_CCC4+0x1                 ; D405  C3 C5 CC

D_D408:			; данные D408..D433 (44 байт)
	db	0x11,0x1B,0x15,0x17,0x11,0x50,0x70,0xB1,0x11,0x50,0x80,0xB1,0xF8,0xD3,0xE2,0xF7	; D408
	db	0x30,0x02,0x20,0x27,0x1C,0x38,0x01,0xC9,0x02,0xA7,0x10,0x50,0x90,0xD0,0x30,0x70	; D418
	db	0xB0,0xE0,0x02,0xD1,0x01,0x05,0x08,0x0D,0x02,0x07,0x11,0x0E	; D428
L_D434:
	ld a,0x07                     ; D434  3E 07
	and l                         ; D436  A5
	cp 0x07                       ; D437  FE 07
	jr nz,L_D440                  ; D439  20 05
	ld a,l                        ; D43B  7D
	sub 0x08                      ; D43C  D6 08
	ld l,a                        ; D43E  6F
	inc h                         ; D43F  24
L_D440:
	inc l                         ; D440  2C
	pop bc                        ; D441  C1
	dec b                         ; D442  05
	jp nz,L_D14E                  ; D443  C2 4E D1
	ret                           ; D446  C9

L_D447:
	ex de,hl                      ; D447  EB
	ld a,(D_D408+0x12)            ; D448  3A 1A D4
	ld c,a                        ; D44B  4F
	sub 0x10                      ; D44C  D6 10
	ld (L_D486+0x1),a             ; D44E  32 87 D4
	ld l,(ix-0x03)                ; D451  DD 6E FD
	ld h,(ix-0x02)                ; D454  DD 66 FE
	push hl                       ; D457  E5
	ld a,(D_D408+0x18)            ; D458  3A 20 D4
	ld b,a                        ; D45B  47
	xor a                         ; D45C  AF
L_D45D:
	add a,c                       ; D45D  81
	djnz L_D45D                   ; D45E  10 FD
	ld c,a                        ; D460  4F
	ld b,0x00                     ; D461  06 00
	add hl,bc                     ; D463  09
	ld (ix+0x06),l                ; D464  DD 75 06
	ld (ix+0x07),h                ; D467  DD 74 07
	pop hl                        ; D46A  E1
	ld c,(ix+0x02)                ; D46B  DD 4E 02
	ld b,(ix+0x03)                ; D46E  DD 46 03
L_D471:
	push bc                       ; D471  C5
	push hl                       ; D472  E5
L_D473:
	ld a,(de)                     ; D473  1A
	ld (hl),a                     ; D474  77
	inc de                        ; D475  13
	push bc                       ; D476  C5
	ld bc,0x10                    ; D477  01 10 00
	add hl,bc                     ; D47A  09
	pop bc                        ; D47B  C1
	djnz L_D473                   ; D47C  10 F5
	pop hl                        ; D47E  E1
	ld a,0x0F                     ; D47F  3E 0F
	and l                         ; D481  A5
	cp 0x0F                       ; D482  FE 0F
	jr nz,L_D48A                  ; D484  20 04
L_D486:
	ld bc,0x10                    ; D486  01 10 00
	add hl,bc                     ; D489  09
L_D48A:
	inc hl                        ; D48A  23
	pop bc                        ; D48B  C1
	dec c                         ; D48C  0D
	jr nz,L_D471                  ; D48D  20 E2
	ret                           ; D48F  C9

L_D490:
	ld hl,WORK_RAM+0x656          ; D490  21 FE F7  ; в каноне +0x100 этот операнд стухший
	ld (D_D408+0xE),hl            ; D493  22 16 D4
	xor a                         ; D496  AF
	ld (D_D408+0x14),a            ; D497  32 1C D4
	ret                           ; D49A  C9

L_D49B:
	ld hl,WORK_RAM+0x1A5          ; D49B  21 4D F3  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x1A6          ; D49E  11 4E F3  ; в каноне +0x100 этот операнд стухший
	ld bc,0x0120                  ; D4A1  01 20 01
	ld (hl),0x00                  ; D4A4  36 00
	ldir                          ; D4A6  ED B0
	ret                           ; D4A8  C9

L_D4A9:
	ld hl,WORK_RAM+0x2C5          ; D4A9  21 6D F4  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x2C6          ; D4AC  11 6E F4  ; в каноне +0x100 этот операнд стухший
	ld bc,0x0120                  ; D4AF  01 20 01
	ld (hl),0x00                  ; D4B2  36 00
	ldir                          ; D4B4  ED B0
	ret                           ; D4B6  C9

D_D4B7:			; данные D4B7..D4B7 (1 байт)
	db	0xBD	; D4B7
L_D4B8:
	ld hl,L_D4EC+0x1              ; D4B8  21 ED D4
	ld (hl),0x00                  ; D4BB  36 00
	cp 0x55                       ; D4BD  FE 55
	ret c                         ; D4BF  D8

	sub 0x55                      ; D4C0  D6 55
	ld (hl),0x40                  ; D4C2  36 40
	cp 0x55                       ; D4C4  FE 55
	ret c                         ; D4C6  D8

	sub 0x55                      ; D4C7  D6 55
	ld (hl),0x80                  ; D4C9  36 80
	ret                           ; D4CB  C9

D_D4CC:			; данные D4CC..D4CE (3 байт)
	db	0x0A,0xC1,0xB0	; D4CC
L_D4CF:
	push hl                       ; D4CF  E5
	srl l                         ; D4D0  CB 3D
	srl l                         ; D4D2  CB 3D
	srl l                         ; D4D4  CB 3D
	ld a,l                        ; D4D6  7D
	sla h                         ; D4D7  CB 24
	sla h                         ; D4D9  CB 24
	sla h                         ; D4DB  CB 24
	ld l,h                        ; D4DD  6C
	ld h,0x00                     ; D4DE  26 00
	ld c,l                        ; D4E0  4D
	ld b,h                        ; D4E1  44
	add hl,hl                     ; D4E2  29
	add hl,bc                     ; D4E3  09
	ld c,a                        ; D4E4  4F
	ld b,0x00                     ; D4E5  06 00
	add hl,bc                     ; D4E7  09
	ld bc,WORK_RAM+0x1A5          ; D4E8  01 4D F3  ; в каноне +0x100 этот операнд стухший
	add hl,bc                     ; D4EB  09
L_D4EC:
	ld a,0x00                     ; D4EC  3E 00
	ld (hl),a                     ; D4EE  77
	pop hl                        ; D4EF  E1
	ret                           ; D4F0  C9

L_D4F1:
	call L_D49B                   ; D4F1  CD 9B D4
	jp L_CC9A                     ; D4F4  C3 9A CC

L_D4F7:
	call L_D4A9                   ; D4F7  CD A9 D4
	jp L_CCA7                     ; D4FA  C3 A7 CC

D_D4FD:			; данные D4FD..D5FF (259 байт)
	db	0xFF,0xF7,0xFF,0x00,0x80,0x40,0xC0,0x20,0xA0,0x60,0xE0,0x10,0x90,0x50,0xD0,0x30	; D4FD
	db	0xB0,0x70,0xF0,0x08,0x88,0x48,0xC8,0x28,0xA8,0x68,0xE8,0x18,0x98,0x58,0xD8,0x38	; D50D
	db	0xB8,0x78,0xF8,0x04,0x84,0x44,0xC4,0x24,0xA4,0x64,0xE4,0x14,0x94,0x54,0xD4,0x34	; D51D
	db	0xB4,0x74,0xF4,0x0C,0x8C,0x4C,0xCC,0x2C,0xAC,0x6C,0xEC,0x1C,0x9C,0x5C,0xDC,0x3C	; D52D
	db	0xBC,0x7C,0xFC,0x02,0x82,0x42,0xC2,0x22,0xA2,0x62,0xE2,0x12,0x92,0x52,0xD2,0x32	; D53D
	db	0xB2,0x72,0xF2,0x0A,0x8A,0x4A,0xCA,0x2A,0xAA,0x6A,0xEA,0x1A,0x9A,0x5A,0xDA,0x3A	; D54D
	db	0xBA,0x7A,0xFA,0x06,0x86,0x46,0xC6,0x26,0xA6,0x66,0xE6,0x16,0x96,0x56,0xD6,0x36	; D55D
	db	0xB6,0x76,0xF6,0x0E,0x8E,0x4E,0xCE,0x2E,0xAE,0x6E,0xEE,0x1E,0x9E,0x5E,0xDE,0x3E	; D56D
	db	0xBE,0x7E,0xFE,0x01,0x81,0x41,0xC1,0x21,0xA1,0x61,0xE1,0x11,0x91,0x51,0xD1,0x31	; D57D
	db	0xB1,0x71,0xF1,0x09,0x89,0x49,0xC9,0x29,0xA9,0x69,0xE9,0x19,0x99,0x59,0xD9,0x39	; D58D
	db	0xB9,0x79,0xF9,0x05,0x85,0x45,0xC5,0x25,0xA5,0x65,0xE5,0x15,0x95,0x55,0xD5,0x35	; D59D
	db	0xB5,0x75,0xF5,0x0D,0x8D,0x4D,0xCD,0x2D,0xAD,0x6D,0xED,0x1D,0x9D,0x5D,0xDD,0x3D	; D5AD
	db	0xBD,0x7D,0xFD,0x03,0x83,0x43,0xC3,0x23,0xA3,0x63,0xE3,0x13,0x93,0x53,0xD3,0x33	; D5BD
	db	0xB3,0x73,0xF3,0x0B,0x8B,0x4B,0xCB,0x2B,0xAB,0x6B,0xEB,0x1B,0x9B,0x5B,0xDB,0x3B	; D5CD
	db	0xBB,0x7B,0xFB,0x07,0x87,0x47,0xC7,0x27,0xA7,0x67,0xE7,0x17,0x97,0x57,0xD7,0x37	; D5DD
	db	0xB7,0x77,0xF7,0x0F,0x8F,0x4F,0xCF,0x2F,0xAF,0x6F,0xEF,0x1F,0x9F,0x5F,0xDF,0x3F	; D5ED
	db	0xBF,0x7F,0xFF	; D5FD
ATTR_ADDR:
	ld a,c                        ; D600  79
	and 0xF8                      ; D601  E6 F8
	ld c,a                        ; D603  4F
	ld a,b                        ; D604  78
	and 0xF8                      ; D605  E6 F8
	rra                           ; D607  1F
	rra                           ; D608  1F
	rra                           ; D609  1F
	ld l,c                        ; D60A  69
	ld h,0x00                     ; D60B  26 00
	ld b,h                        ; D60D  44
	add hl,hl                     ; D60E  29
	add hl,bc                     ; D60F  09
	ld bc,WORK_RAM+0x1A5          ; D610  01 4D F3  ; в каноне +0x100 этот операнд стухший
	add hl,bc                     ; D613  09
	ld c,a                        ; D614  4F
	ld b,0x00                     ; D615  06 00
	add hl,bc                     ; D617  09
	ret                           ; D618  C9

L_D619:
	ld b,0x20                     ; D619  06 20
	ld hl,0x5B00                  ; D61B  21 00 5B
L_D61E:
	call VDP_RD_BYTE              ; D61E  CD 20 D3
	cp 0x60                       ; D621  FE 60
	jr nc,L_D62A                  ; D623  30 05
	ld a,0xD1                     ; D625  3E D1
	call VDP_WR_BYTE              ; D627  CD 28 D3
L_D62A:
	ld a,0x04                     ; D62A  3E 04
	add a,l                       ; D62C  85
	ld l,a                        ; D62D  6F
	djnz L_D61E                   ; D62E  10 EE
	jp L_C38C                     ; D630  C3 8C C3

D_D633:			; данные D633..D635 (3 байт)
	db	0xFF,0xFF,0xFF	; D633
L_D636:
	xor a                         ; D636  AF
	sbc hl,de                     ; D637  ED 52
	ld b,l                        ; D639  45
L_D63A:
	ld (de),a                     ; D63A  12
	inc de                        ; D63B  13
	djnz L_D63A                   ; D63C  10 FC
	ret                           ; D63E  C9

L_D63F:
	push hl                       ; D63F  E5
	push de                       ; D640  D5
	push bc                       ; D641  C5
	ld hl,WORK_RAM+0x3E5          ; D642  21 8D F5  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x3E6          ; D645  11 8E F5  ; в каноне +0x100 этот операнд стухший
	ld bc,0x01F0                  ; D648  01 F0 01
	ld (hl),0x00                  ; D64B  36 00
	ldir                          ; D64D  ED B0
	pop bc                        ; D64F  C1
	pop de                        ; D650  D1
	pop hl                        ; D651  E1
	jp L_C698                     ; D652  C3 98 C6

L_D655:
	push bc                       ; D655  C5
	ld bc,0x03                    ; D656  01 03 00
	lddr                          ; D659  ED B8
	ld a,(hl)                     ; D65B  7E
	add a,0x60                    ; D65C  C6 60
	ld (de),a                     ; D65E  12
	dec de                        ; D65F  1B
	dec hl                        ; D660  2B
	pop bc                        ; D661  C1
	djnz L_D655                   ; D662  10 F1
L_D664:
	ld hl,WORK_RAM+0x5D6          ; D664  21 7E F7  ; в каноне +0x100 этот операнд стухший
	ld de,0x1B00                  ; D667  11 00 1B
	ld bc,0x80                    ; D66A  01 80 00
	call L_D332                   ; D66D  CD 32 D3
	ld hl,WORK_RAM+0x658          ; D670  21 00 F8  ; в каноне +0x100 этот операнд стухший
	ld de,0x3800                  ; D673  11 00 38
	ld bc,0x0800                  ; D676  01 00 08
	call L_D332                   ; D679  CD 32 D3
	ld ix,WORK_RAM+0x81           ; D67C  DD 21 29 F2  ; в каноне +0x100 этот операнд стухший
	jp L_D98E                     ; D680  C3 8E D9

D_D683:			; данные D683..D683 (1 байт)
	db	0xC9	; D683
KBD_CHK_F3B5:
	ld a,0xF3                     ; D684  3E F3
	out (0xAA),a                  ; D686  D3 AA
	in a,(0xA9)                   ; D688  DB A9
	bit 5,a                       ; D68A  CB 6F
	ret nz                        ; D68C  C0

	jp L_CC5D                     ; D68D  C3 5D CC

D_D690:			; данные D690..D691 (2 байт)
	db	0x70,0x45	; D690
L_D692:
	ld a,(GAME_VARS+0xA)          ; D692  3A F4 C1
	cp 0x61                       ; D695  FE 61
	ret nc                        ; D697  D0

	ld bc,(GAME_VARS+0xA)         ; D698  ED 4B F4 C1
	jp L_D6A9                     ; D69C  C3 A9 D6

L_D69F:
	ld a,(GAME_VARS+0xA)          ; D69F  3A F4 C1
	cp 0x60                       ; D6A2  FE 60
	ret c                         ; D6A4  D8

	ld bc,(GAME_VARS+0xA)         ; D6A5  ED 4B F4 C1
L_D6A9:
	call SCR_ADDR_BIT14           ; D6A9  CD 70 D2
	ld a,l                        ; D6AC  7D
	and 0xF8                      ; D6AD  E6 F8
	ld l,a                        ; D6AF  6F
	ld de,0x0500                  ; D6B0  11 00 05
	sbc hl,de                     ; D6B3  ED 52
	ld (D_D690),hl                ; D6B5  22 90 D6
	ld de,0x08                    ; D6B8  11 08 00
	and a                         ; D6BB  A7
	sbc hl,de                     ; D6BC  ED 52
	push hl                       ; D6BE  E5
	ld de,0x8030                  ; D6BF  11 30 80
	ld b,0x06                     ; D6C2  06 06
L_D6C4:
	ld c,0x30                     ; D6C4  0E 30
	push hl                       ; D6C6  E5
	call VDP_SET_RADDR            ; D6C7  CD FD D2
L_D6CA:
	and a                         ; D6CA  A7
	in a,(0x98)                   ; D6CB  DB 98
	ld (de),a                     ; D6CD  12
	inc de                        ; D6CE  13
	dec c                         ; D6CF  0D
	jr nz,L_D6CA                  ; D6D0  20 F8
	pop hl                        ; D6D2  E1
	inc h                         ; D6D3  24
	djnz L_D6C4                   ; D6D4  10 EE
	pop hl                        ; D6D6  E1
	jp L_D9AA                     ; D6D7  C3 AA D9

SFX_64D7:
	push hl                       ; D6DA  E5
	push bc                       ; D6DB  C5
	ld hl,P1_SFX_64D7             ; D6DC  21 D7 64
	call L_83F5                   ; D6DF  CD F5 83
	pop bc                        ; D6E2  C1
	pop hl                        ; D6E3  E1
	ret                           ; D6E4  C9

SFX_64E6:
	ld hl,P1_SFX_64E6             ; D6E5  21 E6 64
	jp L_83F5                     ; D6E8  C3 F5 83

D_D6EB:			; данные D6EB..D6F1 (7 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00	; D6EB
SFX_64D7_x25:
	ld b,0x19                     ; D6F2  06 19
L_D6F4:
	push bc                       ; D6F4  C5
	ld hl,P1_SFX_64D7             ; D6F5  21 D7 64
	call L_83F5                   ; D6F8  CD F5 83
	ld hl,0x1388                  ; D6FB  21 88 13
L_D6FE:
	dec hl                        ; D6FE  2B
	ld a,h                        ; D6FF  7C
	or l                          ; D700  B5
	jr nz,L_D6FE                  ; D701  20 FB
	pop bc                        ; D703  C1
	djnz L_D6F4                   ; D704  10 EE
	jp SFX_64F5                   ; D706  C3 9A D7

D_D709:			; данные D709..D70C (4 байт)
	db	0x00,0x00,0x08,0x00	; D709
L_D70D:
	ld a,0xD0                     ; D70D  3E D0
	ld (L_DA89+0x1),a             ; D70F  32 8A DA
	ld de,0x8180                  ; D712  11 80 81
	ld a,l                        ; D715  7D
	ld c,0x20                     ; D716  0E 20
	cp 0xA0                       ; D718  FE A0
	jr z,L_D738                   ; D71A  28 1C
	ld c,0x28                     ; D71C  0E 28
	cp 0x98                       ; D71E  FE 98
	jr z,L_D738                   ; D720  28 16
	cp 0xF8                       ; D722  FE F8
	jr nz,L_D736                  ; D724  20 10
	ld a,0xD1                     ; D726  3E D1
	ld (L_DA89+0x1),a             ; D728  32 8A DA
	ld l,0x00                     ; D72B  2E 00
	inc h                         ; D72D  24
	ld a,e                        ; D72E  7B
	add a,0x08                    ; D72F  C6 08
	ld e,a                        ; D731  5F
	ld c,0x28                     ; D732  0E 28
	jr L_D738                     ; D734  18 02

L_D736:
	ld c,0x30                     ; D736  0E 30
L_D738:
	ld a,c                        ; D738  79
	ld (L_DA62+0x1),a             ; D739  32 63 DA
	srl a                         ; D73C  CB 3F
	srl a                         ; D73E  CB 3F
	srl a                         ; D740  CB 3F
	ld (L_DAA6+0x1),a             ; D742  32 A7 DA
	jp L_DA56                     ; D745  C3 56 DA

D_D748:			; данные D748..D748 (1 байт)
	db	0xDA	; D748
L_D749:
	ld b,0x06                     ; D749  06 06
L_D74B:
	ld c,0x08                     ; D74B  0E 08
	call VDP_SET_RADDR            ; D74D  CD FD D2
L_D750:
	and a                         ; D750  A7
	in a,(0x98)                   ; D751  DB 98
	ld (de),a                     ; D753  12
	inc de                        ; D754  13
	nop                           ; D755  00
	nop                           ; D756  00
	dec c                         ; D757  0D
	jr nz,L_D750                  ; D758  20 F6
	push hl                       ; D75A  E5
	ld hl,0x28                    ; D75B  21 28 00
	add hl,de                     ; D75E  19
	ex de,hl                      ; D75F  EB
	pop hl                        ; D760  E1
	inc h                         ; D761  24
	djnz L_D74B                   ; D762  10 E7
	ret                           ; D764  C9

D_D765:			; данные D765..D76D (9 байт)
	db	0x42,0x00,0x86,0x00,0x82,0x00,0x06,0x00,0x46	; D765
L_D76E:
	ld c,0x30                     ; D76E  0E 30
	call VDP_SET_RADDR            ; D770  CD FD D2
L_D773:
	and a                         ; D773  A7
	in a,(0x98)                   ; D774  DB 98
	ld (de),a                     ; D776  12
	inc de                        ; D777  13
	nop                           ; D778  00
	nop                           ; D779  00
	dec c                         ; D77A  0D
	jr nz,L_D773                  ; D77B  20 F6
	ret                           ; D77D  C9

L_D77E:
	ld a,(GAME_VARS+0x7)          ; D77E  3A F1 C1
	cp 0x01                       ; D781  FE 01
	jr z,SFX_64AA                 ; D783  28 09
	cp 0x04                       ; D785  FE 04
	ret nz                        ; D787  C0

SFX_64B9:
	ld hl,P1_SFX_64B9             ; D788  21 B9 64
	jp L_83F5                     ; D78B  C3 F5 83

SFX_64AA:
	ld hl,P1_SFX_64AA             ; D78E  21 AA 64
	jp L_83F5                     ; D791  C3 F5 83

SFX_64C8:
	ld hl,P1_SFX_64C8             ; D794  21 C8 64
	jp L_83F5                     ; D797  C3 F5 83

SFX_64F5:
	ld hl,P1_SFX_64F5             ; D79A  21 F5 64
	jp L_83F5                     ; D79D  C3 F5 83

D_D7A0:			; данные D7A0..D7A7 (8 байт)
	db	0xFB,0x00,0x00,0x00,0x08,0x00,0x00,0x07	; D7A0
L_D7A8:
	push hl                       ; D7A8  E5
	ld b,(ix+0x02)                ; D7A9  DD 46 02
	ld a,b                        ; D7AC  78
	srl b                         ; D7AD  CB 38
	srl b                         ; D7AF  CB 38
	srl b                         ; D7B1  CB 38
	and 0x07                      ; D7B3  E6 07
	jr z,L_D7B8                   ; D7B5  28 01
	inc b                         ; D7B7  04
L_D7B8:
	ld hl,0x8278                  ; D7B8  21 78 82
	ld de,0x30                    ; D7BB  11 30 00
L_D7BE:
	and a                         ; D7BE  A7
	sbc hl,de                     ; D7BF  ED 52
	djnz L_D7BE                   ; D7C1  10 FB
	ex de,hl                      ; D7C3  EB
	pop hl                        ; D7C4  E1
	push ix                       ; D7C5  DD E5
	ld a,(D_D7A0+0x5)             ; D7C7  3A A5 D7
	add a,e                       ; D7CA  83
	ld e,a                        ; D7CB  5F
	ld a,(ix+0x02)                ; D7CC  DD 7E 02
	push de                       ; D7CF  D5
	pop ix                        ; D7D0  DD E1
	ld b,a                        ; D7D2  47
L_D7D3:
	ld e,(hl)                     ; D7D3  5E
	inc hl                        ; D7D4  23
	ld d,(hl)                     ; D7D5  56
	inc hl                        ; D7D6  23
	ld c,(hl)                     ; D7D7  4E
	inc hl                        ; D7D8  23
	push bc                       ; D7D9  C5
	ld b,0x00                     ; D7DA  06 00
	ld a,(D_D7A0+0x7)             ; D7DC  3A A7 D7
L_D7DF:
	cp 0x00                       ; D7DF  FE 00
	jr z,L_D7EE                   ; D7E1  28 0B
	dec a                         ; D7E3  3D
	srl e                         ; D7E4  CB 3B
	rr d                          ; D7E6  CB 1A
	rr c                          ; D7E8  CB 19
	rr b                          ; D7EA  CB 18
	jr L_D7DF                     ; D7EC  18 F1

L_D7EE:
	ld a,e                        ; D7EE  7B
	or (ix+0x00)                  ; D7EF  DD B6 00
	ld (ix+0x00),a                ; D7F2  DD 77 00
	ld a,d                        ; D7F5  7A
	or (ix+0x08)                  ; D7F6  DD B6 08
	ld (ix+0x08),a                ; D7F9  DD 77 08
	ld a,c                        ; D7FC  79
	or (ix+0x10)                  ; D7FD  DD B6 10
	ld (ix+0x10),a                ; D800  DD 77 10
	ld a,b                        ; D803  78
	or (ix+0x18)                  ; D804  DD B6 18
	ld (ix+0x18),a                ; D807  DD 77 18
	pop bc                        ; D80A  C1
	ld a,ixl                      ; D80B  DD 7D
	and 0x07                      ; D80D  E6 07
	cp 0x07                       ; D80F  FE 07
	jr nz,L_D818                  ; D811  20 05
	ld de,0x28                    ; D813  11 28 00
	add ix,de                     ; D816  DD 19
L_D818:
	inc ix                        ; D818  DD 23
	djnz L_D7D3                   ; D81A  10 B7
	pop ix                        ; D81C  DD E1
	ld hl,0x82D7                  ; D81E  21 D7 82
	ld c,0x04                     ; D821  0E 04
	ld a,0x03                     ; D823  3E 03
	ld (L_D83C+0x1),a             ; D825  32 3D D8
	ld (L_D844+0x1),a             ; D828  32 45 D8
	ld a,(ix+0x04)                ; D82B  DD 7E 04
	cp 0xA8                       ; D82E  FE A8
	jr nc,L_D83C                  ; D830  30 0A
	ld a,0x04                     ; D832  3E 04
	ld (L_D83C+0x1),a             ; D834  32 3D D8
	ld a,0x02                     ; D837  3E 02
	ld (L_D844+0x1),a             ; D839  32 45 D8
L_D83C:
	ld b,0x04                     ; D83C  06 04
	ld a,0xF1                     ; D83E  3E F1
L_D840:
	ld (hl),a                     ; D840  77
	inc hl                        ; D841  23
	djnz L_D840                   ; D842  10 FC
L_D844:
	ld de,0x02                    ; D844  11 02 00
	add hl,de                     ; D847  19
	dec c                         ; D848  0D
	jr nz,L_D83C                  ; D849  20 F1
	ret                           ; D84B  C9

D_D84C:			; данные D84C..D867 (28 байт)
	db	0xCC,0xD2,0xDD,0x7E,0xFE,0xDD,0x77,0x07,0xDD,0x7E,0xFD,0xDD,0x77,0x06,0xCD,0xA8	; D84C
	db	0xD7,0x01,0x09,0x00,0xDD,0x09,0xC9,0x00,0x00,0x18,0x00,0x20	; D85C
L_D868:
	ld (L_D897+0x1),bc            ; D868  ED 43 98 D8
	ld (L_D8A0+0x1),a             ; D86C  32 A1 D8
	and 0x7F                      ; D86F  E6 7F
	ld (ix+0x08),a                ; D871  DD 77 08
	push bc                       ; D874  C5
	ld b,a                        ; D875  47
	call SPR_HDR                  ; D876  CD 44 D2
	ld (L_D89D+0x1),hl            ; D879  22 9E D8
	ld (ix+0x02),b                ; D87C  DD 70 02
	ld (ix+0x03),a                ; D87F  DD 77 03
	ld a,b                        ; D882  78
	neg                           ; D883  ED 44
	pop bc                        ; D885  C1
	add a,c                       ; D886  81
	ld (ix+0x00),a                ; D887  DD 77 00
	ld (ix+0x01),b                ; D88A  DD 70 01
	ld c,a                        ; D88D  4F
L_D88E:
	call SCR_ADDR_BIT14           ; D88E  CD 70 D2
	ld (ix+0x04),l                ; D891  DD 75 04
	ld (ix+0x05),h                ; D894  DD 74 05
L_D897:
	ld bc,0x7750                  ; D897  01 50 77
	call L_D8CF                   ; D89A  CD CF D8
L_D89D:
	ld hl,SPR_BANK_E04B+0x2       ; D89D  21 4D E0
L_D8A0:
	ld a,0x80                     ; D8A0  3E 80
	and 0x80                      ; D8A2  E6 80
	call nz,L_D2CC                ; D8A4  C4 CC D2
	ld a,(ix-0x02)                ; D8A7  DD 7E FE
	ld (ix+0x07),a                ; D8AA  DD 77 07
	ld a,(ix-0x03)                ; D8AD  DD 7E FD
	ld (ix+0x06),a                ; D8B0  DD 77 06
	call L_D7A8                   ; D8B3  CD A8 D7
	ld bc,0x09                    ; D8B6  01 09 00
	add ix,bc                     ; D8B9  DD 09
	ret                           ; D8BB  C9

D_D8BC:			; данные D8BC..D8CE (19 байт)
	db	0x91,0xD6,0xBC,0xF5,0x11,0x08,0x01,0xA7,0xED,0x52,0xF1,0x28,0x2B,0x30,0x17,0x7C	; D8BC
	db	0xC6,0x06,0x67	; D8CC
L_D8CF:
	call SCR_ADDR_BIT14           ; D8CF  CD 70 D2
	ld (D_D7A0+0x7),a             ; D8D2  32 A7 D7
	ld a,l                        ; D8D5  7D
	and 0x07                      ; D8D6  E6 07
	ld (D_D7A0+0x5),a             ; D8D8  32 A5 D7
	ld a,l                        ; D8DB  7D
	and 0xF8                      ; D8DC  E6 F8
	ld l,a                        ; D8DE  6F
	and a                         ; D8DF  A7
	ld de,0x0500                  ; D8E0  11 00 05
	sbc hl,de                     ; D8E3  ED 52
	push hl                       ; D8E5  E5
	ld a,(D_D690)                 ; D8E6  3A 90 D6
	cp l                          ; D8E9  BD
	jr z,L_D92A                   ; D8EA  28 3E
	ld a,(D_D690+0x1)             ; D8EC  3A 91 D6
	ld h,a                        ; D8EF  67
	jr nc,L_D90E                  ; D8F0  30 1C
	ld de,0x20                    ; D8F2  11 20 00
	add hl,de                     ; D8F5  19
	push hl                       ; D8F6  E5
	ld de,0x8060                  ; D8F7  11 60 80
	call L_D749                   ; D8FA  CD 49 D7
	ld de,0x8030                  ; D8FD  11 30 80
	ld hl,0x8038                  ; D900  21 38 80
	ld bc,0x0120                  ; D903  01 20 01
	ldir                          ; D906  ED B0
	pop hl                        ; D908  E1
	call L_D9D2                   ; D909  CD D2 D9
	jr L_D92A                     ; D90C  18 1C

L_D90E:
	ld de,0x08                    ; D90E  11 08 00
	and a                         ; D911  A7
	sbc hl,de                     ; D912  ED 52
	push hl                       ; D914  E5
	ld de,0x8028                  ; D915  11 28 80
	call L_D749                   ; D918  CD 49 D7
	ld hl,0x8147                  ; D91B  21 47 81
	ld de,0x814F                  ; D91E  11 4F 81
	ld bc,0x0120                  ; D921  01 20 01
	lddr                          ; D924  ED B8
	pop hl                        ; D926  E1
	call L_D9E4                   ; D927  CD E4 D9
L_D92A:
	pop hl                        ; D92A  E1
	push hl                       ; D92B  E5
	ld a,(D_D690+0x1)             ; D92C  3A 91 D6
	cp h                          ; D92F  BC
	push af                       ; D930  F5
	ld de,0x08                    ; D931  11 08 00
	and a                         ; D934  A7
	sbc hl,de                     ; D935  ED 52
	pop af                        ; D937  F1
	jr z,L_D96F                   ; D938  28 35
	jr nc,L_D958                  ; D93A  30 1C
	ld a,h                        ; D93C  7C
	add a,0x05                    ; D93D  C6 05
	ld h,a                        ; D93F  67
	ld de,0x8150                  ; D940  11 50 81
	push hl                       ; D943  E5
	call L_D76E                   ; D944  CD 6E D7
	ld de,0x8030                  ; D947  11 30 80
	ld hl,0x8060                  ; D94A  21 60 80
	ld bc,0x0120                  ; D94D  01 20 01
	ldir                          ; D950  ED B0
	pop hl                        ; D952  E1
	call L_DA0B                   ; D953  CD 0B DA
	jr L_D96F                     ; D956  18 17

L_D958:
	nop                           ; D958  00
	ld de,0x8000                  ; D959  11 00 80
	push hl                       ; D95C  E5
	call L_D76E                   ; D95D  CD 6E D7
	ld hl,0x811F                  ; D960  21 1F 81
	ld de,0x814F                  ; D963  11 4F 81
	ld bc,0x0120                  ; D966  01 20 01
	lddr                          ; D969  ED B8
	pop hl                        ; D96B  E1
	call L_DA1D                   ; D96C  CD 1D DA
L_D96F:
	ld hl,0x8030                  ; D96F  21 30 80
	ld de,0x8180                  ; D972  11 80 81
	ld bc,0x0120                  ; D975  01 20 01
	ldir                          ; D978  ED B0
	ld hl,0x82A6                  ; D97A  21 A6 82
	ld de,0x82D0                  ; D97D  11 D0 82
	ld bc,0x24                    ; D980  01 24 00
	ldir                          ; D983  ED B0
	pop hl                        ; D985  E1
	ld (D_D690),hl                ; D986  22 90 D6
	ret                           ; D989  C9

D_D98A:			; данные D98A..D98D (4 байт)
	db	0x00,0x00,0x00,0x00	; D98A
L_D98E:
	ld hl,(D_D690)                ; D98E  2A 90 D6
	ld de,0x08                    ; D991  11 08 00
	and a                         ; D994  A7
	sbc hl,de                     ; D995  ED 52
	push hl                       ; D997  E5
	call L_D70D                   ; D998  CD 0D D7
	pop hl                        ; D99B  E1
	ld a,(D_D123)                 ; D99C  3A 23 D1
	and a                         ; D99F  A7
	ret z                         ; D9A0  C8

	ld a,h                        ; D9A1  7C
	add a,0x0C                    ; D9A2  C6 0C
	ld h,a                        ; D9A4  67
	jp L_D70D                     ; D9A5  C3 0D D7

D_D9A8:			; данные D9A8..D9A9 (2 байт)
	db	0x00,0x00	; D9A8
L_D9AA:
	ld bc,0x2000                  ; D9AA  01 00 20
	add hl,bc                     ; D9AD  09
	ld de,0x82A6                  ; D9AE  11 A6 82
	ld c,0x06                     ; D9B1  0E 06
L_D9B3:
	push hl                       ; D9B3  E5
	ld b,0x06                     ; D9B4  06 06
L_D9B6:
	push bc                       ; D9B6  C5
	call VDP_RD_BYTE              ; D9B7  CD 20 D3
	ld (de),a                     ; D9BA  12
	inc de                        ; D9BB  13
	ld bc,0x08                    ; D9BC  01 08 00
	add hl,bc                     ; D9BF  09
	pop bc                        ; D9C0  C1
	djnz L_D9B6                   ; D9C1  10 F3
	pop hl                        ; D9C3  E1
	inc h                         ; D9C4  24
	dec c                         ; D9C5  0D
	jr nz,L_D9B3                  ; D9C6  20 EB
	ret                           ; D9C8  C9

D_D9C9:			; данные D9C9..D9D1 (9 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF	; D9C9
L_D9D2:
	ld de,0x82AC                  ; D9D2  11 AC 82
	call L_D9F6                   ; D9D5  CD F6 D9
	ld de,0x82A6                  ; D9D8  11 A6 82
	ld hl,0x82A7                  ; D9DB  21 A7 82
	ld bc,0x24                    ; D9DE  01 24 00
	ldir                          ; D9E1  ED B0
	ret                           ; D9E3  C9

L_D9E4:
	ld de,0x82A5                  ; D9E4  11 A5 82
	call L_D9F6                   ; D9E7  CD F6 D9
	ld hl,0x82C8                  ; D9EA  21 C8 82
	ld de,0x82C9                  ; D9ED  11 C9 82
	ld bc,0x24                    ; D9F0  01 24 00
	lddr                          ; D9F3  ED B8
	ret                           ; D9F5  C9

L_D9F6:
	ld bc,0x2000                  ; D9F6  01 00 20
	add hl,bc                     ; D9F9  09
	ld b,0x06                     ; D9FA  06 06
L_D9FC:
	call VDP_RD_BYTE              ; D9FC  CD 20 D3
	ld (de),a                     ; D9FF  12
	push hl                       ; DA00  E5
	ld hl,0x06                    ; DA01  21 06 00
	add hl,de                     ; DA04  19
	ex de,hl                      ; DA05  EB
	pop hl                        ; DA06  E1
	inc h                         ; DA07  24
	djnz L_D9FC                   ; DA08  10 F2
	ret                           ; DA0A  C9

L_DA0B:
	ld de,0x82CA                  ; DA0B  11 CA 82
	call L_DA2F                   ; DA0E  CD 2F DA
	ld de,0x82A6                  ; DA11  11 A6 82
	ld hl,0x82AC                  ; DA14  21 AC 82
	ld bc,0x24                    ; DA17  01 24 00
	ldir                          ; DA1A  ED B0
	ret                           ; DA1C  C9

L_DA1D:
	ld de,0x82A0                  ; DA1D  11 A0 82
	call L_DA2F                   ; DA20  CD 2F DA
	ld hl,0x82C3                  ; DA23  21 C3 82
	ld de,0x82C9                  ; DA26  11 C9 82
	ld bc,0x24                    ; DA29  01 24 00
	lddr                          ; DA2C  ED B8
	ret                           ; DA2E  C9

L_DA2F:
	ld bc,0x2000                  ; DA2F  01 00 20
	add hl,bc                     ; DA32  09
	ld b,0x06                     ; DA33  06 06
L_DA35:
	call VDP_RD_BYTE              ; DA35  CD 20 D3
	ld (de),a                     ; DA38  12
	inc de                        ; DA39  13
	push bc                       ; DA3A  C5
	ld bc,0x08                    ; DA3B  01 08 00
	add hl,bc                     ; DA3E  09
	pop bc                        ; DA3F  C1
	djnz L_DA35                   ; DA40  10 F3
	ret                           ; DA42  C9

D_DA43:			; данные DA43..DA55 (19 байт)
	db	0x00,0x08,0x00,0x31,0x00,0x11,0x00,0x30,0x00,0x49,0x00,0x38,0x00,0xFF,0xC7,0xFF	; DA43
	db	0xEF,0xFF,0xC7	; DA53
L_DA56:
	push hl                       ; DA56  E5
	ld b,0x06                     ; DA57  06 06
	ld a,h                        ; DA59  7C
	cp 0x4B                       ; DA5A  FE 4B
	jr nz,L_DA61                  ; DA5C  20 03
	push bc                       ; DA5E  C5
	jr L_DA6A                     ; DA5F  18 09

L_DA61:
	push bc                       ; DA61  C5
L_DA62:
	ld bc,0x30                    ; DA62  01 30 00
	ld a,h                        ; DA65  7C
	cp 0x58                       ; DA66  FE 58
	jr c,L_DA73                   ; DA68  38 09
L_DA6A:
	push hl                       ; DA6A  E5
	ld hl,0x30                    ; DA6B  21 30 00
	add hl,de                     ; DA6E  19
	ex de,hl                      ; DA6F  EB
	pop hl                        ; DA70  E1
	jr L_DA7F                     ; DA71  18 0C

L_DA73:
	push hl                       ; DA73  E5
	push de                       ; DA74  D5
	call VDP_COPY_TO_VRAM         ; DA75  CD 33 D3
	pop de                        ; DA78  D1
	ld hl,0x30                    ; DA79  21 30 00
	add hl,de                     ; DA7C  19
	ex de,hl                      ; DA7D  EB
	pop hl                        ; DA7E  E1
L_DA7F:
	inc h                         ; DA7F  24
	pop bc                        ; DA80  C1
	djnz L_DA61                   ; DA81  10 DE
	pop hl                        ; DA83  E1
	ld a,0x60                     ; DA84  3E 60
	ld (L_D30C+0x1),a             ; DA86  32 0D D3
L_DA89:
	ld de,0x82D0                  ; DA89  11 D0 82
	ld c,0x06                     ; DA8C  0E 06
	ld a,h                        ; DA8E  7C
	cp 0x4B                       ; DA8F  FE 4B
	jr nz,L_DA96                  ; DA91  20 03
	push hl                       ; DA93  E5
	jr L_DA9D                     ; DA94  18 07

L_DA96:
	push hl                       ; DA96  E5
	push de                       ; DA97  D5
	ld a,h                        ; DA98  7C
	cp 0x58                       ; DA99  FE 58
	jr c,L_DAA6                   ; DA9B  38 09
L_DA9D:
	push hl                       ; DA9D  E5
	ld hl,0x06                    ; DA9E  21 06 00
	add hl,de                     ; DAA1  19
	ex de,hl                      ; DAA2  EB
	pop hl                        ; DAA3  E1
	jr L_DAB9                     ; DAA4  18 13

L_DAA6:
	ld b,0x06                     ; DAA6  06 06
L_DAA8:
	push bc                       ; DAA8  C5
	ld bc,0x08                    ; DAA9  01 08 00
	ld a,(de)                     ; DAAC  1A
	nop                           ; DAAD  00
	call VDP_FILL                 ; DAAE  CD 11 D3
	inc de                        ; DAB1  13
	ld bc,0x08                    ; DAB2  01 08 00
	add hl,bc                     ; DAB5  09
	pop bc                        ; DAB6  C1
	djnz L_DAA8                   ; DAB7  10 EF
L_DAB9:
	pop de                        ; DAB9  D1
	ld hl,0x06                    ; DABA  21 06 00
	add hl,de                     ; DABD  19
	ex de,hl                      ; DABE  EB
	pop hl                        ; DABF  E1
	inc h                         ; DAC0  24
	dec c                         ; DAC1  0D
	jr nz,L_DA96                  ; DAC2  20 D2
	ld a,0x40                     ; DAC4  3E 40
	ld (L_D30C+0x1),a             ; DAC6  32 0D D3
	ret                           ; DAC9  C9

D_DACA:			; данные DACA..DACE (5 байт)
	db	0x00,0xCD,0x68,0xD8,0xCD	; DACA
L_DACF:
	ld a,0xC9                     ; DACF  3E C9
	ld (L_D7A8),a                 ; DAD1  32 A8 D7
	ld bc,(GAME_VARS+0xA)         ; DAD4  ED 4B F4 C1
	ld a,0x00                     ; DAD8  3E 00
	call L_D868                   ; DADA  CD 68 D8
	call L_D98E                   ; DADD  CD 8E D9
	ld a,0xE5                     ; DAE0  3E E5
	ld (L_D7A8),a                 ; DAE2  32 A8 D7
	ret                           ; DAE5  C9

	jp L_D98E                     ; DAE6  C3 8E D9  ; в каноне +0x100 этот операнд стухший

L_DAE9:
	call L_CDCD                   ; DAE9  CD CD CD
	ld hl,LOW_TILE_SRC            ; DAEC  21 F4 81
	ld (L_CE36+0x1),hl            ; DAEF  22 37 CE
	ld hl,D_DB0E                  ; DAF2  21 0E DB
	ld b,0x11                     ; DAF5  06 11
	ld de,0x1518                  ; DAF7  11 18 15
	call L_CDF9                   ; DAFA  CD F9 CD
	ld hl,HUD_TILES+0x8C          ; DAFD  21 E2 B7
	ld (L_CE36+0x1),hl            ; DB00  22 37 CE
	ld b,0x04                     ; DB03  06 04
	ld de,0x171A                  ; DB05  11 1A 17
	ld hl,D_DB0E+0x11             ; DB08  21 1F DB
	jp L_CDF9                     ; DB0B  C3 F9 CD

D_DB0E:			; данные DB0E..DB23 (22 байт)
	db	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x18,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F	; DB0E
	db	0x30,0x3B,0x43,0x42,0x41,0x00	; DB1E
L_DB24:
	call SFX_64E6                 ; DB24  CD E5 D6
	ld bc,0x2710                  ; DB27  01 10 27
L_DB2A:
	dec bc                        ; DB2A  0B
	ld a,b                        ; DB2B  78
	or c                          ; DB2C  B1
	jr nz,L_DB2A                  ; DB2D  20 FB
	ret                           ; DB2F  C9

D_DB30:			; данные DB30..DB39 (10 байт)
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DB30
MUS_START:
	ld hl,(D_DC6F+0x14)           ; DB3A  2A 83 DC
	ld (D_DC6F+0xA),hl            ; DB3D  22 79 DC
	ld hl,(D_DC6F+0x16)           ; DB40  2A 85 DC
	ld (D_DC6F+0xC),hl            ; DB43  22 7B DC
	ld hl,(D_DC6F+0x18)           ; DB46  2A 87 DC
	ld (D_DC6F+0xE),hl            ; DB49  22 7D DC
	ld hl,D_DC6F                  ; DB4C  21 6F DC
	ld b,(hl)                     ; DB4F  46
	inc hl                        ; DB50  23
L_DB51:
	push bc                       ; DB51  C5
	ld a,(hl)                     ; DB52  7E
	inc hl                        ; DB53  23
	ld c,(hl)                     ; DB54  4E
	inc hl                        ; DB55  23
	call PSG_WR                   ; DB56  CD 69 DC
	pop bc                        ; DB59  C1
	djnz L_DB51                   ; DB5A  10 F5
L_DB5C:
	ld bc,(D_DC6F+0x12)           ; DB5C  ED 4B 81 DC
L_DB60:
	push bc                       ; DB60  C5
	ld b,0x09                     ; DB61  06 09
	ld c,0xF0                     ; DB63  0E F0
L_DB65:
	ld a,c                        ; DB65  79
	out (0xAA),a                  ; DB66  D3 AA
	in a,(0xA9)                   ; DB68  DB A9
	cp 0xFF                       ; DB6A  FE FF
	jp nz,L_DC5C                  ; DB6C  C2 5C DC
	inc c                         ; DB6F  0C
	djnz L_DB65                   ; DB70  10 F3
	pop bc                        ; DB72  C1
	dec bc                        ; DB73  0B
	ld a,b                        ; DB74  78
	or c                          ; DB75  B1
	jr nz,L_DB60                  ; DB76  20 E8
	ld hl,(D_DC6F+0xA)            ; DB78  2A 79 DC
	ld a,(D_DC6F+0x9)             ; DB7B  3A 78 DC
	or 0x01                       ; DB7E  F6 01
	ld (D_DC6F+0x9),a             ; DB80  32 78 DC
	ld c,a                        ; DB83  4F
	ld a,0x07                     ; DB84  3E 07
	call PSG_WR                   ; DB86  CD 69 DC
	ld a,(hl)                     ; DB89  7E
	cp 0xFE                       ; DB8A  FE FE
	jr nz,L_DB95                  ; DB8C  20 07
	ld hl,(D_DC6F+0x14)           ; DB8E  2A 83 DC
	ld (D_DC6F+0xA),hl            ; DB91  22 79 DC
	ld a,(hl)                     ; DB94  7E
L_DB95:
	cp 0xFF                       ; DB95  FE FF
	jr z,L_DBBF                   ; DB97  28 26
	sla a                         ; DB99  CB 27
	ld d,0x00                     ; DB9B  16 00
	ld e,a                        ; DB9D  5F
	push hl                       ; DB9E  E5
	ld hl,(D_DC6F+0x10)           ; DB9F  2A 7F DC
	add hl,de                     ; DBA2  19
	ld a,0x00                     ; DBA3  3E 00
	ld c,(hl)                     ; DBA5  4E
	call PSG_WR                   ; DBA6  CD 69 DC
	ld a,0x01                     ; DBA9  3E 01
	inc hl                        ; DBAB  23
	ld c,(hl)                     ; DBAC  4E
	call PSG_WR                   ; DBAD  CD 69 DC
	ld a,(D_DC6F+0x9)             ; DBB0  3A 78 DC
	and 0xFE                      ; DBB3  E6 FE
	ld (D_DC6F+0x9),a             ; DBB5  32 78 DC
	ld c,a                        ; DBB8  4F
	ld a,0x07                     ; DBB9  3E 07
	call PSG_WR                   ; DBBB  CD 69 DC
	pop hl                        ; DBBE  E1
L_DBBF:
	inc hl                        ; DBBF  23
	ld (D_DC6F+0xA),hl            ; DBC0  22 79 DC
	ld hl,(D_DC6F+0xC)            ; DBC3  2A 7B DC
	ld a,(D_DC6F+0x9)             ; DBC6  3A 78 DC
	or 0x02                       ; DBC9  F6 02
	ld (D_DC6F+0x9),a             ; DBCB  32 78 DC
	ld c,a                        ; DBCE  4F
	ld a,0x07                     ; DBCF  3E 07
	call PSG_WR                   ; DBD1  CD 69 DC
	ld a,(hl)                     ; DBD4  7E
	cp 0xFE                       ; DBD5  FE FE
	jr nz,L_DBE0                  ; DBD7  20 07
	ld hl,(D_DC6F+0x16)           ; DBD9  2A 85 DC
	ld (D_DC6F+0xC),hl            ; DBDC  22 7B DC
	ld a,(hl)                     ; DBDF  7E
L_DBE0:
	cp 0xFF                       ; DBE0  FE FF
	jr z,L_DC0A                   ; DBE2  28 26
	sla a                         ; DBE4  CB 27
	ld d,0x00                     ; DBE6  16 00
	ld e,a                        ; DBE8  5F
	push hl                       ; DBE9  E5
	ld hl,(D_DC6F+0x10)           ; DBEA  2A 7F DC
	add hl,de                     ; DBED  19
	ld a,0x02                     ; DBEE  3E 02
	ld c,(hl)                     ; DBF0  4E
	call PSG_WR                   ; DBF1  CD 69 DC
	ld a,0x03                     ; DBF4  3E 03
	inc hl                        ; DBF6  23
	ld c,(hl)                     ; DBF7  4E
	call PSG_WR                   ; DBF8  CD 69 DC
	ld a,(D_DC6F+0x9)             ; DBFB  3A 78 DC
	and 0xFD                      ; DBFE  E6 FD
	ld (D_DC6F+0x9),a             ; DC00  32 78 DC
	ld c,a                        ; DC03  4F
	ld a,0x07                     ; DC04  3E 07
	call PSG_WR                   ; DC06  CD 69 DC
	pop hl                        ; DC09  E1
L_DC0A:
	inc hl                        ; DC0A  23
	ld (D_DC6F+0xC),hl            ; DC0B  22 7B DC
	ld hl,(D_DC6F+0xE)            ; DC0E  2A 7D DC
	ld a,(D_DC6F+0x9)             ; DC11  3A 78 DC
	or 0x04                       ; DC14  F6 04
	ld (D_DC6F+0x9),a             ; DC16  32 78 DC
	ld c,a                        ; DC19  4F
	ld a,0x07                     ; DC1A  3E 07
	call PSG_WR                   ; DC1C  CD 69 DC
	ld a,(hl)                     ; DC1F  7E
	cp 0xFE                       ; DC20  FE FE
	jr nz,L_DC2B                  ; DC22  20 07
	ld hl,(D_DC6F+0x18)           ; DC24  2A 87 DC
	ld (D_DC6F+0xE),hl            ; DC27  22 7D DC
	ld a,(hl)                     ; DC2A  7E
L_DC2B:
	cp 0xFF                       ; DC2B  FE FF
	jr z,L_DC55                   ; DC2D  28 26
	sla a                         ; DC2F  CB 27
	ld d,0x00                     ; DC31  16 00
	ld e,a                        ; DC33  5F
	push hl                       ; DC34  E5
	ld hl,(D_DC6F+0x10)           ; DC35  2A 7F DC
	add hl,de                     ; DC38  19
	ld a,0x04                     ; DC39  3E 04
	ld c,(hl)                     ; DC3B  4E
	call PSG_WR                   ; DC3C  CD 69 DC
	ld a,0x05                     ; DC3F  3E 05
	inc hl                        ; DC41  23
	ld c,(hl)                     ; DC42  4E
	call PSG_WR                   ; DC43  CD 69 DC
	ld a,(D_DC6F+0x9)             ; DC46  3A 78 DC
	and 0xFB                      ; DC49  E6 FB
	ld (D_DC6F+0x9),a             ; DC4B  32 78 DC
	ld c,a                        ; DC4E  4F
	ld a,0x07                     ; DC4F  3E 07
	call PSG_WR                   ; DC51  CD 69 DC
	pop hl                        ; DC54  E1
L_DC55:
	inc hl                        ; DC55  23
	ld (D_DC6F+0xE),hl            ; DC56  22 7D DC
	jp L_DB5C                     ; DC59  C3 5C DB

L_DC5C:
	pop bc                        ; DC5C  C1
	ld a,0x3F                     ; DC5D  3E 3F
	ld (D_DC6F+0x9),a             ; DC5F  32 78 DC
	ld c,a                        ; DC62  4F
	ld a,0x07                     ; DC63  3E 07
	call PSG_WR                   ; DC65  CD 69 DC
	ret                           ; DC68  C9

PSG_WR:
	out (0xA0),a                  ; DC69  D3 A0
	ld a,c                        ; DC6B  79
	out (0xA1),a                  ; DC6C  D3 A1
	ret                           ; DC6E  C9

D_DC6F:			; данные DC6F..DFE6 (888 байт)
	db	0x04,0x07,0x3F,0x08,0x00,0x09,0x00,0x0A,0x00,0x3F,0x00,0x00,0x00,0x00,0x00,0x00	; DC6F
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; DC7F
	dw	D_DC6F+0x376	; DC87  E5 DF
	db	0x5C,0x0D,0x9C,0x0C,0xE7,0x0B,0x3C,0x0B,0x9A,0x0A,0x02,0x0A,0x72,0x09,0xEA,0x08	; DC89
	db	0x6A,0x08,0xF1,0x07,0x7F,0x07,0x13,0x07,0xAE,0x06,0x4E,0x06,0xF3,0x05,0x9E,0x05	; DC99
	db	0x4D,0x05,0x01,0x05,0xB9,0x04,0x75,0x04,0x35,0x04,0xF8,0x03,0xBF,0x03,0x89,0x03	; DCA9
	db	0x57,0x03,0x27,0x03,0xF9,0x02,0xCF,0x02,0xA6,0x02,0x80,0x02,0x5C,0x02,0x3A,0x02	; DCB9
	db	0x1A,0x02,0xFC,0x01,0xDF,0x01,0xC4,0x01,0xAB,0x01,0x93,0x01,0x7C,0x01,0x67,0x01	; DCC9
	db	0x53,0x01,0x40,0x01,0x2E,0x01,0x1D,0x01,0x0D,0x01,0xFE,0x00,0xEF,0x00,0xE2,0x00	; DCD9
	db	0xD5,0x00,0xC9,0x00,0xBE,0x00,0xB3,0x00,0xA9,0x00,0xA0,0x00,0x97,0x00,0x8E,0x00	; DCE9
	db	0x86,0x00,0x7F,0x00,0x77,0x00,0x71,0x00,0x6A,0x00,0x64,0x00,0x5F,0x00,0x59,0x00	; DCF9
	db	0x54,0x00,0x50,0x00,0x4B,0x00,0x47,0x00,0x43,0x00,0x3F,0x00,0x3B,0x00,0x38,0x00	; DD09
	db	0x35,0x00,0x32,0x00,0x2F,0x00,0x2C,0x00,0x2A,0x00,0x28,0x00,0x25,0x00,0x23,0x00	; DD19
	db	0x21,0x00,0x1F,0x00,0x1D,0x00,0x1C,0x00,0x1A,0x00,0x19,0x00,0x17,0x00,0x16,0x00	; DD29
	db	0x15,0x00,0x14,0x00,0x12,0x00,0x11,0x00,0x10,0x00,0x0F,0x00,0x0E,0x00,0x0E,0x00	; DD39
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; DD49
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01	; DD59
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; DD69
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; DD79
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; DD89
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; DD99
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; DDA9
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; DDB9
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; DDC9
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; DDD9
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; DDE9
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; DDF9
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; DE09
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; DE19
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0xFE,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DE29
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DE39
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DE49
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DE59
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DE69
	db	0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03	; DE79
	db	0xFF,0x01,0xFF,0x01,0xFF,0x01,0xFF,0x01,0xFF,0x0A,0xFF,0x0A,0xFF,0x0C,0xFF,0x0C	; DE89
	db	0xFF,0x06,0xFF,0x06,0xFF,0x01,0xFF,0x01,0xFF,0x06,0xFF,0x06,0xFF,0x03,0xFF,0x08	; DE99
	db	0xFF,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03	; DEA9
	db	0x03,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x0A,0x0A,0x0A,0x0A,0x0C,0x0C,0x0C	; DEB9
	db	0x0C,0x06,0x06,0x06,0x06,0x01,0x01,0x01,0x01,0x06,0x06,0x06,0x06,0x03,0x03,0x08	; DEC9
	db	0x08,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F	; DED9
	db	0x03,0x0D,0x01,0x0D,0x01,0x0D,0x01,0x0D,0x01,0x16,0x0A,0x16,0x0A,0x18,0x0C,0x18	; DEE9
	db	0x0C,0x12,0x06,0x12,0x06,0x0D,0x01,0x0D,0x01,0x12,0x06,0x12,0x06,0x0F,0x03,0x14	; DEF9
	db	0x08,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0xFE,0x01,0x01,0x01,0x0C,0x08,0x08	; DF09
	db	0x06,0x05,0x01,0x01,0x01,0x0C,0x08,0x08,0x06,0x05,0x05,0x05,0x05,0x10,0x0C,0x0C	; DF19
	db	0x0A,0x08,0x05,0x05,0x05,0x10,0x0C,0x0C,0x0A,0x08,0x0A,0x0A,0x0A,0x15,0x11,0x11	; DF29
	db	0x0F,0x0D,0x0A,0x0A,0x0A,0x15,0x11,0x11,0x0F,0x0D,0x06,0x06,0x06,0x11,0x0D,0x0D	; DF39
	db	0x0C,0x0A,0x06,0x06,0x06,0x11,0x0D,0x0D,0x0C,0x0A,0x03,0x03,0x03,0x0E,0x0A,0x0A	; DF49
	db	0x08,0x06,0x03,0x03,0x03,0x0E,0x0A,0x0A,0x08,0x06,0x08,0x08,0x08,0x13,0x0F,0x0D	; DF59
	db	0x0F,0x0D,0x08,0x08,0x08,0x13,0x0F,0x0F,0x0D,0x0C,0x08,0x08,0x08,0x13,0x08,0x08	; DF69
	db	0x08,0x13,0xFE,0x11,0x0D,0x11,0x0D,0x11,0x0D,0x11,0x08,0x11,0x0D,0x11,0x0D,0x0F	; DF79
	db	0x0D,0x0F,0x08,0x11,0x05,0x11,0x05,0x11,0x05,0x11,0x0C,0x11,0x05,0x11,0x05,0x14	; DF89
	db	0x05,0x14,0x0C,0x0D,0x0A,0x0D,0x0A,0x0D,0x0A,0x0D,0x05,0x0D,0x0A,0x0D,0x0A,0x0F	; DF99
	db	0x0A,0x11,0x05,0x12,0x06,0x12,0x06,0x12,0x06,0x12,0x0D,0x12,0x06,0x12,0x06,0x11	; DFA9
	db	0x06,0x11,0x0D,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x0A,0x0F,0x03,0x0F,0x03,0x16	; DFB9
	db	0x03,0x18,0x0A,0x19,0x08,0x19,0x08,0x19,0x08,0x19,0x0D,0x19,0x08,0x19,0x08,0x19	; DFC9
	db	0x08,0x19,0x0D,0x18,0x08,0x18,0x08,0x18,0x08,0x18,0x08,0xFE,0xFF,0xFE	; DFD9
MUS_TRACK_1:
	ld hl,D_DC6F+0xE2             ; DFE7  21 51 DD
	ld (D_DC6F+0x14),hl           ; DFEA  22 83 DC
	ld hl,D_DC6F+0x1C3            ; DFED  21 32 DE
	ld (D_DC6F+0x16),hl           ; DFF0  22 85 DC
	ld hl,0x0480                  ; DFF3  21 80 04
	ld (D_DC6F+0x12),hl           ; DFF6  22 81 DC
	ld hl,D_DC6F+0x56             ; DFF9  21 C5 DC
	ld (D_DC6F+0x10),hl           ; DFFC  22 7F DC
	ld a,0x0F                     ; DFFF  3E 0F
	ld (D_DC6F+0x4),a             ; E001  32 73 DC
	ld a,0x0E                     ; E004  3E 0E
	ld (D_DC6F+0x6),a             ; E006  32 75 DC
	jp MUS_START                  ; E009  C3 3A DB

D_E00C:			; данные E00C..E018 (13 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; E00C
MUS_TRACK_2:
	ld hl,D_DC6F+0x2A4            ; E019  21 13 DF
	ld (D_DC6F+0x14),hl           ; E01C  22 83 DC
	ld hl,D_DC6F+0x30D            ; E01F  21 7C DF
	ld (D_DC6F+0x16),hl           ; E022  22 85 DC
	ld hl,0x04FF                  ; E025  21 FF 04
	ld (D_DC6F+0x12),hl           ; E028  22 81 DC
	ld hl,D_DC6F+0x60             ; E02B  21 CF DC
	ld (D_DC6F+0x10),hl           ; E02E  22 7F DC
	ld a,0x0C                     ; E031  3E 0C
	ld (D_DC6F+0x4),a             ; E033  32 73 DC
	ld a,0x0F                     ; E036  3E 0F
	ld (D_DC6F+0x6),a             ; E038  32 75 DC
	jp MUS_START                  ; E03B  C3 3A DB

D_E03E:			; данные E03E..E04A (13 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; E03E
