; Spirits (Topo Soft, 1987), MSX — RESIDENT
; Дизасм ref/msx/SPIRITS.1.payload, собирается байт-в-байт: tools/verify_disasm.py
; Диапазон D100..E14A (4171 байт), entry D3F8
; Сдвиг +0x100 относительно оригинала (D000).
; Достижимый код 2746 байт, остальное — db (графика/таблицы).
;
; Абсолютные адреса вынесены в метки, чтобы переезд на другую раскладку
; делал ассемблер, а не пересчёт операндов скриптом.
; Абсолютных адресов 281: метками 253, стухших 28 (помечены в строке —
; символизировать их нельзя), не опознано 0. Относительных переходов 102.
; Разбор — docs/msx-relocation.md.
;
; Сгенерировано tools/disasm_msx.py — правки вносить туда или в tools/entries.json.
; Наложения (цель внутри предыдущей инструкции): D3F8

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
LOW_TILE_SRC:	equ	0x82F4
L_84F5:	equ	0x84F5
ROOM_MAPS:	equ	0x8547
SPR_DATA_A89C:	equ	0xA89C
SPR_DATA_AB76:	equ	0xAB76
HUD_TILES:	equ	0xB856
L_C034:	equ	0xC034
GAME_VARS:	equ	0xC2EA
L_C48C:	equ	0xC48C
L_C74A:	equ	0xC74A
L_C798:	equ	0xC798
L_CD5D:	equ	0xCD5D
L_CD9A:	equ	0xCD9A
L_CDA7:	equ	0xCDA7
D_CDC4:	equ	0xCDC4
L_CECD:	equ	0xCECD
L_CEF9:	equ	0xCEF9
L_CF36:	equ	0xCF36
SPR_BANK_E14B:	equ	0xE14B

	org	0xD100

D_D100:			; данные D100..D106 (7 байт)
	db	0x00,0x00,0xAF,0x00,0x00,0x00,0x01	; D100
L_D107:
	ld a,0xC9                     ; D107  3E C9
	ld (L_D7A9),a                 ; D109  32 A9 D7
	call L_C034                   ; D10C  CD 34 C0
	call L_D59B                   ; D10F  CD 9B D5
	call L_C74A                   ; D112  CD 4A C7
	ld a,0xCD                     ; D115  3E CD
	ld (L_D7A9),a                 ; D117  32 A9 D7
	ret                           ; D11A  C9

D_D11B:			; данные D11B..D120 (6 байт)
	db	0x02,0xD2,0x32,0x11,0xD3,0xC9	; D11B
L_D121:
	ld a,(D_D169)                 ; D121  3A 69 D1
	cpl                           ; D124  2F
	ld (D_D169),a                 ; D125  32 69 D1
	and a                         ; D128  A7
	jr z,L_D16A                   ; D129  28 3F
	ld hl,0x00                    ; D12B  21 00 00
	ld d,0x80                     ; D12E  16 80
L_D130:
	push hl                       ; D130  E5
	ld bc,0x0800                  ; D131  01 00 08
L_D134:
	res 3,h                       ; D134  CB 9C
	set 4,h                       ; D136  CB E4
	call VDP_RD_BYTE              ; D138  CD 20 D4
	and d                         ; D13B  A2
	ld e,a                        ; D13C  5F
	res 4,h                       ; D13D  CB A4
	set 3,h                       ; D13F  CB DC
	call VDP_RD_BYTE              ; D141  CD 20 D4
	xor e                         ; D144  AB
	call VDP_WR_BYTE              ; D145  CD 28 D4
	inc hl                        ; D148  23
	dec bc                        ; D149  0B
	ld a,b                        ; D14A  78
	or c                          ; D14B  B1
	jr nz,L_D134                  ; D14C  20 E6
	ld h,0x0A                     ; D14E  26 0A
L_D150:
	dec h                         ; D150  25
	jr nz,L_D150                  ; D151  20 FD
	nop                           ; D153  00
	nop                           ; D154  00
	pop hl                        ; D155  E1
	rr d                          ; D156  CB 1A
	jr nc,L_D130                  ; D158  30 D6
	ld hl,0x0800                  ; D15A  21 00 08
	call VDP_RD_BYTE              ; D15D  CD 20 D4
	ld bc,0x0800                  ; D160  01 00 08
	ld hl,0x1001                  ; D163  21 01 10
	jp VDP_FILL                   ; D166  C3 11 D4

D_D169:			; данные D169..D169 (1 байт)
	db	0xFF	; D169
L_D16A:
	ld hl,0x0800                  ; D16A  21 00 08
	ld b,0x08                     ; D16D  06 08
L_D16F:
	push bc                       ; D16F  C5
	ld b,0x08                     ; D170  06 08
L_D172:
	dec bc                        ; D172  0B
	ld a,b                        ; D173  78
	or c                          ; D174  B1
	jr nz,L_D172                  ; D175  20 FB
	push hl                       ; D177  E5
L_D178:
	res 3,h                       ; D178  CB 9C
	set 4,h                       ; D17A  CB E4
	call VDP_RD_BYTE              ; D17C  CD 20 D4
	res 4,h                       ; D17F  CB A4
	set 3,h                       ; D181  CB DC
	call VDP_WR_BYTE              ; D183  CD 28 D4
	ld de,0x08                    ; D186  11 08 00
	add hl,de                     ; D189  19
	djnz L_D178                   ; D18A  10 EC
	pop hl                        ; D18C  E1
	inc hl                        ; D18D  23
	pop bc                        ; D18E  C1
	djnz L_D16F                   ; D18F  10 DE
	ret                           ; D191  C9

SCR_ADDR_BIT13:
	ld a,c                        ; D192  79
	and 0xF8                      ; D193  E6 F8
	rrca                          ; D195  0F
	rrca                          ; D196  0F
	rrca                          ; D197  0F
	ld h,a                        ; D198  67
	ld a,b                        ; D199  78
	and 0xF8                      ; D19A  E6 F8
	ld l,a                        ; D19C  6F
	set 5,h                       ; D19D  CB EC
	ret                           ; D19F  C9

L_D1A0:
	ld (L_D1E2+0x1),a             ; D1A0  32 E3 D1
	and 0x7F                      ; D1A3  E6 7F
	ld (ix+0x08),a                ; D1A5  DD 77 08
	push bc                       ; D1A8  C5
	ld b,a                        ; D1A9  47
	add a,0x17                    ; D1AA  C6 17
	ld l,a                        ; D1AC  6F
	ld h,0xF3                     ; D1AD  26 F3
	ld a,(hl)                     ; D1AF  7E
	ld (L_D1DA+0x1),a             ; D1B0  32 DB D1
	call SPR_HDR                  ; D1B3  CD 44 D3
	ld (L_D1DF+0x1),hl            ; D1B6  22 E0 D1
	ld (ix+0x02),b                ; D1B9  DD 70 02
	ld c,a                        ; D1BC  4F
	ld (ix+0x03),c                ; D1BD  DD 71 03
	call L_D481                   ; D1C0  CD 81 D4
	ld a,b                        ; D1C3  78
	neg                           ; D1C4  ED 44
	pop bc                        ; D1C6  C1
	add a,c                       ; D1C7  81
	ld c,a                        ; D1C8  4F
	ld (ix+0x00),c                ; D1C9  DD 71 00
	ld (ix+0x01),b                ; D1CC  DD 70 01
	push bc                       ; D1CF  C5
	call SCR_ADDR_BIT14           ; D1D0  CD 70 D3
	ld (ix+0x04),l                ; D1D3  DD 75 04
	ld (ix+0x05),h                ; D1D6  DD 74 05
	pop bc                        ; D1D9  C1
L_D1DA:
	ld a,0x0C                     ; D1DA  3E 0C
	call L_D440                   ; D1DC  CD 40 D4
L_D1DF:
	ld hl,SPR_BANK_E14B+0x8D7     ; D1DF  21 22 EA
L_D1E2:
	ld a,0x16                     ; D1E2  3E 16
	and 0x80                      ; D1E4  E6 80
	call nz,L_D3CC                ; D1E6  C4 CC D3
	call L_D547                   ; D1E9  CD 47 D5
	ld bc,0x09                    ; D1EC  01 09 00
	add ix,bc                     ; D1EF  DD 09
	ret                           ; D1F1  C9

L_D1F2:
	ld ix,0xF229                  ; D1F2  DD 21 29 F2  ; СТУХШИЙ ОПЕРАНД, должно быть F329
	ld (ix-0x01),0xFF             ; D1F6  DD 36 FF FF
	ld (ix-0x03),0x00             ; D1FA  DD 36 FD 00
	ld (ix-0x02),0xF8             ; D1FE  DD 36 FE F8
	ld hl,0xF77E                  ; D202  21 7E F7  ; СТУХШИЙ ОПЕРАНД, должно быть F87E
	ld de,0xF77F                  ; D205  11 7F F7  ; СТУХШИЙ ОПЕРАНД, должно быть F87F
	ld bc,0x7F                    ; D208  01 7F 00
	ld (hl),0xD1                  ; D20B  36 D1
	ldir                          ; D20D  ED B0
	ld hl,0xF7FE                  ; D20F  21 FE F7  ; СТУХШИЙ ОПЕРАНД, должно быть F8FE
	ld de,0xF7FF                  ; D212  11 FF F7  ; СТУХШИЙ ОПЕРАНД, должно быть F8FF
	ld bc,0x07FF                  ; D215  01 FF 07
	ld (hl),0x00                  ; D218  36 00
	ldir                          ; D21A  ED B0
	jp L_D590                     ; D21C  C3 90 D5

	ld (0xF77E),hl                ; D21F  22 7E F7  ; СТУХШИЙ ОПЕРАНД, должно быть F87E
	ret                           ; D222  C9

D_D223:			; данные D223..D223 (1 байт)
	db	0x00	; D223
L_D224:
	ld a,(D_D223)                 ; D224  3A 23 D2
	and a                         ; D227  A7
	jp z,L_D764                   ; D228  CA 64 D7
	ld de,(D_D508+0xE)            ; D22B  ED 5B 16 D5
	ld hl,0xF7FE                  ; D22F  21 FE F7  ; СТУХШИЙ ОПЕРАНД, должно быть F8FE
	and a                         ; D232  A7
	sbc hl,de                     ; D233  ED 52
	srl l                         ; D235  CB 3D
	srl l                         ; D237  CB 3D
	ld b,l                        ; D239  45
	dec de                        ; D23A  1B
	ld hl,0xF7FD                  ; D23B  21 FD F7  ; СТУХШИЙ ОПЕРАНД, должно быть F8FD
	jp L_D755                     ; D23E  C3 55 D7

L_D241:
	push bc                       ; D241  C5
	dec c                         ; D242  0D
	sla c                         ; D243  CB 21
	sla c                         ; D245  CB 21
	sla c                         ; D247  CB 21
	ld b,0x00                     ; D249  06 00
	add hl,bc                     ; D24B  09
	pop bc                        ; D24C  C1
	nop                           ; D24D  00
L_D24E:
	push bc                       ; D24E  C5
	push hl                       ; D24F  E5
L_D250:
	push bc                       ; D250  C5
	call VDP_SET_WADDR            ; D251  CD 06 D4
	ld a,(de)                     ; D254  1A
	ld b,0x08                     ; D255  06 08
L_D257:
	rla                           ; D257  17
	rr c                          ; D258  CB 19
	djnz L_D257                   ; D25A  10 FB
	ld a,c                        ; D25C  79
	out (0x98),a                  ; D25D  D3 98
	inc de                        ; D25F  13
	ld bc,0xFFF8                  ; D260  01 F8 FF
	add hl,bc                     ; D263  09
	pop bc                        ; D264  C1
	dec c                         ; D265  0D
	jr nz,L_D250                  ; D266  20 E8
	pop hl                        ; D268  E1
	jp L_D534                     ; D269  C3 34 D5

L_D26C:
	ld hl,ROOM_MAPS-0x1           ; D26C  21 46 85
	ld b,0x00                     ; D26F  06 00
L_D271:
	and a                         ; D271  A7
	ret z                         ; D272  C8

	dec a                         ; D273  3D
	ld c,0x04                     ; D274  0E 04
	add hl,bc                     ; D276  09
	ld c,(hl)                     ; D277  4E
	inc hl                        ; D278  23
	inc hl                        ; D279  23
	add hl,bc                     ; D27A  09
	add hl,bc                     ; D27B  09
	add hl,bc                     ; D27C  09
	add hl,bc                     ; D27D  09
	jr L_D271                     ; D27E  18 F1

D_D280:			; данные D280..D283 (4 байт)
	db	0xC9,0x00,0x06,0x18	; D280
L_D284:
	xor a                         ; D284  AF
	bit 7,b                       ; D285  CB 78
	jr z,L_D28B                   ; D287  28 02
	ld a,0x60                     ; D289  3E 60
L_D28B:
	ld (L_D2A4+0x1),a             ; D28B  32 A5 D2
	ld a,b                        ; D28E  78
	and 0x7F                      ; D28F  E6 7F
	call L_D26C                   ; D291  CD 6C D2
	ld de,D_D508                  ; D294  11 08 D5
	ld bc,0x04                    ; D297  01 04 00
	ldir                          ; D29A  ED B0
	inc hl                        ; D29C  23
	ld b,(hl)                     ; D29D  46
	inc hl                        ; D29E  23
L_D29F:
	push bc                       ; D29F  C5
	ld a,(hl)                     ; D2A0  7E
	ex af,af'                     ; D2A1  08
	inc hl                        ; D2A2  23
	ld a,(hl)                     ; D2A3  7E
L_D2A4:
	add a,0x00                    ; D2A4  C6 00
	ld c,a                        ; D2A6  4F
	ex af,af'                     ; D2A7  08
	inc hl                        ; D2A8  23
	ld b,(hl)                     ; D2A9  46
	inc hl                        ; D2AA  23
	push bc                       ; D2AB  C5
	push hl                       ; D2AC  E5
	call L_D302                   ; D2AD  CD 02 D3
	pop hl                        ; D2B0  E1
	pop bc                        ; D2B1  C1
	ld a,(hl)                     ; D2B2  7E
	inc hl                        ; D2B3  23
	push hl                       ; D2B4  E5
	call L_D2BD                   ; D2B5  CD BD D2
	pop hl                        ; D2B8  E1
	pop bc                        ; D2B9  C1
	djnz L_D29F                   ; D2BA  10 E3
	ret                           ; D2BC  C9

L_D2BD:
	push af                       ; D2BD  F5
	call SCR_ADDR_BIT13           ; D2BE  CD 92 D1
	pop af                        ; D2C1  F1
L_D2C2:
	push hl                       ; D2C2  E5
	call L_D5B8                   ; D2C3  CD B8 D5
	cp 0x31                       ; D2C6  FE 31
	jr z,L_D2D2                   ; D2C8  28 08
	cp 0x51                       ; D2CA  FE 51
	jr c,L_D2D4                   ; D2CC  38 06
	cp 0x54                       ; D2CE  FE 54
	jr nc,L_D2D4                  ; D2D0  30 02
L_D2D2:
	ld (hl),0x20                  ; D2D2  36 20
L_D2D4:
	ld b,a                        ; D2D4  47
	call SPR_BANK_A89C            ; D2D5  CD 4C D3
	ld b,(hl)                     ; D2D8  46
	inc hl                        ; D2D9  23
	ld c,(hl)                     ; D2DA  4E
	inc hl                        ; D2DB  23
	ex de,hl                      ; D2DC  EB
	pop hl                        ; D2DD  E1
L_D2DE:
	push bc                       ; D2DE  C5
	push hl                       ; D2DF  E5
L_D2E0:
	push bc                       ; D2E0  C5
	call L_D5CF                   ; D2E1  CD CF D5
	ld a,(de)                     ; D2E4  1A
	ld bc,0x08                    ; D2E5  01 08 00
	call VDP_FILL                 ; D2E8  CD 11 D4
	ld a,0x08                     ; D2EB  3E 08
	add a,l                       ; D2ED  85
	ld l,a                        ; D2EE  6F
	inc de                        ; D2EF  13
	pop bc                        ; D2F0  C1
	dec c                         ; D2F1  0D
	jr nz,L_D2E0                  ; D2F2  20 EC
	pop hl                        ; D2F4  E1
	inc h                         ; D2F5  24
	pop bc                        ; D2F6  C1
	djnz L_D2DE                   ; D2F7  10 E5
	ret                           ; D2F9  C9

D_D2FA:			; данные D2FA..D301 (8 байт)
	db	0xE7,0xE1,0x24,0xC1,0x10,0xE0,0xC9,0xC9	; D2FA
L_D302:
	push af                       ; D302  F5
	call SCR_ADDR_BIT14           ; D303  CD 70 D3
	pop af                        ; D306  F1
	push af                       ; D307  F5
	and 0x7F                      ; D308  E6 7F
	push hl                       ; D30A  E5
	ld b,a                        ; D30B  47
	call SPR_BANK_VAR             ; D30C  CD 52 D3
	ld b,(hl)                     ; D30F  46
	inc hl                        ; D310  23
	ld c,(hl)                     ; D311  4E
	inc hl                        ; D312  23
	ex de,hl                      ; D313  EB
	pop hl                        ; D314  E1
	pop af                        ; D315  F1
	and 0x80                      ; D316  E6 80
	jp z,L_D241                   ; D318  CA 41 D2
	in a,(0x99)                   ; D31B  DB 99
VDP_WR_STRIDE8:
	push bc                       ; D31D  C5
	push hl                       ; D31E  E5
L_D31F:
	ld a,l                        ; D31F  7D
	out (0x99),a                  ; D320  D3 99
	ld a,h                        ; D322  7C
	push de                       ; D323  D5
	out (0x99),a                  ; D324  D3 99
	ld de,0x08                    ; D326  11 08 00
	add hl,de                     ; D329  19
	pop de                        ; D32A  D1
	ld a,(de)                     ; D32B  1A
	out (0x98),a                  ; D32C  D3 98
	inc de                        ; D32E  13
	dec c                         ; D32F  0D
	jr nz,L_D31F                  ; D330  20 ED
	pop hl                        ; D332  E1
	ld a,0x07                     ; D333  3E 07
	and l                         ; D335  A5
	cp 0x07                       ; D336  FE 07
	jr nz,L_D33F                  ; D338  20 05
	ld a,l                        ; D33A  7D
	sub 0x08                      ; D33B  D6 08
	ld l,a                        ; D33D  6F
	inc h                         ; D33E  24
L_D33F:
	inc l                         ; D33F  2C
	pop bc                        ; D340  C1
	djnz VDP_WR_STRIDE8           ; D341  10 DA
	ret                           ; D343  C9

SPR_HDR:
	call SPR_BANK_HI              ; D344  CD 58 D3
	ld b,(hl)                     ; D347  46
	inc hl                        ; D348  23
	ld a,(hl)                     ; D349  7E
	inc hl                        ; D34A  23
	ret                           ; D34B  C9

SPR_BANK_A89C:
	ld hl,SPR_DATA_A89C           ; D34C  21 9C A8
	xor a                         ; D34F  AF
	jr L_D35D                     ; D350  18 0B

SPR_BANK_VAR:
	ld hl,SPR_DATA_AB76           ; D352  21 76 AB
	xor a                         ; D355  AF
	jr L_D35D                     ; D356  18 05

SPR_BANK_HI:
	ld hl,SPR_BANK_E14B           ; D358  21 4B E1
	ld a,0x00                     ; D35B  3E 00
L_D35D:
	ld (L_D36A),a                 ; D35D  32 6A D3
	ld a,b                        ; D360  78
	ld d,0x00                     ; D361  16 00
L_D363:
	and a                         ; D363  A7
	ret z                         ; D364  C8

	dec a                         ; D365  3D
	ld e,(hl)                     ; D366  5E
	inc hl                        ; D367  23
	ld b,(hl)                     ; D368  46
	inc hl                        ; D369  23
L_D36A:
	nop                           ; D36A  00
	add hl,de                     ; D36B  19
	djnz L_D36A                   ; D36C  10 FC
	jr L_D363                     ; D36E  18 F3

SCR_ADDR_BIT14:
	ld a,c                        ; D370  79
	and 0xF8                      ; D371  E6 F8
	rrca                          ; D373  0F
	rrca                          ; D374  0F
	rrca                          ; D375  0F
	ld h,a                        ; D376  67
	ld a,b                        ; D377  78
	and 0xF8                      ; D378  E6 F8
	ld l,a                        ; D37A  6F
	ld a,c                        ; D37B  79
	and 0x07                      ; D37C  E6 07
	add a,l                       ; D37E  85
	ld l,a                        ; D37F  6F
	ld a,b                        ; D380  78
	and 0x07                      ; D381  E6 07
	ld b,a                        ; D383  47
	set 6,h                       ; D384  CB F4
	ret                           ; D386  C9

	ld hl,0xF34D                  ; D387  21 4D F3  ; СТУХШИЙ ОПЕРАНД, должно быть F44D
	ld de,0xF34D                  ; D38A  11 4D F3  ; СТУХШИЙ ОПЕРАНД, должно быть F44D
	jr L_D395                     ; D38D  18 06

D_D38F:			; данные D38F..D394 (6 байт)
	db	0x21,0x6D,0xF4,0x11,0x6D,0xF4	; D38F
L_D395:
	ld bc,0x0120                  ; D395  01 20 01
	jr L_D3A3                     ; D398  18 09

D_D39A:			; данные D39A..D3A2 (9 байт)
	db	0x21,0x4D,0xF3,0x11,0x4D,0xF3,0x01,0x40,0x02	; D39A
L_D3A3:
	ldir                          ; D3A3  ED B0
	ret                           ; D3A5  C9

	ld e,(ix-0x03)                ; D3A6  DD 5E FD
	ld d,(ix-0x02)                ; D3A9  DD 56 FE
	ld a,(0xD420)                 ; D3AC  3A 20 D4  ; СТУХШИЙ ОПЕРАНД, должно быть D520
	ld b,a                        ; D3AF  47
	ld a,(0xD418)                 ; D3B0  3A 18 D4  ; СТУХШИЙ ОПЕРАНД, должно быть D518
	ld c,a                        ; D3B3  4F
L_D3B4:
	push bc                       ; D3B4  C5
	push de                       ; D3B5  D5
	ld b,0x00                     ; D3B6  06 00
	ldir                          ; D3B8  ED B0
	pop de                        ; D3BA  D1
	push hl                       ; D3BB  E5
	ld hl,(0xD41A)                ; D3BC  2A 1A D4  ; СТУХШИЙ ОПЕРАНД, должно быть D51A
	add hl,de                     ; D3BF  19
	ex de,hl                      ; D3C0  EB
	pop hl                        ; D3C1  E1
	pop bc                        ; D3C2  C1
	djnz L_D3B4                   ; D3C3  10 EF
	ld (ix+0x06),e                ; D3C5  DD 73 06
	ld (ix+0x07),d                ; D3C8  DD 72 07
	ret                           ; D3CB  C9

L_D3CC:
	ld b,(ix+0x02)                ; D3CC  DD 46 02
	ld a,(ix+0x03)                ; D3CF  DD 7E 03
	ld (L_D3E3+0x1),a             ; D3D2  32 E4 D3
	ld e,a                        ; D3D5  5F
	rlca                          ; D3D6  07
	ld (L_D3F1+0x1),a             ; D3D7  32 F2 D3
	dec e                         ; D3DA  1D
	ld d,0x00                     ; D3DB  16 00
	add hl,de                     ; D3DD  19
	ld de,0xF1A9                  ; D3DE  11 A9 F1  ; СТУХШИЙ ОПЕРАНД, должно быть F2A9
	ld c,b                        ; D3E1  48
L_D3E2:
	nop                           ; D3E2  00
L_D3E3:
	ld b,0x03                     ; D3E3  06 03
L_D3E5:
	push bc                       ; D3E5  C5
	ld c,(hl)                     ; D3E6  4E
	ld b,0xD5                     ; D3E7  06 D5
	ld a,(bc)                     ; D3E9  0A
	ld (de),a                     ; D3EA  12
	pop bc                        ; D3EB  C1
	inc de                        ; D3EC  13
	dec hl                        ; D3ED  2B
	djnz L_D3E5                   ; D3EE  10 F5
	push bc                       ; D3F0  C5
L_D3F1:
	ld bc,0x06                    ; D3F1  01 06 00
	add hl,bc                     ; D3F4  09
	pop bc                        ; D3F5  C1
	dec c                         ; D3F6  0D
	jr nz,L_D3E2                  ; D3F7  20 E9
	ld hl,0xF1A9                  ; D3F9  21 A9 F1  ; СТУХШИЙ ОПЕРАНД, должно быть F2A9
	ret                           ; D3FC  C9

VDP_SET_RADDR:
	ld a,l                        ; D3FD  7D
	out (0x99),a                  ; D3FE  D3 99
	ld a,h                        ; D400  7C
	and 0x3F                      ; D401  E6 3F
	out (0x99),a                  ; D403  D3 99
	ret                           ; D405  C9

VDP_SET_WADDR:
	ld a,l                        ; D406  7D
	out (0x99),a                  ; D407  D3 99
	ld a,h                        ; D409  7C
	and 0x3F                      ; D40A  E6 3F
L_D40C:
	or 0x40                       ; D40C  F6 40
	out (0x99),a                  ; D40E  D3 99
	ret                           ; D410  C9

VDP_FILL:
	push af                       ; D411  F5
	call VDP_SET_WADDR            ; D412  CD 06 D4
L_D415:
	pop af                        ; D415  F1
	out (0x98),a                  ; D416  D3 98
	push af                       ; D418  F5
	dec bc                        ; D419  0B
	ld a,c                        ; D41A  79
	or b                          ; D41B  B0
	jr nz,L_D415                  ; D41C  20 F7
	pop af                        ; D41E  F1
	ret                           ; D41F  C9

VDP_RD_BYTE:
	call VDP_SET_RADDR            ; D420  CD FD D3
	ex (sp),hl                    ; D423  E3
	ex (sp),hl                    ; D424  E3
	in a,(0x98)                   ; D425  DB 98
	ret                           ; D427  C9

VDP_WR_BYTE:
	push af                       ; D428  F5
	call VDP_SET_WADDR            ; D429  CD 06 D4
	ex (sp),hl                    ; D42C  E3
	ex (sp),hl                    ; D42D  E3
	pop af                        ; D42E  F1
	out (0x98),a                  ; D42F  D3 98
	ret                           ; D431  C9

L_D432:
	ex de,hl                      ; D432  EB
VDP_COPY_TO_VRAM:
	call VDP_SET_WADDR            ; D433  CD 06 D4
L_D436:
	ld a,(de)                     ; D436  1A
	out (0x98),a                  ; D437  D3 98
	inc de                        ; D439  13
	dec bc                        ; D43A  0B
	ld a,c                        ; D43B  79
	or b                          ; D43C  B0
	jr nz,L_D436                  ; D43D  20 F7
	ret                           ; D43F  C9

L_D440:
	ld (L_D472+0x1),a             ; D440  32 73 D4
	push bc                       ; D443  C5
	ld hl,(D_D508+0xE)            ; D444  2A 16 D5
	ld a,(D_D508+0x22)            ; D447  3A 2A D5
	rlca                          ; D44A  07
	rlca                          ; D44B  07
	ld e,a                        ; D44C  5F
	ld d,0x00                     ; D44D  16 00
	and a                         ; D44F  A7
	sbc hl,de                     ; D450  ED 52
	ld (D_D508+0xE),hl            ; D452  22 16 D5
	ld a,(D_D508+0x16)            ; D455  3A 1E D5
	ld b,a                        ; D458  47
	ld a,(D_D508+0x18)            ; D459  3A 20 D5
	ld c,a                        ; D45C  4F
	pop de                        ; D45D  D1
L_D45E:
	push bc                       ; D45E  C5
	push de                       ; D45F  D5
L_D460:
	ld (hl),e                     ; D460  73
	inc hl                        ; D461  23
	ld (hl),d                     ; D462  72
	ld a,0x10                     ; D463  3E 10
	add a,d                       ; D465  82
	ld d,a                        ; D466  57
	inc hl                        ; D467  23
	ld a,(D_D508+0x14)            ; D468  3A 1C D5
	ld (hl),a                     ; D46B  77
	add a,0x04                    ; D46C  C6 04
	ld (D_D508+0x14),a            ; D46E  32 1C D5
	inc hl                        ; D471  23
L_D472:
	ld (hl),0x0C                  ; D472  36 0C
	inc hl                        ; D474  23
	djnz L_D460                   ; D475  10 E9
	pop de                        ; D477  D1
	ld a,0x10                     ; D478  3E 10
	add a,e                       ; D47A  83
	ld e,a                        ; D47B  5F
	pop bc                        ; D47C  C1
	dec c                         ; D47D  0D
	jr nz,L_D45E                  ; D47E  20 DE
	ret                           ; D480  C9

L_D481:
	push bc                       ; D481  C5
	srl c                         ; D482  CB 39
	jr nc,L_D487                  ; D484  30 01
	inc c                         ; D486  0C
L_D487:
	ld a,c                        ; D487  79
	ld (D_D508+0x16),a            ; D488  32 1E D5
	ld a,b                        ; D48B  78
	srl b                         ; D48C  CB 38
	srl b                         ; D48E  CB 38
	srl b                         ; D490  CB 38
	srl b                         ; D492  CB 38
	and 0x0F                      ; D494  E6 0F
	jr z,L_D499                   ; D496  28 01
	inc b                         ; D498  04
L_D499:
	ld a,b                        ; D499  78
	ld (D_D508+0x18),a            ; D49A  32 20 D5
	xor a                         ; D49D  AF
L_D49E:
	add a,c                       ; D49E  81
	djnz L_D49E                   ; D49F  10 FD
	ld (D_D508+0x22),a            ; D4A1  32 2A D5
	ld b,c                        ; D4A4  41
	xor a                         ; D4A5  AF
L_D4A6:
	add a,0x20                    ; D4A6  C6 20
	djnz L_D4A6                   ; D4A8  10 FC
	ld (D_D508+0x12),a            ; D4AA  32 1A D5
	pop bc                        ; D4AD  C1
	ret                           ; D4AE  C9

D_D4AF:			; данные D4AF..D4B3 (5 байт)
	db	0x07,0x32,0x18,0xD4,0xC9	; D4AF
VDP_RD_STRIDE8:
	res 6,h                       ; D4B4  CB B4
L_D4B6:
	push bc                       ; D4B6  C5
	push hl                       ; D4B7  E5
L_D4B8:
	ld a,l                        ; D4B8  7D
	out (0x99),a                  ; D4B9  D3 99
	ld a,h                        ; D4BB  7C
	push de                       ; D4BC  D5
	out (0x99),a                  ; D4BD  D3 99
	ld de,0x08                    ; D4BF  11 08 00
	add hl,de                     ; D4C2  19
	pop de                        ; D4C3  D1
	ex (sp),hl                    ; D4C4  E3
	ex (sp),hl                    ; D4C5  E3
	in a,(0x98)                   ; D4C6  DB 98
	ld (de),a                     ; D4C8  12
	inc de                        ; D4C9  13
	dec c                         ; D4CA  0D
	jr nz,L_D4B8                  ; D4CB  20 EB
	pop hl                        ; D4CD  E1
	ld a,0x07                     ; D4CE  3E 07
	and l                         ; D4D0  A5
	cp 0x07                       ; D4D1  FE 07
	jr nz,L_D4DA                  ; D4D3  20 05
	ld a,l                        ; D4D5  7D
	sub 0x08                      ; D4D6  D6 08
	ld l,a                        ; D4D8  6F
	inc h                         ; D4D9  24
L_D4DA:
	inc l                         ; D4DA  2C
	pop bc                        ; D4DB  C1
	djnz L_D4B6                   ; D4DC  10 D8
	ret                           ; D4DE  C9

KBD_SCAN:
	push bc                       ; D4DF  C5
	ld a,c                        ; D4E0  79
	and 0x07                      ; D4E1  E6 07
	inc a                         ; D4E3  3C
	ld b,a                        ; D4E4  47
	ld a,c                        ; D4E5  79
	and 0xF0                      ; D4E6  E6 F0
	rrca                          ; D4E8  0F
	rrca                          ; D4E9  0F
	rrca                          ; D4EA  0F
	rrca                          ; D4EB  0F
	or 0xF0                       ; D4EC  F6 F0
	out (0xAA),a                  ; D4EE  D3 AA
	nop                           ; D4F0  00
	in a,(0xA9)                   ; D4F1  DB A9
	cpl                           ; D4F3  2F
L_D4F4:
	rrca                          ; D4F4  0F
	djnz L_D4F4                   ; D4F5  10 FD
	pop bc                        ; D4F7  C1
RET_STUB:
	ret                           ; D4F8  C9

D_D4F9:			; данные D4F9..D4FD (5 байт)
	db	0xC9,0x48,0x09,0xD6,0x08	; D4F9
THUNK_CDC5_D00:
	ld d,0x00                     ; D4FE  16 00
	jp D_CDC4+0x1                 ; D500  C3 C5 CD

THUNK_CDC5_D60:
	ld d,0x60                     ; D503  16 60
	jp D_CDC4+0x1                 ; D505  C3 C5 CD

D_D508:			; данные D508..D533 (44 байт)
	db	0x11,0x1B,0x15,0x17,0x11,0x50,0x70,0xB1,0x11,0x50,0x80,0xB1,0xF8,0xD3,0xE2,0xF7	; D508
	db	0x30,0x02,0x20,0x27,0x1C,0x38,0x01,0xC9,0x02,0xA7,0x10,0x50,0x90,0xD0,0x30,0x70	; D518
	db	0xB0,0xE0,0x02,0xD1,0x01,0x05,0x08,0x0D,0x02,0x07,0x11,0x0E	; D528
L_D534:
	ld a,0x07                     ; D534  3E 07
	and l                         ; D536  A5
	cp 0x07                       ; D537  FE 07
	jr nz,L_D540                  ; D539  20 05
	ld a,l                        ; D53B  7D
	sub 0x08                      ; D53C  D6 08
	ld l,a                        ; D53E  6F
	inc h                         ; D53F  24
L_D540:
	inc l                         ; D540  2C
	pop bc                        ; D541  C1
	dec b                         ; D542  05
	jp nz,L_D24E                  ; D543  C2 4E D2
	ret                           ; D546  C9

L_D547:
	ex de,hl                      ; D547  EB
	ld a,(D_D508+0x12)            ; D548  3A 1A D5
	ld c,a                        ; D54B  4F
	sub 0x10                      ; D54C  D6 10
	ld (L_D586+0x1),a             ; D54E  32 87 D5
	ld l,(ix-0x03)                ; D551  DD 6E FD
	ld h,(ix-0x02)                ; D554  DD 66 FE
	push hl                       ; D557  E5
	ld a,(D_D508+0x18)            ; D558  3A 20 D5
	ld b,a                        ; D55B  47
	xor a                         ; D55C  AF
L_D55D:
	add a,c                       ; D55D  81
	djnz L_D55D                   ; D55E  10 FD
	ld c,a                        ; D560  4F
	ld b,0x00                     ; D561  06 00
	add hl,bc                     ; D563  09
	ld (ix+0x06),l                ; D564  DD 75 06
	ld (ix+0x07),h                ; D567  DD 74 07
	pop hl                        ; D56A  E1
	ld c,(ix+0x02)                ; D56B  DD 4E 02
	ld b,(ix+0x03)                ; D56E  DD 46 03
L_D571:
	push bc                       ; D571  C5
	push hl                       ; D572  E5
L_D573:
	ld a,(de)                     ; D573  1A
	ld (hl),a                     ; D574  77
	inc de                        ; D575  13
	push bc                       ; D576  C5
	ld bc,0x10                    ; D577  01 10 00
	add hl,bc                     ; D57A  09
	pop bc                        ; D57B  C1
	djnz L_D573                   ; D57C  10 F5
	pop hl                        ; D57E  E1
	ld a,0x0F                     ; D57F  3E 0F
	and l                         ; D581  A5
	cp 0x0F                       ; D582  FE 0F
	jr nz,L_D58A                  ; D584  20 04
L_D586:
	ld bc,0x10                    ; D586  01 10 00
	add hl,bc                     ; D589  09
L_D58A:
	inc hl                        ; D58A  23
	pop bc                        ; D58B  C1
	dec c                         ; D58C  0D
	jr nz,L_D571                  ; D58D  20 E2
	ret                           ; D58F  C9

L_D590:
	ld hl,0xF7FE                  ; D590  21 FE F7  ; СТУХШИЙ ОПЕРАНД, должно быть F8FE
	ld (D_D508+0xE),hl            ; D593  22 16 D5
	xor a                         ; D596  AF
	ld (D_D508+0x14),a            ; D597  32 1C D5
	ret                           ; D59A  C9

L_D59B:
	ld hl,0xF34D                  ; D59B  21 4D F3  ; СТУХШИЙ ОПЕРАНД, должно быть F44D
	ld de,0xF34E                  ; D59E  11 4E F3  ; СТУХШИЙ ОПЕРАНД, должно быть F44E
	ld bc,0x0120                  ; D5A1  01 20 01
	ld (hl),0x00                  ; D5A4  36 00
	ldir                          ; D5A6  ED B0
	ret                           ; D5A8  C9

L_D5A9:
	ld hl,0xF46D                  ; D5A9  21 6D F4  ; СТУХШИЙ ОПЕРАНД, должно быть F56D
	ld de,0xF46E                  ; D5AC  11 6E F4  ; СТУХШИЙ ОПЕРАНД, должно быть F56E
	ld bc,0x0120                  ; D5AF  01 20 01
	ld (hl),0x00                  ; D5B2  36 00
	ldir                          ; D5B4  ED B0
	ret                           ; D5B6  C9

D_D5B7:			; данные D5B7..D5B7 (1 байт)
	db	0xBD	; D5B7
L_D5B8:
	ld hl,L_D5EC+0x1              ; D5B8  21 ED D5
	ld (hl),0x00                  ; D5BB  36 00
	cp 0x55                       ; D5BD  FE 55
	ret c                         ; D5BF  D8

	sub 0x55                      ; D5C0  D6 55
	ld (hl),0x40                  ; D5C2  36 40
	cp 0x55                       ; D5C4  FE 55
	ret c                         ; D5C6  D8

	sub 0x55                      ; D5C7  D6 55
	ld (hl),0x80                  ; D5C9  36 80
	ret                           ; D5CB  C9

D_D5CC:			; данные D5CC..D5CE (3 байт)
	db	0x0A,0xC1,0xB0	; D5CC
L_D5CF:
	push hl                       ; D5CF  E5
	srl l                         ; D5D0  CB 3D
	srl l                         ; D5D2  CB 3D
	srl l                         ; D5D4  CB 3D
	ld a,l                        ; D5D6  7D
	sla h                         ; D5D7  CB 24
	sla h                         ; D5D9  CB 24
	sla h                         ; D5DB  CB 24
	ld l,h                        ; D5DD  6C
	ld h,0x00                     ; D5DE  26 00
	ld c,l                        ; D5E0  4D
	ld b,h                        ; D5E1  44
	add hl,hl                     ; D5E2  29
	add hl,bc                     ; D5E3  09
	ld c,a                        ; D5E4  4F
	ld b,0x00                     ; D5E5  06 00
	add hl,bc                     ; D5E7  09
	ld bc,0xF34D                  ; D5E8  01 4D F3  ; СТУХШИЙ ОПЕРАНД, должно быть F44D
	add hl,bc                     ; D5EB  09
L_D5EC:
	ld a,0x00                     ; D5EC  3E 00
	ld (hl),a                     ; D5EE  77
	pop hl                        ; D5EF  E1
	ret                           ; D5F0  C9

L_D5F1:
	call L_D59B                   ; D5F1  CD 9B D5
	jp L_CD9A                     ; D5F4  C3 9A CD

L_D5F7:
	call L_D5A9                   ; D5F7  CD A9 D5
	jp L_CDA7                     ; D5FA  C3 A7 CD

D_D5FD:			; данные D5FD..D6FF (259 байт)
	db	0xFF,0xF7,0xFF,0x00,0x80,0x40,0xC0,0x20,0xA0,0x60,0xE0,0x10,0x90,0x50,0xD0,0x30	; D5FD
	db	0xB0,0x70,0xF0,0x08,0x88,0x48,0xC8,0x28,0xA8,0x68,0xE8,0x18,0x98,0x58,0xD8,0x38	; D60D
	db	0xB8,0x78,0xF8,0x04,0x84,0x44,0xC4,0x24,0xA4,0x64,0xE4,0x14,0x94,0x54,0xD4,0x34	; D61D
	db	0xB4,0x74,0xF4,0x0C,0x8C,0x4C,0xCC,0x2C,0xAC,0x6C,0xEC,0x1C,0x9C,0x5C,0xDC,0x3C	; D62D
	db	0xBC,0x7C,0xFC,0x02,0x82,0x42,0xC2,0x22,0xA2,0x62,0xE2,0x12,0x92,0x52,0xD2,0x32	; D63D
	db	0xB2,0x72,0xF2,0x0A,0x8A,0x4A,0xCA,0x2A,0xAA,0x6A,0xEA,0x1A,0x9A,0x5A,0xDA,0x3A	; D64D
	db	0xBA,0x7A,0xFA,0x06,0x86,0x46,0xC6,0x26,0xA6,0x66,0xE6,0x16,0x96,0x56,0xD6,0x36	; D65D
	db	0xB6,0x76,0xF6,0x0E,0x8E,0x4E,0xCE,0x2E,0xAE,0x6E,0xEE,0x1E,0x9E,0x5E,0xDE,0x3E	; D66D
	db	0xBE,0x7E,0xFE,0x01,0x81,0x41,0xC1,0x21,0xA1,0x61,0xE1,0x11,0x91,0x51,0xD1,0x31	; D67D
	db	0xB1,0x71,0xF1,0x09,0x89,0x49,0xC9,0x29,0xA9,0x69,0xE9,0x19,0x99,0x59,0xD9,0x39	; D68D
	db	0xB9,0x79,0xF9,0x05,0x85,0x45,0xC5,0x25,0xA5,0x65,0xE5,0x15,0x95,0x55,0xD5,0x35	; D69D
	db	0xB5,0x75,0xF5,0x0D,0x8D,0x4D,0xCD,0x2D,0xAD,0x6D,0xED,0x1D,0x9D,0x5D,0xDD,0x3D	; D6AD
	db	0xBD,0x7D,0xFD,0x03,0x83,0x43,0xC3,0x23,0xA3,0x63,0xE3,0x13,0x93,0x53,0xD3,0x33	; D6BD
	db	0xB3,0x73,0xF3,0x0B,0x8B,0x4B,0xCB,0x2B,0xAB,0x6B,0xEB,0x1B,0x9B,0x5B,0xDB,0x3B	; D6CD
	db	0xBB,0x7B,0xFB,0x07,0x87,0x47,0xC7,0x27,0xA7,0x67,0xE7,0x17,0x97,0x57,0xD7,0x37	; D6DD
	db	0xB7,0x77,0xF7,0x0F,0x8F,0x4F,0xCF,0x2F,0xAF,0x6F,0xEF,0x1F,0x9F,0x5F,0xDF,0x3F	; D6ED
	db	0xBF,0x7F,0xFF	; D6FD
ATTR_ADDR:
	ld a,c                        ; D700  79
	and 0xF8                      ; D701  E6 F8
	ld c,a                        ; D703  4F
	ld a,b                        ; D704  78
	and 0xF8                      ; D705  E6 F8
	rra                           ; D707  1F
	rra                           ; D708  1F
	rra                           ; D709  1F
	ld l,c                        ; D70A  69
	ld h,0x00                     ; D70B  26 00
	ld b,h                        ; D70D  44
	add hl,hl                     ; D70E  29
	add hl,bc                     ; D70F  09
	ld bc,0xF34D                  ; D710  01 4D F3  ; СТУХШИЙ ОПЕРАНД, должно быть F44D
	add hl,bc                     ; D713  09
	ld c,a                        ; D714  4F
	ld b,0x00                     ; D715  06 00
	add hl,bc                     ; D717  09
	ret                           ; D718  C9

L_D719:
	ld b,0x20                     ; D719  06 20
	ld hl,0x5B00                  ; D71B  21 00 5B
L_D71E:
	call VDP_RD_BYTE              ; D71E  CD 20 D4
	cp 0x60                       ; D721  FE 60
	jr nc,L_D72A                  ; D723  30 05
	ld a,0xD1                     ; D725  3E D1
	call VDP_WR_BYTE              ; D727  CD 28 D4
L_D72A:
	ld a,0x04                     ; D72A  3E 04
	add a,l                       ; D72C  85
	ld l,a                        ; D72D  6F
	djnz L_D71E                   ; D72E  10 EE
	jp L_C48C                     ; D730  C3 8C C4

D_D733:			; данные D733..D735 (3 байт)
	db	0xFF,0xFF,0xFF	; D733
L_D736:
	xor a                         ; D736  AF
	sbc hl,de                     ; D737  ED 52
	ld b,l                        ; D739  45
L_D73A:
	ld (de),a                     ; D73A  12
	inc de                        ; D73B  13
	djnz L_D73A                   ; D73C  10 FC
	ret                           ; D73E  C9

L_D73F:
	push hl                       ; D73F  E5
	push de                       ; D740  D5
	push bc                       ; D741  C5
	ld hl,0xF58D                  ; D742  21 8D F5  ; СТУХШИЙ ОПЕРАНД, должно быть F68D
	ld de,0xF58E                  ; D745  11 8E F5  ; СТУХШИЙ ОПЕРАНД, должно быть F68E
	ld bc,0x01F0                  ; D748  01 F0 01
	ld (hl),0x00                  ; D74B  36 00
	ldir                          ; D74D  ED B0
	pop bc                        ; D74F  C1
	pop de                        ; D750  D1
	pop hl                        ; D751  E1
	jp L_C798                     ; D752  C3 98 C7

L_D755:
	push bc                       ; D755  C5
	ld bc,0x03                    ; D756  01 03 00
	lddr                          ; D759  ED B8
	ld a,(hl)                     ; D75B  7E
	add a,0x60                    ; D75C  C6 60
	ld (de),a                     ; D75E  12
	dec de                        ; D75F  1B
	dec hl                        ; D760  2B
	pop bc                        ; D761  C1
	djnz L_D755                   ; D762  10 F1
L_D764:
	ld hl,0xF77E                  ; D764  21 7E F7  ; СТУХШИЙ ОПЕРАНД, должно быть F87E
	ld de,0x1B00                  ; D767  11 00 1B
	ld bc,0x80                    ; D76A  01 80 00
	call L_D432                   ; D76D  CD 32 D4
	ld hl,0xF800                  ; D770  21 00 F8  ; СТУХШИЙ ОПЕРАНД, должно быть F900
	ld de,0x3800                  ; D773  11 00 38
	ld bc,0x0800                  ; D776  01 00 08
	call L_D432                   ; D779  CD 32 D4
	ld ix,0xF229                  ; D77C  DD 21 29 F2  ; СТУХШИЙ ОПЕРАНД, должно быть F329
	jp L_DA8E                     ; D780  C3 8E DA

D_D783:			; данные D783..D783 (1 байт)
	db	0xC9	; D783
KBD_CHK_F3B5:
	ld a,0xF3                     ; D784  3E F3
	out (0xAA),a                  ; D786  D3 AA
	in a,(0xA9)                   ; D788  DB A9
	bit 5,a                       ; D78A  CB 6F
	ret nz                        ; D78C  C0

	jp L_CD5D                     ; D78D  C3 5D CD

D_D790:			; данные D790..D791 (2 байт)
	db	0x70,0x45	; D790
L_D792:
	ld a,(GAME_VARS+0xA)          ; D792  3A F4 C2
	cp 0x61                       ; D795  FE 61
	ret nc                        ; D797  D0

	ld bc,(GAME_VARS+0xA)         ; D798  ED 4B F4 C2
	jp L_D7A9                     ; D79C  C3 A9 D7

L_D79F:
	ld a,(GAME_VARS+0xA)          ; D79F  3A F4 C2
	cp 0x60                       ; D7A2  FE 60
	ret c                         ; D7A4  D8

	ld bc,(GAME_VARS+0xA)         ; D7A5  ED 4B F4 C2
L_D7A9:
	call SCR_ADDR_BIT14           ; D7A9  CD 70 D3
	ld a,l                        ; D7AC  7D
	and 0xF8                      ; D7AD  E6 F8
	ld l,a                        ; D7AF  6F
	ld de,0x0500                  ; D7B0  11 00 05
	sbc hl,de                     ; D7B3  ED 52
	ld (D_D790),hl                ; D7B5  22 90 D7
	ld de,0x08                    ; D7B8  11 08 00
	and a                         ; D7BB  A7
	sbc hl,de                     ; D7BC  ED 52
	push hl                       ; D7BE  E5
	ld de,0x8030                  ; D7BF  11 30 80
	ld b,0x06                     ; D7C2  06 06
L_D7C4:
	ld c,0x30                     ; D7C4  0E 30
	push hl                       ; D7C6  E5
	call VDP_SET_RADDR            ; D7C7  CD FD D3
L_D7CA:
	and a                         ; D7CA  A7
	in a,(0x98)                   ; D7CB  DB 98
	ld (de),a                     ; D7CD  12
	inc de                        ; D7CE  13
	dec c                         ; D7CF  0D
	jr nz,L_D7CA                  ; D7D0  20 F8
	pop hl                        ; D7D2  E1
	inc h                         ; D7D3  24
	djnz L_D7C4                   ; D7D4  10 EE
	pop hl                        ; D7D6  E1
	jp L_DAAA                     ; D7D7  C3 AA DA

SFX_64D7:
	push hl                       ; D7DA  E5
	push bc                       ; D7DB  C5
	ld hl,P1_SFX_64D7             ; D7DC  21 D7 64
	call L_84F5                   ; D7DF  CD F5 84
	pop bc                        ; D7E2  C1
	pop hl                        ; D7E3  E1
	ret                           ; D7E4  C9

SFX_64E6:
	ld hl,P1_SFX_64E6             ; D7E5  21 E6 64
	jp L_84F5                     ; D7E8  C3 F5 84

D_D7EB:			; данные D7EB..D7F1 (7 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00	; D7EB
SFX_64D7_x25:
	ld b,0x19                     ; D7F2  06 19
L_D7F4:
	push bc                       ; D7F4  C5
	ld hl,P1_SFX_64D7             ; D7F5  21 D7 64
	call L_84F5                   ; D7F8  CD F5 84
	ld hl,0x1388                  ; D7FB  21 88 13
L_D7FE:
	dec hl                        ; D7FE  2B
	ld a,h                        ; D7FF  7C
	or l                          ; D800  B5
	jr nz,L_D7FE                  ; D801  20 FB
	pop bc                        ; D803  C1
	djnz L_D7F4                   ; D804  10 EE
	jp SFX_64F5                   ; D806  C3 9A D8

D_D809:			; данные D809..D80C (4 байт)
	db	0x00,0x00,0x08,0x00	; D809
L_D80D:
	ld a,0xD0                     ; D80D  3E D0
	ld (L_DB89+0x1),a             ; D80F  32 8A DB
	ld de,0x8180                  ; D812  11 80 81
	ld a,l                        ; D815  7D
	ld c,0x20                     ; D816  0E 20
	cp 0xA0                       ; D818  FE A0
	jr z,L_D838                   ; D81A  28 1C
	ld c,0x28                     ; D81C  0E 28
	cp 0x98                       ; D81E  FE 98
	jr z,L_D838                   ; D820  28 16
	cp 0xF8                       ; D822  FE F8
	jr nz,L_D836                  ; D824  20 10
	ld a,0xD1                     ; D826  3E D1
	ld (L_DB89+0x1),a             ; D828  32 8A DB
	ld l,0x00                     ; D82B  2E 00
	inc h                         ; D82D  24
	ld a,e                        ; D82E  7B
	add a,0x08                    ; D82F  C6 08
	ld e,a                        ; D831  5F
	ld c,0x28                     ; D832  0E 28
	jr L_D838                     ; D834  18 02

L_D836:
	ld c,0x30                     ; D836  0E 30
L_D838:
	ld a,c                        ; D838  79
	ld (L_DB62+0x1),a             ; D839  32 63 DB
	srl a                         ; D83C  CB 3F
	srl a                         ; D83E  CB 3F
	srl a                         ; D840  CB 3F
	ld (L_DBA6+0x1),a             ; D842  32 A7 DB
	jp L_DB56                     ; D845  C3 56 DB

D_D848:			; данные D848..D848 (1 байт)
	db	0xDA	; D848
L_D849:
	ld b,0x06                     ; D849  06 06
L_D84B:
	ld c,0x08                     ; D84B  0E 08
	call VDP_SET_RADDR            ; D84D  CD FD D3
L_D850:
	and a                         ; D850  A7
	in a,(0x98)                   ; D851  DB 98
	ld (de),a                     ; D853  12
	inc de                        ; D854  13
	nop                           ; D855  00
	nop                           ; D856  00
	dec c                         ; D857  0D
	jr nz,L_D850                  ; D858  20 F6
	push hl                       ; D85A  E5
	ld hl,0x28                    ; D85B  21 28 00
	add hl,de                     ; D85E  19
	ex de,hl                      ; D85F  EB
	pop hl                        ; D860  E1
	inc h                         ; D861  24
	djnz L_D84B                   ; D862  10 E7
	ret                           ; D864  C9

D_D865:			; данные D865..D86D (9 байт)
	db	0x42,0x00,0x86,0x00,0x82,0x00,0x06,0x00,0x46	; D865
L_D86E:
	ld c,0x30                     ; D86E  0E 30
	call VDP_SET_RADDR            ; D870  CD FD D3
L_D873:
	and a                         ; D873  A7
	in a,(0x98)                   ; D874  DB 98
	ld (de),a                     ; D876  12
	inc de                        ; D877  13
	nop                           ; D878  00
	nop                           ; D879  00
	dec c                         ; D87A  0D
	jr nz,L_D873                  ; D87B  20 F6
	ret                           ; D87D  C9

L_D87E:
	ld a,(GAME_VARS+0x7)          ; D87E  3A F1 C2
	cp 0x01                       ; D881  FE 01
	jr z,SFX_64AA                 ; D883  28 09
	cp 0x04                       ; D885  FE 04
	ret nz                        ; D887  C0

SFX_64B9:
	ld hl,P1_SFX_64B9             ; D888  21 B9 64
	jp L_84F5                     ; D88B  C3 F5 84

SFX_64AA:
	ld hl,P1_SFX_64AA             ; D88E  21 AA 64
	jp L_84F5                     ; D891  C3 F5 84

SFX_64C8:
	ld hl,P1_SFX_64C8             ; D894  21 C8 64
	jp L_84F5                     ; D897  C3 F5 84

SFX_64F5:
	ld hl,P1_SFX_64F5             ; D89A  21 F5 64
	jp L_84F5                     ; D89D  C3 F5 84

D_D8A0:			; данные D8A0..D8A7 (8 байт)
	db	0xFB,0x00,0x00,0x00,0x08,0x00,0x00,0x07	; D8A0
L_D8A8:
	push hl                       ; D8A8  E5
	ld b,(ix+0x02)                ; D8A9  DD 46 02
	ld a,b                        ; D8AC  78
	srl b                         ; D8AD  CB 38
	srl b                         ; D8AF  CB 38
	srl b                         ; D8B1  CB 38
	and 0x07                      ; D8B3  E6 07
	jr z,L_D8B8                   ; D8B5  28 01
	inc b                         ; D8B7  04
L_D8B8:
	ld hl,0x8278                  ; D8B8  21 78 82
	ld de,0x30                    ; D8BB  11 30 00
L_D8BE:
	and a                         ; D8BE  A7
	sbc hl,de                     ; D8BF  ED 52
	djnz L_D8BE                   ; D8C1  10 FB
	ex de,hl                      ; D8C3  EB
	pop hl                        ; D8C4  E1
	push ix                       ; D8C5  DD E5
	ld a,(D_D8A0+0x5)             ; D8C7  3A A5 D8
	add a,e                       ; D8CA  83
	ld e,a                        ; D8CB  5F
	ld a,(ix+0x02)                ; D8CC  DD 7E 02
	push de                       ; D8CF  D5
	pop ix                        ; D8D0  DD E1
	ld b,a                        ; D8D2  47
L_D8D3:
	ld e,(hl)                     ; D8D3  5E
	inc hl                        ; D8D4  23
	ld d,(hl)                     ; D8D5  56
	inc hl                        ; D8D6  23
	ld c,(hl)                     ; D8D7  4E
	inc hl                        ; D8D8  23
	push bc                       ; D8D9  C5
	ld b,0x00                     ; D8DA  06 00
	ld a,(D_D8A0+0x7)             ; D8DC  3A A7 D8
L_D8DF:
	cp 0x00                       ; D8DF  FE 00
	jr z,L_D8EE                   ; D8E1  28 0B
	dec a                         ; D8E3  3D
	srl e                         ; D8E4  CB 3B
	rr d                          ; D8E6  CB 1A
	rr c                          ; D8E8  CB 19
	rr b                          ; D8EA  CB 18
	jr L_D8DF                     ; D8EC  18 F1

L_D8EE:
	ld a,e                        ; D8EE  7B
	or (ix+0x00)                  ; D8EF  DD B6 00
	ld (ix+0x00),a                ; D8F2  DD 77 00
	ld a,d                        ; D8F5  7A
	or (ix+0x08)                  ; D8F6  DD B6 08
	ld (ix+0x08),a                ; D8F9  DD 77 08
	ld a,c                        ; D8FC  79
	or (ix+0x10)                  ; D8FD  DD B6 10
	ld (ix+0x10),a                ; D900  DD 77 10
	ld a,b                        ; D903  78
	or (ix+0x18)                  ; D904  DD B6 18
	ld (ix+0x18),a                ; D907  DD 77 18
	pop bc                        ; D90A  C1
	ld a,ixl                      ; D90B  DD 7D
	and 0x07                      ; D90D  E6 07
	cp 0x07                       ; D90F  FE 07
	jr nz,L_D918                  ; D911  20 05
	ld de,0x28                    ; D913  11 28 00
	add ix,de                     ; D916  DD 19
L_D918:
	inc ix                        ; D918  DD 23
	djnz L_D8D3                   ; D91A  10 B7
	pop ix                        ; D91C  DD E1
	ld hl,0x82D7                  ; D91E  21 D7 82
	ld c,0x04                     ; D921  0E 04
	ld a,0x03                     ; D923  3E 03
	ld (L_D93C+0x1),a             ; D925  32 3D D9
	ld (L_D944+0x1),a             ; D928  32 45 D9
	ld a,(ix+0x04)                ; D92B  DD 7E 04
	cp 0xA8                       ; D92E  FE A8
	jr nc,L_D93C                  ; D930  30 0A
	ld a,0x04                     ; D932  3E 04
	ld (L_D93C+0x1),a             ; D934  32 3D D9
	ld a,0x02                     ; D937  3E 02
	ld (L_D944+0x1),a             ; D939  32 45 D9
L_D93C:
	ld b,0x04                     ; D93C  06 04
	ld a,0xF1                     ; D93E  3E F1
L_D940:
	ld (hl),a                     ; D940  77
	inc hl                        ; D941  23
	djnz L_D940                   ; D942  10 FC
L_D944:
	ld de,0x02                    ; D944  11 02 00
	add hl,de                     ; D947  19
	dec c                         ; D948  0D
	jr nz,L_D93C                  ; D949  20 F1
	ret                           ; D94B  C9

D_D94C:			; данные D94C..D967 (28 байт)
	db	0xCC,0xD2,0xDD,0x7E,0xFE,0xDD,0x77,0x07,0xDD,0x7E,0xFD,0xDD,0x77,0x06,0xCD,0xA8	; D94C
	db	0xD7,0x01,0x09,0x00,0xDD,0x09,0xC9,0x00,0x00,0x18,0x00,0x20	; D95C
L_D968:
	ld (L_D997+0x1),bc            ; D968  ED 43 98 D9
	ld (L_D9A0+0x1),a             ; D96C  32 A1 D9
	and 0x7F                      ; D96F  E6 7F
	ld (ix+0x08),a                ; D971  DD 77 08
	push bc                       ; D974  C5
	ld b,a                        ; D975  47
	call SPR_HDR                  ; D976  CD 44 D3
	ld (L_D99D+0x1),hl            ; D979  22 9E D9
	ld (ix+0x02),b                ; D97C  DD 70 02
	ld (ix+0x03),a                ; D97F  DD 77 03
	ld a,b                        ; D982  78
	neg                           ; D983  ED 44
	pop bc                        ; D985  C1
	add a,c                       ; D986  81
	ld (ix+0x00),a                ; D987  DD 77 00
	ld (ix+0x01),b                ; D98A  DD 70 01
	ld c,a                        ; D98D  4F
L_D98E:
	call SCR_ADDR_BIT14           ; D98E  CD 70 D3
	ld (ix+0x04),l                ; D991  DD 75 04
	ld (ix+0x05),h                ; D994  DD 74 05
L_D997:
	ld bc,0x7750                  ; D997  01 50 77
	call L_D9CF                   ; D99A  CD CF D9
L_D99D:
	ld hl,SPR_BANK_E14B+0x2       ; D99D  21 4D E1
L_D9A0:
	ld a,0x80                     ; D9A0  3E 80
	and 0x80                      ; D9A2  E6 80
	call nz,L_D3CC                ; D9A4  C4 CC D3
	ld a,(ix-0x02)                ; D9A7  DD 7E FE
	ld (ix+0x07),a                ; D9AA  DD 77 07
	ld a,(ix-0x03)                ; D9AD  DD 7E FD
	ld (ix+0x06),a                ; D9B0  DD 77 06
	call L_D8A8                   ; D9B3  CD A8 D8
	ld bc,0x09                    ; D9B6  01 09 00
	add ix,bc                     ; D9B9  DD 09
	ret                           ; D9BB  C9

D_D9BC:			; данные D9BC..D9CE (19 байт)
	db	0x91,0xD6,0xBC,0xF5,0x11,0x08,0x01,0xA7,0xED,0x52,0xF1,0x28,0x2B,0x30,0x17,0x7C	; D9BC
	db	0xC6,0x06,0x67	; D9CC
L_D9CF:
	call SCR_ADDR_BIT14           ; D9CF  CD 70 D3
	ld (D_D8A0+0x7),a             ; D9D2  32 A7 D8
	ld a,l                        ; D9D5  7D
	and 0x07                      ; D9D6  E6 07
	ld (D_D8A0+0x5),a             ; D9D8  32 A5 D8
	ld a,l                        ; D9DB  7D
	and 0xF8                      ; D9DC  E6 F8
	ld l,a                        ; D9DE  6F
	and a                         ; D9DF  A7
	ld de,0x0500                  ; D9E0  11 00 05
	sbc hl,de                     ; D9E3  ED 52
	push hl                       ; D9E5  E5
	ld a,(D_D790)                 ; D9E6  3A 90 D7
	cp l                          ; D9E9  BD
	jr z,L_DA2A                   ; D9EA  28 3E
	ld a,(D_D790+0x1)             ; D9EC  3A 91 D7
	ld h,a                        ; D9EF  67
	jr nc,L_DA0E                  ; D9F0  30 1C
	ld de,0x20                    ; D9F2  11 20 00
	add hl,de                     ; D9F5  19
	push hl                       ; D9F6  E5
	ld de,0x8060                  ; D9F7  11 60 80
	call L_D849                   ; D9FA  CD 49 D8
	ld de,0x8030                  ; D9FD  11 30 80
	ld hl,0x8038                  ; DA00  21 38 80
	ld bc,0x0120                  ; DA03  01 20 01
	ldir                          ; DA06  ED B0
	pop hl                        ; DA08  E1
	call L_DAD2                   ; DA09  CD D2 DA
	jr L_DA2A                     ; DA0C  18 1C

L_DA0E:
	ld de,0x08                    ; DA0E  11 08 00
	and a                         ; DA11  A7
	sbc hl,de                     ; DA12  ED 52
	push hl                       ; DA14  E5
	ld de,0x8028                  ; DA15  11 28 80
	call L_D849                   ; DA18  CD 49 D8
	ld hl,0x8147                  ; DA1B  21 47 81
	ld de,0x814F                  ; DA1E  11 4F 81
	ld bc,0x0120                  ; DA21  01 20 01
	lddr                          ; DA24  ED B8
	pop hl                        ; DA26  E1
	call L_DAE4                   ; DA27  CD E4 DA
L_DA2A:
	pop hl                        ; DA2A  E1
	push hl                       ; DA2B  E5
	ld a,(D_D790+0x1)             ; DA2C  3A 91 D7
	cp h                          ; DA2F  BC
	push af                       ; DA30  F5
	ld de,0x08                    ; DA31  11 08 00
	and a                         ; DA34  A7
	sbc hl,de                     ; DA35  ED 52
	pop af                        ; DA37  F1
	jr z,L_DA6F                   ; DA38  28 35
	jr nc,L_DA58                  ; DA3A  30 1C
	ld a,h                        ; DA3C  7C
	add a,0x05                    ; DA3D  C6 05
	ld h,a                        ; DA3F  67
	ld de,0x8150                  ; DA40  11 50 81
	push hl                       ; DA43  E5
	call L_D86E                   ; DA44  CD 6E D8
	ld de,0x8030                  ; DA47  11 30 80
	ld hl,0x8060                  ; DA4A  21 60 80
	ld bc,0x0120                  ; DA4D  01 20 01
	ldir                          ; DA50  ED B0
	pop hl                        ; DA52  E1
	call L_DB0B                   ; DA53  CD 0B DB
	jr L_DA6F                     ; DA56  18 17

L_DA58:
	nop                           ; DA58  00
	ld de,0x8000                  ; DA59  11 00 80
	push hl                       ; DA5C  E5
	call L_D86E                   ; DA5D  CD 6E D8
	ld hl,0x811F                  ; DA60  21 1F 81
	ld de,0x814F                  ; DA63  11 4F 81
	ld bc,0x0120                  ; DA66  01 20 01
	lddr                          ; DA69  ED B8
	pop hl                        ; DA6B  E1
	call L_DB1D                   ; DA6C  CD 1D DB
L_DA6F:
	ld hl,0x8030                  ; DA6F  21 30 80
	ld de,0x8180                  ; DA72  11 80 81
	ld bc,0x0120                  ; DA75  01 20 01
	ldir                          ; DA78  ED B0
	ld hl,0x82A6                  ; DA7A  21 A6 82
	ld de,0x82D0                  ; DA7D  11 D0 82
	ld bc,0x24                    ; DA80  01 24 00
	ldir                          ; DA83  ED B0
	pop hl                        ; DA85  E1
	ld (D_D790),hl                ; DA86  22 90 D7
	ret                           ; DA89  C9

D_DA8A:			; данные DA8A..DA8D (4 байт)
	db	0x00,0x00,0x00,0x00	; DA8A
L_DA8E:
	ld hl,(D_D790)                ; DA8E  2A 90 D7
	ld de,0x08                    ; DA91  11 08 00
	and a                         ; DA94  A7
	sbc hl,de                     ; DA95  ED 52
	push hl                       ; DA97  E5
	call L_D80D                   ; DA98  CD 0D D8
	pop hl                        ; DA9B  E1
	ld a,(D_D223)                 ; DA9C  3A 23 D2
	and a                         ; DA9F  A7
	ret z                         ; DAA0  C8

	ld a,h                        ; DAA1  7C
	add a,0x0C                    ; DAA2  C6 0C
	ld h,a                        ; DAA4  67
	jp L_D80D                     ; DAA5  C3 0D D8

D_DAA8:			; данные DAA8..DAA9 (2 байт)
	db	0x00,0x00	; DAA8
L_DAAA:
	ld bc,0x2000                  ; DAAA  01 00 20
	add hl,bc                     ; DAAD  09
	ld de,0x82A6                  ; DAAE  11 A6 82
	ld c,0x06                     ; DAB1  0E 06
L_DAB3:
	push hl                       ; DAB3  E5
	ld b,0x06                     ; DAB4  06 06
L_DAB6:
	push bc                       ; DAB6  C5
	call VDP_RD_BYTE              ; DAB7  CD 20 D4
	ld (de),a                     ; DABA  12
	inc de                        ; DABB  13
	ld bc,0x08                    ; DABC  01 08 00
	add hl,bc                     ; DABF  09
	pop bc                        ; DAC0  C1
	djnz L_DAB6                   ; DAC1  10 F3
	pop hl                        ; DAC3  E1
	inc h                         ; DAC4  24
	dec c                         ; DAC5  0D
	jr nz,L_DAB3                  ; DAC6  20 EB
	ret                           ; DAC8  C9

D_DAC9:			; данные DAC9..DAD1 (9 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF	; DAC9
L_DAD2:
	ld de,0x82AC                  ; DAD2  11 AC 82
	call L_DAF6                   ; DAD5  CD F6 DA
	ld de,0x82A6                  ; DAD8  11 A6 82
	ld hl,0x82A7                  ; DADB  21 A7 82
	ld bc,0x24                    ; DADE  01 24 00
	ldir                          ; DAE1  ED B0
	ret                           ; DAE3  C9

L_DAE4:
	ld de,0x82A5                  ; DAE4  11 A5 82
	call L_DAF6                   ; DAE7  CD F6 DA
	ld hl,0x82C8                  ; DAEA  21 C8 82
	ld de,0x82C9                  ; DAED  11 C9 82
	ld bc,0x24                    ; DAF0  01 24 00
	lddr                          ; DAF3  ED B8
	ret                           ; DAF5  C9

L_DAF6:
	ld bc,0x2000                  ; DAF6  01 00 20
	add hl,bc                     ; DAF9  09
	ld b,0x06                     ; DAFA  06 06
L_DAFC:
	call VDP_RD_BYTE              ; DAFC  CD 20 D4
	ld (de),a                     ; DAFF  12
	push hl                       ; DB00  E5
	ld hl,0x06                    ; DB01  21 06 00
	add hl,de                     ; DB04  19
	ex de,hl                      ; DB05  EB
	pop hl                        ; DB06  E1
	inc h                         ; DB07  24
	djnz L_DAFC                   ; DB08  10 F2
	ret                           ; DB0A  C9

L_DB0B:
	ld de,0x82CA                  ; DB0B  11 CA 82
	call L_DB2F                   ; DB0E  CD 2F DB
	ld de,0x82A6                  ; DB11  11 A6 82
	ld hl,0x82AC                  ; DB14  21 AC 82
	ld bc,0x24                    ; DB17  01 24 00
	ldir                          ; DB1A  ED B0
	ret                           ; DB1C  C9

L_DB1D:
	ld de,0x82A0                  ; DB1D  11 A0 82
	call L_DB2F                   ; DB20  CD 2F DB
	ld hl,0x82C3                  ; DB23  21 C3 82
	ld de,0x82C9                  ; DB26  11 C9 82
	ld bc,0x24                    ; DB29  01 24 00
	lddr                          ; DB2C  ED B8
	ret                           ; DB2E  C9

L_DB2F:
	ld bc,0x2000                  ; DB2F  01 00 20
	add hl,bc                     ; DB32  09
	ld b,0x06                     ; DB33  06 06
L_DB35:
	call VDP_RD_BYTE              ; DB35  CD 20 D4
	ld (de),a                     ; DB38  12
	inc de                        ; DB39  13
	push bc                       ; DB3A  C5
	ld bc,0x08                    ; DB3B  01 08 00
	add hl,bc                     ; DB3E  09
	pop bc                        ; DB3F  C1
	djnz L_DB35                   ; DB40  10 F3
	ret                           ; DB42  C9

D_DB43:			; данные DB43..DB55 (19 байт)
	db	0x00,0x08,0x00,0x31,0x00,0x11,0x00,0x30,0x00,0x49,0x00,0x38,0x00,0xFF,0xC7,0xFF	; DB43
	db	0xEF,0xFF,0xC7	; DB53
L_DB56:
	push hl                       ; DB56  E5
	ld b,0x06                     ; DB57  06 06
	ld a,h                        ; DB59  7C
	cp 0x4B                       ; DB5A  FE 4B
	jr nz,L_DB61                  ; DB5C  20 03
	push bc                       ; DB5E  C5
	jr L_DB6A                     ; DB5F  18 09

L_DB61:
	push bc                       ; DB61  C5
L_DB62:
	ld bc,0x30                    ; DB62  01 30 00
	ld a,h                        ; DB65  7C
	cp 0x58                       ; DB66  FE 58
	jr c,L_DB73                   ; DB68  38 09
L_DB6A:
	push hl                       ; DB6A  E5
	ld hl,0x30                    ; DB6B  21 30 00
	add hl,de                     ; DB6E  19
	ex de,hl                      ; DB6F  EB
	pop hl                        ; DB70  E1
	jr L_DB7F                     ; DB71  18 0C

L_DB73:
	push hl                       ; DB73  E5
	push de                       ; DB74  D5
	call VDP_COPY_TO_VRAM         ; DB75  CD 33 D4
	pop de                        ; DB78  D1
	ld hl,0x30                    ; DB79  21 30 00
	add hl,de                     ; DB7C  19
	ex de,hl                      ; DB7D  EB
	pop hl                        ; DB7E  E1
L_DB7F:
	inc h                         ; DB7F  24
	pop bc                        ; DB80  C1
	djnz L_DB61                   ; DB81  10 DE
	pop hl                        ; DB83  E1
	ld a,0x60                     ; DB84  3E 60
	ld (L_D40C+0x1),a             ; DB86  32 0D D4
L_DB89:
	ld de,0x82D0                  ; DB89  11 D0 82
	ld c,0x06                     ; DB8C  0E 06
	ld a,h                        ; DB8E  7C
	cp 0x4B                       ; DB8F  FE 4B
	jr nz,L_DB96                  ; DB91  20 03
	push hl                       ; DB93  E5
	jr L_DB9D                     ; DB94  18 07

L_DB96:
	push hl                       ; DB96  E5
	push de                       ; DB97  D5
	ld a,h                        ; DB98  7C
	cp 0x58                       ; DB99  FE 58
	jr c,L_DBA6                   ; DB9B  38 09
L_DB9D:
	push hl                       ; DB9D  E5
	ld hl,0x06                    ; DB9E  21 06 00
	add hl,de                     ; DBA1  19
	ex de,hl                      ; DBA2  EB
	pop hl                        ; DBA3  E1
	jr L_DBB9                     ; DBA4  18 13

L_DBA6:
	ld b,0x06                     ; DBA6  06 06
L_DBA8:
	push bc                       ; DBA8  C5
	ld bc,0x08                    ; DBA9  01 08 00
	ld a,(de)                     ; DBAC  1A
	nop                           ; DBAD  00
	call VDP_FILL                 ; DBAE  CD 11 D4
	inc de                        ; DBB1  13
	ld bc,0x08                    ; DBB2  01 08 00
	add hl,bc                     ; DBB5  09
	pop bc                        ; DBB6  C1
	djnz L_DBA8                   ; DBB7  10 EF
L_DBB9:
	pop de                        ; DBB9  D1
	ld hl,0x06                    ; DBBA  21 06 00
	add hl,de                     ; DBBD  19
	ex de,hl                      ; DBBE  EB
	pop hl                        ; DBBF  E1
	inc h                         ; DBC0  24
	dec c                         ; DBC1  0D
	jr nz,L_DB96                  ; DBC2  20 D2
	ld a,0x40                     ; DBC4  3E 40
	ld (L_D40C+0x1),a             ; DBC6  32 0D D4
	ret                           ; DBC9  C9

D_DBCA:			; данные DBCA..DBCE (5 байт)
	db	0x00,0xCD,0x68,0xD8,0xCD	; DBCA
L_DBCF:
	ld a,0xC9                     ; DBCF  3E C9
	ld (L_D8A8),a                 ; DBD1  32 A8 D8
	ld bc,(GAME_VARS+0xA)         ; DBD4  ED 4B F4 C2
	ld a,0x00                     ; DBD8  3E 00
	call L_D968                   ; DBDA  CD 68 D9
	call L_DA8E                   ; DBDD  CD 8E DA
	ld a,0xE5                     ; DBE0  3E E5
	ld (L_D8A8),a                 ; DBE2  32 A8 D8
	ret                           ; DBE5  C9

	jp 0xD98E                     ; DBE6  C3 8E D9  ; СТУХШИЙ ОПЕРАНД, должно быть DA8E

L_DBE9:
	call L_CECD                   ; DBE9  CD CD CE
	ld hl,LOW_TILE_SRC            ; DBEC  21 F4 82
	ld (L_CF36+0x1),hl            ; DBEF  22 37 CF
	ld hl,D_DC0E                  ; DBF2  21 0E DC
	ld b,0x11                     ; DBF5  06 11
	ld de,0x1518                  ; DBF7  11 18 15
	call L_CEF9                   ; DBFA  CD F9 CE
	ld hl,HUD_TILES+0x8C          ; DBFD  21 E2 B8
	ld (L_CF36+0x1),hl            ; DC00  22 37 CF
	ld b,0x04                     ; DC03  06 04
	ld de,0x171A                  ; DC05  11 1A 17
	ld hl,D_DC0E+0x11             ; DC08  21 1F DC
	jp L_CEF9                     ; DC0B  C3 F9 CE

D_DC0E:			; данные DC0E..DC23 (22 байт)
	db	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x18,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F	; DC0E
	db	0x30,0x3B,0x43,0x42,0x41,0x00	; DC1E
L_DC24:
	call SFX_64E6                 ; DC24  CD E5 D7
	ld bc,0x2710                  ; DC27  01 10 27
L_DC2A:
	dec bc                        ; DC2A  0B
	ld a,b                        ; DC2B  78
	or c                          ; DC2C  B1
	jr nz,L_DC2A                  ; DC2D  20 FB
	ret                           ; DC2F  C9

D_DC30:			; данные DC30..DC39 (10 байт)
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DC30
MUS_START:
	ld hl,(D_DD6F+0x14)           ; DC3A  2A 83 DD
	ld (D_DD6F+0xA),hl            ; DC3D  22 79 DD
	ld hl,(D_DD6F+0x16)           ; DC40  2A 85 DD
	ld (D_DD6F+0xC),hl            ; DC43  22 7B DD
	ld hl,(D_DD6F+0x18)           ; DC46  2A 87 DD
	ld (D_DD6F+0xE),hl            ; DC49  22 7D DD
	ld hl,D_DD6F                  ; DC4C  21 6F DD
	ld b,(hl)                     ; DC4F  46
	inc hl                        ; DC50  23
L_DC51:
	push bc                       ; DC51  C5
	ld a,(hl)                     ; DC52  7E
	inc hl                        ; DC53  23
	ld c,(hl)                     ; DC54  4E
	inc hl                        ; DC55  23
	call PSG_WR                   ; DC56  CD 69 DD
	pop bc                        ; DC59  C1
	djnz L_DC51                   ; DC5A  10 F5
L_DC5C:
	ld bc,(D_DD6F+0x12)           ; DC5C  ED 4B 81 DD
L_DC60:
	push bc                       ; DC60  C5
	ld b,0x09                     ; DC61  06 09
	ld c,0xF0                     ; DC63  0E F0
L_DC65:
	ld a,c                        ; DC65  79
	out (0xAA),a                  ; DC66  D3 AA
	in a,(0xA9)                   ; DC68  DB A9
	cp 0xFF                       ; DC6A  FE FF
	jp nz,L_DD5C                  ; DC6C  C2 5C DD
	inc c                         ; DC6F  0C
	djnz L_DC65                   ; DC70  10 F3
	pop bc                        ; DC72  C1
	dec bc                        ; DC73  0B
	ld a,b                        ; DC74  78
	or c                          ; DC75  B1
	jr nz,L_DC60                  ; DC76  20 E8
	ld hl,(D_DD6F+0xA)            ; DC78  2A 79 DD
	ld a,(D_DD6F+0x9)             ; DC7B  3A 78 DD
	or 0x01                       ; DC7E  F6 01
	ld (D_DD6F+0x9),a             ; DC80  32 78 DD
	ld c,a                        ; DC83  4F
	ld a,0x07                     ; DC84  3E 07
	call PSG_WR                   ; DC86  CD 69 DD
	ld a,(hl)                     ; DC89  7E
	cp 0xFE                       ; DC8A  FE FE
	jr nz,L_DC95                  ; DC8C  20 07
	ld hl,(D_DD6F+0x14)           ; DC8E  2A 83 DD
	ld (D_DD6F+0xA),hl            ; DC91  22 79 DD
	ld a,(hl)                     ; DC94  7E
L_DC95:
	cp 0xFF                       ; DC95  FE FF
	jr z,L_DCBF                   ; DC97  28 26
	sla a                         ; DC99  CB 27
	ld d,0x00                     ; DC9B  16 00
	ld e,a                        ; DC9D  5F
	push hl                       ; DC9E  E5
	ld hl,(D_DD6F+0x10)           ; DC9F  2A 7F DD
	add hl,de                     ; DCA2  19
	ld a,0x00                     ; DCA3  3E 00
	ld c,(hl)                     ; DCA5  4E
	call PSG_WR                   ; DCA6  CD 69 DD
	ld a,0x01                     ; DCA9  3E 01
	inc hl                        ; DCAB  23
	ld c,(hl)                     ; DCAC  4E
	call PSG_WR                   ; DCAD  CD 69 DD
	ld a,(D_DD6F+0x9)             ; DCB0  3A 78 DD
	and 0xFE                      ; DCB3  E6 FE
	ld (D_DD6F+0x9),a             ; DCB5  32 78 DD
	ld c,a                        ; DCB8  4F
	ld a,0x07                     ; DCB9  3E 07
	call PSG_WR                   ; DCBB  CD 69 DD
	pop hl                        ; DCBE  E1
L_DCBF:
	inc hl                        ; DCBF  23
	ld (D_DD6F+0xA),hl            ; DCC0  22 79 DD
	ld hl,(D_DD6F+0xC)            ; DCC3  2A 7B DD
	ld a,(D_DD6F+0x9)             ; DCC6  3A 78 DD
	or 0x02                       ; DCC9  F6 02
	ld (D_DD6F+0x9),a             ; DCCB  32 78 DD
	ld c,a                        ; DCCE  4F
	ld a,0x07                     ; DCCF  3E 07
	call PSG_WR                   ; DCD1  CD 69 DD
	ld a,(hl)                     ; DCD4  7E
	cp 0xFE                       ; DCD5  FE FE
	jr nz,L_DCE0                  ; DCD7  20 07
	ld hl,(D_DD6F+0x16)           ; DCD9  2A 85 DD
	ld (D_DD6F+0xC),hl            ; DCDC  22 7B DD
	ld a,(hl)                     ; DCDF  7E
L_DCE0:
	cp 0xFF                       ; DCE0  FE FF
	jr z,L_DD0A                   ; DCE2  28 26
	sla a                         ; DCE4  CB 27
	ld d,0x00                     ; DCE6  16 00
	ld e,a                        ; DCE8  5F
	push hl                       ; DCE9  E5
	ld hl,(D_DD6F+0x10)           ; DCEA  2A 7F DD
	add hl,de                     ; DCED  19
	ld a,0x02                     ; DCEE  3E 02
	ld c,(hl)                     ; DCF0  4E
	call PSG_WR                   ; DCF1  CD 69 DD
	ld a,0x03                     ; DCF4  3E 03
	inc hl                        ; DCF6  23
	ld c,(hl)                     ; DCF7  4E
	call PSG_WR                   ; DCF8  CD 69 DD
	ld a,(D_DD6F+0x9)             ; DCFB  3A 78 DD
	and 0xFD                      ; DCFE  E6 FD
	ld (D_DD6F+0x9),a             ; DD00  32 78 DD
	ld c,a                        ; DD03  4F
	ld a,0x07                     ; DD04  3E 07
	call PSG_WR                   ; DD06  CD 69 DD
	pop hl                        ; DD09  E1
L_DD0A:
	inc hl                        ; DD0A  23
	ld (D_DD6F+0xC),hl            ; DD0B  22 7B DD
	ld hl,(D_DD6F+0xE)            ; DD0E  2A 7D DD
	ld a,(D_DD6F+0x9)             ; DD11  3A 78 DD
	or 0x04                       ; DD14  F6 04
	ld (D_DD6F+0x9),a             ; DD16  32 78 DD
	ld c,a                        ; DD19  4F
	ld a,0x07                     ; DD1A  3E 07
	call PSG_WR                   ; DD1C  CD 69 DD
	ld a,(hl)                     ; DD1F  7E
	cp 0xFE                       ; DD20  FE FE
	jr nz,L_DD2B                  ; DD22  20 07
	ld hl,(D_DD6F+0x18)           ; DD24  2A 87 DD
	ld (D_DD6F+0xE),hl            ; DD27  22 7D DD
	ld a,(hl)                     ; DD2A  7E
L_DD2B:
	cp 0xFF                       ; DD2B  FE FF
	jr z,L_DD55                   ; DD2D  28 26
	sla a                         ; DD2F  CB 27
	ld d,0x00                     ; DD31  16 00
	ld e,a                        ; DD33  5F
	push hl                       ; DD34  E5
	ld hl,(D_DD6F+0x10)           ; DD35  2A 7F DD
	add hl,de                     ; DD38  19
	ld a,0x04                     ; DD39  3E 04
	ld c,(hl)                     ; DD3B  4E
	call PSG_WR                   ; DD3C  CD 69 DD
	ld a,0x05                     ; DD3F  3E 05
	inc hl                        ; DD41  23
	ld c,(hl)                     ; DD42  4E
	call PSG_WR                   ; DD43  CD 69 DD
	ld a,(D_DD6F+0x9)             ; DD46  3A 78 DD
	and 0xFB                      ; DD49  E6 FB
	ld (D_DD6F+0x9),a             ; DD4B  32 78 DD
	ld c,a                        ; DD4E  4F
	ld a,0x07                     ; DD4F  3E 07
	call PSG_WR                   ; DD51  CD 69 DD
	pop hl                        ; DD54  E1
L_DD55:
	inc hl                        ; DD55  23
	ld (D_DD6F+0xE),hl            ; DD56  22 7D DD
	jp L_DC5C                     ; DD59  C3 5C DC

L_DD5C:
	pop bc                        ; DD5C  C1
	ld a,0x3F                     ; DD5D  3E 3F
	ld (D_DD6F+0x9),a             ; DD5F  32 78 DD
	ld c,a                        ; DD62  4F
	ld a,0x07                     ; DD63  3E 07
	call PSG_WR                   ; DD65  CD 69 DD
	ret                           ; DD68  C9

PSG_WR:
	out (0xA0),a                  ; DD69  D3 A0
	ld a,c                        ; DD6B  79
	out (0xA1),a                  ; DD6C  D3 A1
	ret                           ; DD6E  C9

D_DD6F:			; данные DD6F..E0E6 (888 байт)
	db	0x04,0x07,0x3F,0x08,0x00,0x09,0x00,0x0A,0x00,0x3F,0x00,0x00,0x00,0x00,0x00,0x00	; DD6F
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xE5,0xDF,0x5C,0x0D,0x9C,0x0C,0xE7,0x0B	; DD7F
	db	0x3C,0x0B,0x9A,0x0A,0x02,0x0A,0x72,0x09,0xEA,0x08,0x6A,0x08,0xF1,0x07,0x7F,0x07	; DD8F
	db	0x13,0x07,0xAE,0x06,0x4E,0x06,0xF3,0x05,0x9E,0x05,0x4D,0x05,0x01,0x05,0xB9,0x04	; DD9F
	db	0x75,0x04,0x35,0x04,0xF8,0x03,0xBF,0x03,0x89,0x03,0x57,0x03,0x27,0x03,0xF9,0x02	; DDAF
	db	0xCF,0x02,0xA6,0x02,0x80,0x02,0x5C,0x02,0x3A,0x02,0x1A,0x02,0xFC,0x01,0xDF,0x01	; DDBF
	db	0xC4,0x01,0xAB,0x01,0x93,0x01,0x7C,0x01,0x67,0x01,0x53,0x01,0x40,0x01,0x2E,0x01	; DDCF
	db	0x1D,0x01,0x0D,0x01,0xFE,0x00,0xEF,0x00,0xE2,0x00,0xD5,0x00,0xC9,0x00,0xBE,0x00	; DDDF
	db	0xB3,0x00,0xA9,0x00,0xA0,0x00,0x97,0x00,0x8E,0x00,0x86,0x00,0x7F,0x00,0x77,0x00	; DDEF
	db	0x71,0x00,0x6A,0x00,0x64,0x00,0x5F,0x00,0x59,0x00,0x54,0x00,0x50,0x00,0x4B,0x00	; DDFF
	db	0x47,0x00,0x43,0x00,0x3F,0x00,0x3B,0x00,0x38,0x00,0x35,0x00,0x32,0x00,0x2F,0x00	; DE0F
	db	0x2C,0x00,0x2A,0x00,0x28,0x00,0x25,0x00,0x23,0x00,0x21,0x00,0x1F,0x00,0x1D,0x00	; DE1F
	db	0x1C,0x00,0x1A,0x00,0x19,0x00,0x17,0x00,0x16,0x00,0x15,0x00,0x14,0x00,0x12,0x00	; DE2F
	db	0x11,0x00,0x10,0x00,0x0F,0x00,0x0E,0x00,0x0E,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; DE3F
	db	0x00,0x00,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06	; DE4F
	db	0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x03,0x0A,0x08,0x06,0x08,0x06	; DE5F
	db	0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05	; DE6F
	db	0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08,0x06,0x0D,0x0C,0x0A,0x08,0x01	; DE7F
	db	0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08,0x03,0x0A,0x08,0x06,0x08,0x06	; DE8F
	db	0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05	; DE9F
	db	0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08,0x06,0x0D,0x0C,0x0A,0x08,0x01	; DEAF
	db	0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08,0x03,0x0A,0x08,0x06,0x08,0x06	; DEBF
	db	0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05	; DECF
	db	0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08,0x06,0x0D,0x0C,0x0A,0x08,0x01	; DEDF
	db	0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08,0x03,0x0A,0x08,0x06,0x08,0x06	; DEEF
	db	0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05	; DEFF
	db	0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08,0x06,0x0D,0x0C,0x0A,0x08,0x01	; DF0F
	db	0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08,0x03,0x0A,0x08,0x06,0x08,0x06	; DF1F
	db	0x08,0x0A,0xFE,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DF2F
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DF3F
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DF4F
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; DF5F
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x03,0xFF,0x03,0xFF,0x03	; DF6F
	db	0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x01,0xFF,0x01,0xFF,0x01	; DF7F
	db	0xFF,0x01,0xFF,0x0A,0xFF,0x0A,0xFF,0x0C,0xFF,0x0C,0xFF,0x06,0xFF,0x06,0xFF,0x01	; DF8F
	db	0xFF,0x01,0xFF,0x06,0xFF,0x06,0xFF,0x03,0xFF,0x08,0xFF,0x03,0x03,0x03,0x03,0x03	; DF9F
	db	0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x01,0x01,0x01,0x01,0x01	; DFAF
	db	0x01,0x01,0x01,0x0A,0x0A,0x0A,0x0A,0x0C,0x0C,0x0C,0x0C,0x06,0x06,0x06,0x06,0x01	; DFBF
	db	0x01,0x01,0x01,0x06,0x06,0x06,0x06,0x03,0x03,0x08,0x08,0x0F,0x03,0x0F,0x03,0x0F	; DFCF
	db	0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0D,0x01,0x0D,0x01,0x0D	; DFDF
	db	0x01,0x0D,0x01,0x16,0x0A,0x16,0x0A,0x18,0x0C,0x18,0x0C,0x12,0x06,0x12,0x06,0x0D	; DFEF
	db	0x01,0x0D,0x01,0x12,0x06,0x12,0x06,0x0F,0x03,0x14,0x08,0x03,0x03,0x03,0x03,0x03	; DFFF
	db	0x03,0x03,0x03,0xFE,0x01,0x01,0x01,0x0C,0x08,0x08,0x06,0x05,0x01,0x01,0x01,0x0C	; E00F
	db	0x08,0x08,0x06,0x05,0x05,0x05,0x05,0x10,0x0C,0x0C,0x0A,0x08,0x05,0x05,0x05,0x10	; E01F
	db	0x0C,0x0C,0x0A,0x08,0x0A,0x0A,0x0A,0x15,0x11,0x11,0x0F,0x0D,0x0A,0x0A,0x0A,0x15	; E02F
	db	0x11,0x11,0x0F,0x0D,0x06,0x06,0x06,0x11,0x0D,0x0D,0x0C,0x0A,0x06,0x06,0x06,0x11	; E03F
	db	0x0D,0x0D,0x0C,0x0A,0x03,0x03,0x03,0x0E,0x0A,0x0A,0x08,0x06,0x03,0x03,0x03,0x0E	; E04F
	db	0x0A,0x0A,0x08,0x06,0x08,0x08,0x08,0x13,0x0F,0x0D,0x0F,0x0D,0x08,0x08,0x08,0x13	; E05F
	db	0x0F,0x0F,0x0D,0x0C,0x08,0x08,0x08,0x13,0x08,0x08,0x08,0x13,0xFE,0x11,0x0D,0x11	; E06F
	db	0x0D,0x11,0x0D,0x11,0x08,0x11,0x0D,0x11,0x0D,0x0F,0x0D,0x0F,0x08,0x11,0x05,0x11	; E07F
	db	0x05,0x11,0x05,0x11,0x0C,0x11,0x05,0x11,0x05,0x14,0x05,0x14,0x0C,0x0D,0x0A,0x0D	; E08F
	db	0x0A,0x0D,0x0A,0x0D,0x05,0x0D,0x0A,0x0D,0x0A,0x0F,0x0A,0x11,0x05,0x12,0x06,0x12	; E09F
	db	0x06,0x12,0x06,0x12,0x0D,0x12,0x06,0x12,0x06,0x11,0x06,0x11,0x0D,0x0F,0x03,0x0F	; E0AF
	db	0x03,0x0F,0x03,0x0F,0x0A,0x0F,0x03,0x0F,0x03,0x16,0x03,0x18,0x0A,0x19,0x08,0x19	; E0BF
	db	0x08,0x19,0x08,0x19,0x0D,0x19,0x08,0x19,0x08,0x19,0x08,0x19,0x0D,0x18,0x08,0x18	; E0CF
	db	0x08,0x18,0x08,0x18,0x08,0xFE,0xFF,0xFE	; E0DF
MUS_TRACK_1:
	ld hl,D_DD6F+0xE2             ; E0E7  21 51 DE
	ld (D_DD6F+0x14),hl           ; E0EA  22 83 DD
	ld hl,D_DD6F+0x1C3            ; E0ED  21 32 DF
	ld (D_DD6F+0x16),hl           ; E0F0  22 85 DD
	ld hl,0x0480                  ; E0F3  21 80 04
	ld (D_DD6F+0x12),hl           ; E0F6  22 81 DD
	ld hl,D_DD6F+0x56             ; E0F9  21 C5 DD
	ld (D_DD6F+0x10),hl           ; E0FC  22 7F DD
	ld a,0x0F                     ; E0FF  3E 0F
	ld (D_DD6F+0x4),a             ; E101  32 73 DD
	ld a,0x0E                     ; E104  3E 0E
	ld (D_DD6F+0x6),a             ; E106  32 75 DD
	jp MUS_START                  ; E109  C3 3A DC

D_E10C:			; данные E10C..E118 (13 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; E10C
MUS_TRACK_2:
	ld hl,D_DD6F+0x2A4            ; E119  21 13 E0
	ld (D_DD6F+0x14),hl           ; E11C  22 83 DD
	ld hl,D_DD6F+0x30D            ; E11F  21 7C E0
	ld (D_DD6F+0x16),hl           ; E122  22 85 DD
	ld hl,0x04FF                  ; E125  21 FF 04
	ld (D_DD6F+0x12),hl           ; E128  22 81 DD
	ld hl,D_DD6F+0x60             ; E12B  21 CF DD
	ld (D_DD6F+0x10),hl           ; E12E  22 7F DD
	ld a,0x0C                     ; E131  3E 0C
	ld (D_DD6F+0x4),a             ; E133  32 73 DD
	ld a,0x0F                     ; E136  3E 0F
	ld (D_DD6F+0x6),a             ; E138  32 75 DD
	jp MUS_START                  ; E13B  C3 3A DC

D_E13E:			; данные E13E..E14A (13 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; E13E
