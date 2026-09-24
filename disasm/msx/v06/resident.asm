; Spirits (Topo Soft, 1987), MSX — RESIDENT [РАСКЛАДКА ВЕКТОРА-06Ц, кусок resident]
; Источник — ref/msx/SPIRITS.1.payload в раскладке ОРИГИНАЛА (канон сдвинут на +0x100).
; Оригинал D000..E04A  ->  Вектор 1900..294A (4171 байт)
; Достижимый код 2746 байт, остальное — db (графика/таблицы).
;
; Абсолютных адресов 282: символом 282, числом 0. Относительных 102.
; Раскладка и проверки — docs/v06-memory.md, tools/verify_v06.py.
; Адреса в комментариях — уже ВЕКТОРНЫЕ; пояснения к областям данных
; цитируют адреса канона +0x100 (это разбор, а не операнды).
;
; Сгенерировано tools/disasm_msx.py --v06 — правки вносить туда или в tools/entries.json.
; Наложения (цель внутри предыдущей инструкции): 1BF8

; Символы вне этого образа: резидентный слой (он копируется в верхнюю RAM
; из SPIRITS.1 — см. docs/msx-vdp-abi.md), копия в page 1, BIOS и цели,
; попавшие внутрь чужой инструкции. equ байтов не порождает — канон не
; трогается, а при смене org правится в одном месте.
P1_SFX_64AA:	equ	0x4EAA
P1_SFX_64B9:	equ	0x4EB9
P1_SFX_64C8:	equ	0x4EC8
P1_SFX_64D7:	equ	0x4ED7
P1_SFX_64E6:	equ	0x4EE6
P1_SFX_64F5:	equ	0x4EF5
LOW_TILE_SRC:	equ	0x01F4
L_03F5:	equ	0x03F5
ROOM_MAPS:	equ	0x6847
SPR_DATA_8B9C:	equ	0x8B9C
SPR_DATA_8E76:	equ	0x8E76
HUD_TILES:	equ	0x9B56
L_0834:	equ	0x0834
GAME_VARS:	equ	0x0AEA
L_0C8C:	equ	0x0C8C
L_0F4A:	equ	0x0F4A
L_0F98:	equ	0x0F98
L_155D:	equ	0x155D
L_159A:	equ	0x159A
L_15A7:	equ	0x15A7
D_15C4:	equ	0x15C4
L_16CD:	equ	0x16CD
L_16F9:	equ	0x16F9
L_1736:	equ	0x1736
SPR_BANK_294B:	equ	0x294B
WORK_RAM:	equ	0x3AA8

	org	0x1900

D_1900:			; данные 1900..1906 (7 байт)
	db	0x00,0x00,0xAF,0x00,0x00,0x00,0x01	; 1900
L_1907:
	ld a,0xC9                     ; 1907  3E C9
	ld (L_1FA9),a                 ; 1909  32 A9 1F
	call L_0834                   ; 190C  CD 34 08
	call L_1D9B                   ; 190F  CD 9B 1D
	call L_0F4A                   ; 1912  CD 4A 0F
	ld a,0xCD                     ; 1915  3E CD
	ld (L_1FA9),a                 ; 1917  32 A9 1F
	ret                           ; 191A  C9

D_191B:			; данные 191B..1920 (6 байт)
	db	0x02,0xD2,0x32,0x11,0xD3,0xC9	; 191B
L_1921:
	ld a,(D_1969)                 ; 1921  3A 69 19
	cpl                           ; 1924  2F
	ld (D_1969),a                 ; 1925  32 69 19
	and a                         ; 1928  A7
	jr z,L_196A                   ; 1929  28 3F
	ld hl,0x00                    ; 192B  21 00 00
	ld d,0x80                     ; 192E  16 80
L_1930:
	push hl                       ; 1930  E5
	ld bc,0x0800                  ; 1931  01 00 08
L_1934:
	res 3,h                       ; 1934  CB 9C
	set 4,h                       ; 1936  CB E4
	call VDP_RD_BYTE              ; 1938  CD 20 1C
	and d                         ; 193B  A2
	ld e,a                        ; 193C  5F
	res 4,h                       ; 193D  CB A4
	set 3,h                       ; 193F  CB DC
	call VDP_RD_BYTE              ; 1941  CD 20 1C
	xor e                         ; 1944  AB
	call VDP_WR_BYTE              ; 1945  CD 28 1C
	inc hl                        ; 1948  23
	dec bc                        ; 1949  0B
	ld a,b                        ; 194A  78
	or c                          ; 194B  B1
	jr nz,L_1934                  ; 194C  20 E6
	ld h,0x0A                     ; 194E  26 0A
L_1950:
	dec h                         ; 1950  25
	jr nz,L_1950                  ; 1951  20 FD
	nop                           ; 1953  00
	nop                           ; 1954  00
	pop hl                        ; 1955  E1
	rr d                          ; 1956  CB 1A
	jr nc,L_1930                  ; 1958  30 D6
	ld hl,0x0800                  ; 195A  21 00 08
	call VDP_RD_BYTE              ; 195D  CD 20 1C
	ld bc,0x0800                  ; 1960  01 00 08
	ld hl,0x1001                  ; 1963  21 01 10
	jp VDP_FILL                   ; 1966  C3 11 1C

D_1969:			; данные 1969..1969 (1 байт)
	db	0xFF	; 1969
L_196A:
	ld hl,0x0800                  ; 196A  21 00 08
	ld b,0x08                     ; 196D  06 08
L_196F:
	push bc                       ; 196F  C5
	ld b,0x08                     ; 1970  06 08
L_1972:
	dec bc                        ; 1972  0B
	ld a,b                        ; 1973  78
	or c                          ; 1974  B1
	jr nz,L_1972                  ; 1975  20 FB
	push hl                       ; 1977  E5
L_1978:
	res 3,h                       ; 1978  CB 9C
	set 4,h                       ; 197A  CB E4
	call VDP_RD_BYTE              ; 197C  CD 20 1C
	res 4,h                       ; 197F  CB A4
	set 3,h                       ; 1981  CB DC
	call VDP_WR_BYTE              ; 1983  CD 28 1C
	ld de,0x08                    ; 1986  11 08 00
	add hl,de                     ; 1989  19
	djnz L_1978                   ; 198A  10 EC
	pop hl                        ; 198C  E1
	inc hl                        ; 198D  23
	pop bc                        ; 198E  C1
	djnz L_196F                   ; 198F  10 DE
	ret                           ; 1991  C9

SCR_ADDR_BIT13:
	ld a,c                        ; 1992  79
	and 0xF8                      ; 1993  E6 F8
	rrca                          ; 1995  0F
	rrca                          ; 1996  0F
	rrca                          ; 1997  0F
	ld h,a                        ; 1998  67
	ld a,b                        ; 1999  78
	and 0xF8                      ; 199A  E6 F8
	ld l,a                        ; 199C  6F
	set 5,h                       ; 199D  CB EC
	ret                           ; 199F  C9

L_19A0:
	ld (L_19E2+0x1),a             ; 19A0  32 E3 19
	and 0x7F                      ; 19A3  E6 7F
	ld (ix+0x08),a                ; 19A5  DD 77 08
	push bc                       ; 19A8  C5
	ld b,a                        ; 19A9  47
	add a,0x17                    ; 19AA  C6 17
	ld l,a                        ; 19AC  6F
	ld h,0xF3                     ; 19AD  26 F3
	ld a,(hl)                     ; 19AF  7E
	ld (L_19DA+0x1),a             ; 19B0  32 DB 19
	call SPR_HDR                  ; 19B3  CD 44 1B
	ld (L_19DF+0x1),hl            ; 19B6  22 E0 19
	ld (ix+0x02),b                ; 19B9  DD 70 02
	ld c,a                        ; 19BC  4F
	ld (ix+0x03),c                ; 19BD  DD 71 03
	call L_1C81                   ; 19C0  CD 81 1C
	ld a,b                        ; 19C3  78
	neg                           ; 19C4  ED 44
	pop bc                        ; 19C6  C1
	add a,c                       ; 19C7  81
	ld c,a                        ; 19C8  4F
	ld (ix+0x00),c                ; 19C9  DD 71 00
	ld (ix+0x01),b                ; 19CC  DD 70 01
	push bc                       ; 19CF  C5
	call SCR_ADDR_BIT14           ; 19D0  CD 70 1B
	ld (ix+0x04),l                ; 19D3  DD 75 04
	ld (ix+0x05),h                ; 19D6  DD 74 05
	pop bc                        ; 19D9  C1
L_19DA:
	ld a,0x0C                     ; 19DA  3E 0C
	call L_1C40                   ; 19DC  CD 40 1C
L_19DF:
	ld hl,SPR_BANK_294B+0x8D7     ; 19DF  21 22 32
L_19E2:
	ld a,0x16                     ; 19E2  3E 16
	and 0x80                      ; 19E4  E6 80
	call nz,L_1BCC                ; 19E6  C4 CC 1B
	call L_1D47                   ; 19E9  CD 47 1D
	ld bc,0x09                    ; 19EC  01 09 00
	add ix,bc                     ; 19EF  DD 09
	ret                           ; 19F1  C9

L_19F2:
	ld ix,WORK_RAM+0x81           ; 19F2  DD 21 29 3B  ; в каноне +0x100 этот операнд стухший
	ld (ix-0x01),0xFF             ; 19F6  DD 36 FF FF
	ld (ix-0x03),0x00             ; 19FA  DD 36 FD 00
	ld (ix-0x02),0xF8             ; 19FE  DD 36 FE F8
	ld hl,WORK_RAM+0x5D6          ; 1A02  21 7E 40  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x5D7          ; 1A05  11 7F 40  ; в каноне +0x100 этот операнд стухший
	ld bc,0x7F                    ; 1A08  01 7F 00
	ld (hl),0xD1                  ; 1A0B  36 D1
	ldir                          ; 1A0D  ED B0
	ld hl,WORK_RAM+0x656          ; 1A0F  21 FE 40  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x657          ; 1A12  11 FF 40  ; в каноне +0x100 этот операнд стухший
	ld bc,0x07FF                  ; 1A15  01 FF 07
	ld (hl),0x00                  ; 1A18  36 00
	ldir                          ; 1A1A  ED B0
	jp L_1D90                     ; 1A1C  C3 90 1D

	ld (WORK_RAM+0x5D6),hl        ; 1A1F  22 7E 40  ; в каноне +0x100 этот операнд стухший
	ret                           ; 1A22  C9

D_1A23:			; данные 1A23..1A23 (1 байт)
	db	0x00	; 1A23
L_1A24:
	ld a,(D_1A23)                 ; 1A24  3A 23 1A
	and a                         ; 1A27  A7
	jp z,L_1F64                   ; 1A28  CA 64 1F
	ld de,(D_1D08+0xE)            ; 1A2B  ED 5B 16 1D
	ld hl,WORK_RAM+0x656          ; 1A2F  21 FE 40  ; в каноне +0x100 этот операнд стухший
	and a                         ; 1A32  A7
	sbc hl,de                     ; 1A33  ED 52
	srl l                         ; 1A35  CB 3D
	srl l                         ; 1A37  CB 3D
	ld b,l                        ; 1A39  45
	dec de                        ; 1A3A  1B
	ld hl,WORK_RAM+0x655          ; 1A3B  21 FD 40  ; в каноне +0x100 этот операнд стухший
	jp L_1F55                     ; 1A3E  C3 55 1F

L_1A41:
	push bc                       ; 1A41  C5
	dec c                         ; 1A42  0D
	sla c                         ; 1A43  CB 21
	sla c                         ; 1A45  CB 21
	sla c                         ; 1A47  CB 21
L_1A49:
	ld b,0x00                     ; 1A49  06 00
	add hl,bc                     ; 1A4B  09
	pop bc                        ; 1A4C  C1
	nop                           ; 1A4D  00
L_1A4E:
	push bc                       ; 1A4E  C5
	push hl                       ; 1A4F  E5
L_1A50:
	push bc                       ; 1A50  C5
	call VDP_SET_WADDR            ; 1A51  CD 06 1C
	ld a,(de)                     ; 1A54  1A
	ld b,0x08                     ; 1A55  06 08
L_1A57:
	rla                           ; 1A57  17
	rr c                          ; 1A58  CB 19
	djnz L_1A57                   ; 1A5A  10 FB
	ld a,c                        ; 1A5C  79
	out (0x98),a                  ; 1A5D  D3 98
	inc de                        ; 1A5F  13
	ld bc,0xFFF8                  ; 1A60  01 F8 FF
	add hl,bc                     ; 1A63  09
	pop bc                        ; 1A64  C1
	dec c                         ; 1A65  0D
	jr nz,L_1A50                  ; 1A66  20 E8
	pop hl                        ; 1A68  E1
	jp L_1D34                     ; 1A69  C3 34 1D

L_1A6C:
	ld hl,ROOM_MAPS-0x1           ; 1A6C  21 46 68
	ld b,0x00                     ; 1A6F  06 00
L_1A71:
	and a                         ; 1A71  A7
	ret z                         ; 1A72  C8

	dec a                         ; 1A73  3D
	ld c,0x04                     ; 1A74  0E 04
	add hl,bc                     ; 1A76  09
	ld c,(hl)                     ; 1A77  4E
	inc hl                        ; 1A78  23
	inc hl                        ; 1A79  23
	add hl,bc                     ; 1A7A  09
	add hl,bc                     ; 1A7B  09
	add hl,bc                     ; 1A7C  09
	add hl,bc                     ; 1A7D  09
	jr L_1A71                     ; 1A7E  18 F1

D_1A80:			; данные 1A80..1A83 (4 байт)
	db	0xC9,0x00,0x06,0x18	; 1A80
L_1A84:
	xor a                         ; 1A84  AF
	bit 7,b                       ; 1A85  CB 78
	jr z,L_1A8B                   ; 1A87  28 02
	ld a,0x60                     ; 1A89  3E 60
L_1A8B:
	ld (L_1AA4+0x1),a             ; 1A8B  32 A5 1A
	ld a,b                        ; 1A8E  78
	and 0x7F                      ; 1A8F  E6 7F
	call L_1A6C                   ; 1A91  CD 6C 1A
	ld de,D_1D08                  ; 1A94  11 08 1D
	ld bc,0x04                    ; 1A97  01 04 00
	ldir                          ; 1A9A  ED B0
	inc hl                        ; 1A9C  23
	ld b,(hl)                     ; 1A9D  46
	inc hl                        ; 1A9E  23
L_1A9F:
	push bc                       ; 1A9F  C5
	ld a,(hl)                     ; 1AA0  7E
	ex af,af'                     ; 1AA1  08
	inc hl                        ; 1AA2  23
	ld a,(hl)                     ; 1AA3  7E
L_1AA4:
	add a,0x00                    ; 1AA4  C6 00
	ld c,a                        ; 1AA6  4F
	ex af,af'                     ; 1AA7  08
	inc hl                        ; 1AA8  23
	ld b,(hl)                     ; 1AA9  46
	inc hl                        ; 1AAA  23
	push bc                       ; 1AAB  C5
	push hl                       ; 1AAC  E5
	call L_1B02                   ; 1AAD  CD 02 1B
	pop hl                        ; 1AB0  E1
	pop bc                        ; 1AB1  C1
	ld a,(hl)                     ; 1AB2  7E
	inc hl                        ; 1AB3  23
	push hl                       ; 1AB4  E5
	call L_1ABD                   ; 1AB5  CD BD 1A
	pop hl                        ; 1AB8  E1
	pop bc                        ; 1AB9  C1
	djnz L_1A9F                   ; 1ABA  10 E3
	ret                           ; 1ABC  C9

L_1ABD:
	push af                       ; 1ABD  F5
	call SCR_ADDR_BIT13           ; 1ABE  CD 92 19
	pop af                        ; 1AC1  F1
L_1AC2:
	push hl                       ; 1AC2  E5
	call L_1DB8                   ; 1AC3  CD B8 1D
	cp 0x31                       ; 1AC6  FE 31
	jr z,L_1AD2                   ; 1AC8  28 08
	cp 0x51                       ; 1ACA  FE 51
	jr c,L_1AD4                   ; 1ACC  38 06
	cp 0x54                       ; 1ACE  FE 54
	jr nc,L_1AD4                  ; 1AD0  30 02
L_1AD2:
	ld (hl),0x20                  ; 1AD2  36 20
L_1AD4:
	ld b,a                        ; 1AD4  47
	call SPR_BANK_A89C            ; 1AD5  CD 4C 1B
	ld b,(hl)                     ; 1AD8  46
	inc hl                        ; 1AD9  23
	ld c,(hl)                     ; 1ADA  4E
	inc hl                        ; 1ADB  23
	ex de,hl                      ; 1ADC  EB
	pop hl                        ; 1ADD  E1
L_1ADE:
	push bc                       ; 1ADE  C5
	push hl                       ; 1ADF  E5
L_1AE0:
	push bc                       ; 1AE0  C5
	call L_1DCF                   ; 1AE1  CD CF 1D
	ld a,(de)                     ; 1AE4  1A
	ld bc,0x08                    ; 1AE5  01 08 00
	call VDP_FILL                 ; 1AE8  CD 11 1C
	ld a,0x08                     ; 1AEB  3E 08
	add a,l                       ; 1AED  85
	ld l,a                        ; 1AEE  6F
	inc de                        ; 1AEF  13
	pop bc                        ; 1AF0  C1
	dec c                         ; 1AF1  0D
	jr nz,L_1AE0                  ; 1AF2  20 EC
	pop hl                        ; 1AF4  E1
	inc h                         ; 1AF5  24
	pop bc                        ; 1AF6  C1
	djnz L_1ADE                   ; 1AF7  10 E5
	ret                           ; 1AF9  C9

D_1AFA:			; данные 1AFA..1B01 (8 байт)
	db	0xE7,0xE1,0x24,0xC1,0x10,0xE0,0xC9,0xC9	; 1AFA
L_1B02:
	push af                       ; 1B02  F5
	call SCR_ADDR_BIT14           ; 1B03  CD 70 1B
	pop af                        ; 1B06  F1
	push af                       ; 1B07  F5
	and 0x7F                      ; 1B08  E6 7F
	push hl                       ; 1B0A  E5
	ld b,a                        ; 1B0B  47
	call SPR_BANK_VAR             ; 1B0C  CD 52 1B
	ld b,(hl)                     ; 1B0F  46
	inc hl                        ; 1B10  23
	ld c,(hl)                     ; 1B11  4E
	inc hl                        ; 1B12  23
	ex de,hl                      ; 1B13  EB
	pop hl                        ; 1B14  E1
	pop af                        ; 1B15  F1
	and 0x80                      ; 1B16  E6 80
	jp z,L_1A41                   ; 1B18  CA 41 1A
	in a,(0x99)                   ; 1B1B  DB 99
VDP_WR_STRIDE8:
	push bc                       ; 1B1D  C5
	push hl                       ; 1B1E  E5
L_1B1F:
	ld a,l                        ; 1B1F  7D
	out (0x99),a                  ; 1B20  D3 99
	ld a,h                        ; 1B22  7C
	push de                       ; 1B23  D5
	out (0x99),a                  ; 1B24  D3 99
	ld de,0x08                    ; 1B26  11 08 00
	add hl,de                     ; 1B29  19
	pop de                        ; 1B2A  D1
	ld a,(de)                     ; 1B2B  1A
	out (0x98),a                  ; 1B2C  D3 98
	inc de                        ; 1B2E  13
	dec c                         ; 1B2F  0D
	jr nz,L_1B1F                  ; 1B30  20 ED
	pop hl                        ; 1B32  E1
	ld a,0x07                     ; 1B33  3E 07
	and l                         ; 1B35  A5
	cp 0x07                       ; 1B36  FE 07
	jr nz,L_1B3F                  ; 1B38  20 05
	ld a,l                        ; 1B3A  7D
	sub 0x08                      ; 1B3B  D6 08
	ld l,a                        ; 1B3D  6F
	inc h                         ; 1B3E  24
L_1B3F:
	inc l                         ; 1B3F  2C
	pop bc                        ; 1B40  C1
	djnz VDP_WR_STRIDE8           ; 1B41  10 DA
	ret                           ; 1B43  C9

SPR_HDR:
	call SPR_BANK_HI              ; 1B44  CD 58 1B
	ld b,(hl)                     ; 1B47  46
	inc hl                        ; 1B48  23
	ld a,(hl)                     ; 1B49  7E
	inc hl                        ; 1B4A  23
	ret                           ; 1B4B  C9

SPR_BANK_A89C:
	ld hl,SPR_DATA_8B9C           ; 1B4C  21 9C 8B
	xor a                         ; 1B4F  AF
	jr L_1B5D                     ; 1B50  18 0B

SPR_BANK_VAR:
	ld hl,SPR_DATA_8E76           ; 1B52  21 76 8E
	xor a                         ; 1B55  AF
	jr L_1B5D                     ; 1B56  18 05

SPR_BANK_HI:
	ld hl,SPR_BANK_294B           ; 1B58  21 4B 29
	ld a,0x00                     ; 1B5B  3E 00
L_1B5D:
	ld (L_1B6A),a                 ; 1B5D  32 6A 1B
	ld a,b                        ; 1B60  78
	ld d,0x00                     ; 1B61  16 00
L_1B63:
	and a                         ; 1B63  A7
	ret z                         ; 1B64  C8

	dec a                         ; 1B65  3D
	ld e,(hl)                     ; 1B66  5E
	inc hl                        ; 1B67  23
	ld b,(hl)                     ; 1B68  46
	inc hl                        ; 1B69  23
L_1B6A:
	nop                           ; 1B6A  00
	add hl,de                     ; 1B6B  19
	djnz L_1B6A                   ; 1B6C  10 FC
	jr L_1B63                     ; 1B6E  18 F3

SCR_ADDR_BIT14:
	ld a,c                        ; 1B70  79
	and 0xF8                      ; 1B71  E6 F8
	rrca                          ; 1B73  0F
	rrca                          ; 1B74  0F
	rrca                          ; 1B75  0F
	ld h,a                        ; 1B76  67
	ld a,b                        ; 1B77  78
	and 0xF8                      ; 1B78  E6 F8
	ld l,a                        ; 1B7A  6F
	ld a,c                        ; 1B7B  79
	and 0x07                      ; 1B7C  E6 07
	add a,l                       ; 1B7E  85
	ld l,a                        ; 1B7F  6F
	ld a,b                        ; 1B80  78
	and 0x07                      ; 1B81  E6 07
	ld b,a                        ; 1B83  47
	set 6,h                       ; 1B84  CB F4
	ret                           ; 1B86  C9

	ld hl,WORK_RAM+0x1A5          ; 1B87  21 4D 3C  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x1A5          ; 1B8A  11 4D 3C  ; в каноне +0x100 этот операнд стухший
	jr L_1B95                     ; 1B8D  18 06

D_1B8F:			; данные 1B8F..1B94 (6 байт)
	db	0x21,0x6D,0xF4,0x11,0x6D,0xF4	; 1B8F
L_1B95:
	ld bc,0x0120                  ; 1B95  01 20 01
	jr L_1BA3                     ; 1B98  18 09

D_1B9A:			; данные 1B9A..1BA2 (9 байт)
	db	0x21,0x4D,0xF3,0x11,0x4D,0xF3,0x01,0x40,0x02	; 1B9A
L_1BA3:
	ldir                          ; 1BA3  ED B0
	ret                           ; 1BA5  C9

	ld e,(ix-0x03)                ; 1BA6  DD 5E FD
	ld d,(ix-0x02)                ; 1BA9  DD 56 FE
	ld a,(D_1D08+0x18)            ; 1BAC  3A 20 1D  ; в каноне +0x100 этот операнд стухший
	ld b,a                        ; 1BAF  47
	ld a,(D_1D08+0x10)            ; 1BB0  3A 18 1D  ; в каноне +0x100 этот операнд стухший
	ld c,a                        ; 1BB3  4F
L_1BB4:
	push bc                       ; 1BB4  C5
	push de                       ; 1BB5  D5
	ld b,0x00                     ; 1BB6  06 00
	ldir                          ; 1BB8  ED B0
	pop de                        ; 1BBA  D1
	push hl                       ; 1BBB  E5
	ld hl,(D_1D08+0x12)           ; 1BBC  2A 1A 1D  ; в каноне +0x100 этот операнд стухший
	add hl,de                     ; 1BBF  19
	ex de,hl                      ; 1BC0  EB
	pop hl                        ; 1BC1  E1
	pop bc                        ; 1BC2  C1
	djnz L_1BB4                   ; 1BC3  10 EF
	ld (ix+0x06),e                ; 1BC5  DD 73 06
	ld (ix+0x07),d                ; 1BC8  DD 72 07
	ret                           ; 1BCB  C9

L_1BCC:
	ld b,(ix+0x02)                ; 1BCC  DD 46 02
	ld a,(ix+0x03)                ; 1BCF  DD 7E 03
	ld (L_1BE3+0x1),a             ; 1BD2  32 E4 1B
	ld e,a                        ; 1BD5  5F
	rlca                          ; 1BD6  07
	ld (L_1BF1+0x1),a             ; 1BD7  32 F2 1B
	dec e                         ; 1BDA  1D
	ld d,0x00                     ; 1BDB  16 00
	add hl,de                     ; 1BDD  19
	ld de,WORK_RAM+0x1            ; 1BDE  11 A9 3A  ; в каноне +0x100 этот операнд стухший
	ld c,b                        ; 1BE1  48
L_1BE2:
	nop                           ; 1BE2  00
L_1BE3:
	ld b,0x03                     ; 1BE3  06 03
L_1BE5:
	push bc                       ; 1BE5  C5
	ld c,(hl)                     ; 1BE6  4E
	ld b,0xD5                     ; 1BE7  06 D5
	ld a,(bc)                     ; 1BE9  0A
	ld (de),a                     ; 1BEA  12
	pop bc                        ; 1BEB  C1
	inc de                        ; 1BEC  13
	dec hl                        ; 1BED  2B
	djnz L_1BE5                   ; 1BEE  10 F5
	push bc                       ; 1BF0  C5
L_1BF1:
	ld bc,0x06                    ; 1BF1  01 06 00
	add hl,bc                     ; 1BF4  09
	pop bc                        ; 1BF5  C1
	dec c                         ; 1BF6  0D
	jr nz,L_1BE2                  ; 1BF7  20 E9
	ld hl,WORK_RAM+0x1            ; 1BF9  21 A9 3A  ; в каноне +0x100 этот операнд стухший
	ret                           ; 1BFC  C9

VDP_SET_RADDR:
	ld a,l                        ; 1BFD  7D
	out (0x99),a                  ; 1BFE  D3 99
	ld a,h                        ; 1C00  7C
	and 0x3F                      ; 1C01  E6 3F
	out (0x99),a                  ; 1C03  D3 99
	ret                           ; 1C05  C9

VDP_SET_WADDR:
	ld a,l                        ; 1C06  7D
	out (0x99),a                  ; 1C07  D3 99
	ld a,h                        ; 1C09  7C
	and 0x3F                      ; 1C0A  E6 3F
L_1C0C:
	or 0x40                       ; 1C0C  F6 40
	out (0x99),a                  ; 1C0E  D3 99
	ret                           ; 1C10  C9

VDP_FILL:
	push af                       ; 1C11  F5
	call VDP_SET_WADDR            ; 1C12  CD 06 1C
L_1C15:
	pop af                        ; 1C15  F1
	out (0x98),a                  ; 1C16  D3 98
	push af                       ; 1C18  F5
	dec bc                        ; 1C19  0B
	ld a,c                        ; 1C1A  79
	or b                          ; 1C1B  B0
	jr nz,L_1C15                  ; 1C1C  20 F7
	pop af                        ; 1C1E  F1
	ret                           ; 1C1F  C9

VDP_RD_BYTE:
	call VDP_SET_RADDR            ; 1C20  CD FD 1B
	ex (sp),hl                    ; 1C23  E3
	ex (sp),hl                    ; 1C24  E3
	in a,(0x98)                   ; 1C25  DB 98
	ret                           ; 1C27  C9

VDP_WR_BYTE:
	push af                       ; 1C28  F5
	call VDP_SET_WADDR            ; 1C29  CD 06 1C
	ex (sp),hl                    ; 1C2C  E3
	ex (sp),hl                    ; 1C2D  E3
	pop af                        ; 1C2E  F1
	out (0x98),a                  ; 1C2F  D3 98
	ret                           ; 1C31  C9

L_1C32:
	ex de,hl                      ; 1C32  EB
VDP_COPY_TO_VRAM:
	call VDP_SET_WADDR            ; 1C33  CD 06 1C
L_1C36:
	ld a,(de)                     ; 1C36  1A
	out (0x98),a                  ; 1C37  D3 98
	inc de                        ; 1C39  13
	dec bc                        ; 1C3A  0B
	ld a,c                        ; 1C3B  79
	or b                          ; 1C3C  B0
	jr nz,L_1C36                  ; 1C3D  20 F7
	ret                           ; 1C3F  C9

L_1C40:
	ld (L_1C72+0x1),a             ; 1C40  32 73 1C
	push bc                       ; 1C43  C5
	ld hl,(D_1D08+0xE)            ; 1C44  2A 16 1D
	ld a,(D_1D08+0x22)            ; 1C47  3A 2A 1D
	rlca                          ; 1C4A  07
	rlca                          ; 1C4B  07
	ld e,a                        ; 1C4C  5F
	ld d,0x00                     ; 1C4D  16 00
	and a                         ; 1C4F  A7
	sbc hl,de                     ; 1C50  ED 52
	ld (D_1D08+0xE),hl            ; 1C52  22 16 1D
	ld a,(D_1D08+0x16)            ; 1C55  3A 1E 1D
	ld b,a                        ; 1C58  47
	ld a,(D_1D08+0x18)            ; 1C59  3A 20 1D
	ld c,a                        ; 1C5C  4F
	pop de                        ; 1C5D  D1
L_1C5E:
	push bc                       ; 1C5E  C5
	push de                       ; 1C5F  D5
L_1C60:
	ld (hl),e                     ; 1C60  73
	inc hl                        ; 1C61  23
	ld (hl),d                     ; 1C62  72
	ld a,0x10                     ; 1C63  3E 10
	add a,d                       ; 1C65  82
	ld d,a                        ; 1C66  57
	inc hl                        ; 1C67  23
	ld a,(D_1D08+0x14)            ; 1C68  3A 1C 1D
	ld (hl),a                     ; 1C6B  77
	add a,0x04                    ; 1C6C  C6 04
	ld (D_1D08+0x14),a            ; 1C6E  32 1C 1D
	inc hl                        ; 1C71  23
L_1C72:
	ld (hl),0x0C                  ; 1C72  36 0C
	inc hl                        ; 1C74  23
	djnz L_1C60                   ; 1C75  10 E9
	pop de                        ; 1C77  D1
	ld a,0x10                     ; 1C78  3E 10
	add a,e                       ; 1C7A  83
	ld e,a                        ; 1C7B  5F
	pop bc                        ; 1C7C  C1
	dec c                         ; 1C7D  0D
	jr nz,L_1C5E                  ; 1C7E  20 DE
	ret                           ; 1C80  C9

L_1C81:
	push bc                       ; 1C81  C5
	srl c                         ; 1C82  CB 39
	jr nc,L_1C87                  ; 1C84  30 01
	inc c                         ; 1C86  0C
L_1C87:
	ld a,c                        ; 1C87  79
	ld (D_1D08+0x16),a            ; 1C88  32 1E 1D
	ld a,b                        ; 1C8B  78
	srl b                         ; 1C8C  CB 38
	srl b                         ; 1C8E  CB 38
	srl b                         ; 1C90  CB 38
	srl b                         ; 1C92  CB 38
	and 0x0F                      ; 1C94  E6 0F
	jr z,L_1C99                   ; 1C96  28 01
	inc b                         ; 1C98  04
L_1C99:
	ld a,b                        ; 1C99  78
	ld (D_1D08+0x18),a            ; 1C9A  32 20 1D
	xor a                         ; 1C9D  AF
L_1C9E:
	add a,c                       ; 1C9E  81
	djnz L_1C9E                   ; 1C9F  10 FD
	ld (D_1D08+0x22),a            ; 1CA1  32 2A 1D
	ld b,c                        ; 1CA4  41
	xor a                         ; 1CA5  AF
L_1CA6:
	add a,0x20                    ; 1CA6  C6 20
	djnz L_1CA6                   ; 1CA8  10 FC
	ld (D_1D08+0x12),a            ; 1CAA  32 1A 1D
	pop bc                        ; 1CAD  C1
	ret                           ; 1CAE  C9

D_1CAF:			; данные 1CAF..1CB3 (5 байт)
	db	0x07,0x32,0x18,0xD4,0xC9	; 1CAF
VDP_RD_STRIDE8:
	res 6,h                       ; 1CB4  CB B4
L_1CB6:
	push bc                       ; 1CB6  C5
	push hl                       ; 1CB7  E5
L_1CB8:
	ld a,l                        ; 1CB8  7D
	out (0x99),a                  ; 1CB9  D3 99
	ld a,h                        ; 1CBB  7C
	push de                       ; 1CBC  D5
	out (0x99),a                  ; 1CBD  D3 99
	ld de,0x08                    ; 1CBF  11 08 00
	add hl,de                     ; 1CC2  19
	pop de                        ; 1CC3  D1
	ex (sp),hl                    ; 1CC4  E3
	ex (sp),hl                    ; 1CC5  E3
	in a,(0x98)                   ; 1CC6  DB 98
	ld (de),a                     ; 1CC8  12
	inc de                        ; 1CC9  13
	dec c                         ; 1CCA  0D
	jr nz,L_1CB8                  ; 1CCB  20 EB
	pop hl                        ; 1CCD  E1
	ld a,0x07                     ; 1CCE  3E 07
	and l                         ; 1CD0  A5
	cp 0x07                       ; 1CD1  FE 07
	jr nz,L_1CDA                  ; 1CD3  20 05
	ld a,l                        ; 1CD5  7D
	sub 0x08                      ; 1CD6  D6 08
	ld l,a                        ; 1CD8  6F
	inc h                         ; 1CD9  24
L_1CDA:
	inc l                         ; 1CDA  2C
	pop bc                        ; 1CDB  C1
	djnz L_1CB6                   ; 1CDC  10 D8
	ret                           ; 1CDE  C9

KBD_SCAN:
	push bc                       ; 1CDF  C5
	ld a,c                        ; 1CE0  79
	and 0x07                      ; 1CE1  E6 07
	inc a                         ; 1CE3  3C
	ld b,a                        ; 1CE4  47
	ld a,c                        ; 1CE5  79
	and 0xF0                      ; 1CE6  E6 F0
	rrca                          ; 1CE8  0F
	rrca                          ; 1CE9  0F
	rrca                          ; 1CEA  0F
	rrca                          ; 1CEB  0F
	or 0xF0                       ; 1CEC  F6 F0
	out (0xAA),a                  ; 1CEE  D3 AA
	nop                           ; 1CF0  00
	in a,(0xA9)                   ; 1CF1  DB A9
	cpl                           ; 1CF3  2F
L_1CF4:
	rrca                          ; 1CF4  0F
	djnz L_1CF4                   ; 1CF5  10 FD
	pop bc                        ; 1CF7  C1
RET_STUB:
	ret                           ; 1CF8  C9

D_1CF9:			; данные 1CF9..1CFD (5 байт)
	db	0xC9,0x48,0x09,0xD6,0x08	; 1CF9
THUNK_CDC5_D00:
	ld d,0x00                     ; 1CFE  16 00
	jp D_15C4+0x1                 ; 1D00  C3 C5 15

THUNK_CDC5_D60:
	ld d,0x60                     ; 1D03  16 60
	jp D_15C4+0x1                 ; 1D05  C3 C5 15

D_1D08:			; данные 1D08..1D33 (44 байт)
	db	0x11,0x1B,0x15,0x17,0x11,0x50,0x70,0xB1,0x11,0x50,0x80,0xB1,0xF8,0xD3,0xE2,0xF7	; 1D08
	db	0x30,0x02,0x20,0x27,0x1C,0x38,0x01,0xC9,0x02,0xA7,0x10,0x50,0x90,0xD0,0x30,0x70	; 1D18
	db	0xB0,0xE0,0x02,0xD1,0x01,0x05,0x08,0x0D,0x02,0x07,0x11,0x0E	; 1D28
L_1D34:
	ld a,0x07                     ; 1D34  3E 07
	and l                         ; 1D36  A5
	cp 0x07                       ; 1D37  FE 07
	jr nz,L_1D40                  ; 1D39  20 05
	ld a,l                        ; 1D3B  7D
	sub 0x08                      ; 1D3C  D6 08
	ld l,a                        ; 1D3E  6F
	inc h                         ; 1D3F  24
L_1D40:
	inc l                         ; 1D40  2C
	pop bc                        ; 1D41  C1
	dec b                         ; 1D42  05
	jp nz,L_1A4E                  ; 1D43  C2 4E 1A
	ret                           ; 1D46  C9

L_1D47:
	ex de,hl                      ; 1D47  EB
	ld a,(D_1D08+0x12)            ; 1D48  3A 1A 1D
	ld c,a                        ; 1D4B  4F
	sub 0x10                      ; 1D4C  D6 10
	ld (L_1D86+0x1),a             ; 1D4E  32 87 1D
	ld l,(ix-0x03)                ; 1D51  DD 6E FD
	ld h,(ix-0x02)                ; 1D54  DD 66 FE
	push hl                       ; 1D57  E5
	ld a,(D_1D08+0x18)            ; 1D58  3A 20 1D
	ld b,a                        ; 1D5B  47
	xor a                         ; 1D5C  AF
L_1D5D:
	add a,c                       ; 1D5D  81
	djnz L_1D5D                   ; 1D5E  10 FD
	ld c,a                        ; 1D60  4F
	ld b,0x00                     ; 1D61  06 00
	add hl,bc                     ; 1D63  09
	ld (ix+0x06),l                ; 1D64  DD 75 06
	ld (ix+0x07),h                ; 1D67  DD 74 07
	pop hl                        ; 1D6A  E1
	ld c,(ix+0x02)                ; 1D6B  DD 4E 02
	ld b,(ix+0x03)                ; 1D6E  DD 46 03
L_1D71:
	push bc                       ; 1D71  C5
	push hl                       ; 1D72  E5
L_1D73:
	ld a,(de)                     ; 1D73  1A
	ld (hl),a                     ; 1D74  77
	inc de                        ; 1D75  13
	push bc                       ; 1D76  C5
	ld bc,0x10                    ; 1D77  01 10 00
	add hl,bc                     ; 1D7A  09
	pop bc                        ; 1D7B  C1
	djnz L_1D73                   ; 1D7C  10 F5
	pop hl                        ; 1D7E  E1
	ld a,0x0F                     ; 1D7F  3E 0F
	and l                         ; 1D81  A5
	cp 0x0F                       ; 1D82  FE 0F
	jr nz,L_1D8A                  ; 1D84  20 04
L_1D86:
	ld bc,0x10                    ; 1D86  01 10 00
	add hl,bc                     ; 1D89  09
L_1D8A:
	inc hl                        ; 1D8A  23
	pop bc                        ; 1D8B  C1
	dec c                         ; 1D8C  0D
	jr nz,L_1D71                  ; 1D8D  20 E2
	ret                           ; 1D8F  C9

L_1D90:
	ld hl,WORK_RAM+0x656          ; 1D90  21 FE 40  ; в каноне +0x100 этот операнд стухший
	ld (D_1D08+0xE),hl            ; 1D93  22 16 1D
	xor a                         ; 1D96  AF
	ld (D_1D08+0x14),a            ; 1D97  32 1C 1D
	ret                           ; 1D9A  C9

L_1D9B:
	ld hl,WORK_RAM+0x1A5          ; 1D9B  21 4D 3C  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x1A6          ; 1D9E  11 4E 3C  ; в каноне +0x100 этот операнд стухший
	ld bc,0x0120                  ; 1DA1  01 20 01
	ld (hl),0x00                  ; 1DA4  36 00
	ldir                          ; 1DA6  ED B0
	ret                           ; 1DA8  C9

L_1DA9:
	ld hl,WORK_RAM+0x2C5          ; 1DA9  21 6D 3D  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x2C6          ; 1DAC  11 6E 3D  ; в каноне +0x100 этот операнд стухший
	ld bc,0x0120                  ; 1DAF  01 20 01
	ld (hl),0x00                  ; 1DB2  36 00
	ldir                          ; 1DB4  ED B0
	ret                           ; 1DB6  C9

D_1DB7:			; данные 1DB7..1DB7 (1 байт)
	db	0xBD	; 1DB7
L_1DB8:
	ld hl,L_1DEC+0x1              ; 1DB8  21 ED 1D
	ld (hl),0x00                  ; 1DBB  36 00
	cp 0x55                       ; 1DBD  FE 55
	ret c                         ; 1DBF  D8

	sub 0x55                      ; 1DC0  D6 55
	ld (hl),0x40                  ; 1DC2  36 40
	cp 0x55                       ; 1DC4  FE 55
	ret c                         ; 1DC6  D8

	sub 0x55                      ; 1DC7  D6 55
	ld (hl),0x80                  ; 1DC9  36 80
	ret                           ; 1DCB  C9

D_1DCC:			; данные 1DCC..1DCE (3 байт)
	db	0x0A,0xC1,0xB0	; 1DCC
L_1DCF:
	push hl                       ; 1DCF  E5
	srl l                         ; 1DD0  CB 3D
	srl l                         ; 1DD2  CB 3D
	srl l                         ; 1DD4  CB 3D
	ld a,l                        ; 1DD6  7D
	sla h                         ; 1DD7  CB 24
	sla h                         ; 1DD9  CB 24
	sla h                         ; 1DDB  CB 24
	ld l,h                        ; 1DDD  6C
	ld h,0x00                     ; 1DDE  26 00
	ld c,l                        ; 1DE0  4D
	ld b,h                        ; 1DE1  44
	add hl,hl                     ; 1DE2  29
	add hl,bc                     ; 1DE3  09
	ld c,a                        ; 1DE4  4F
	ld b,0x00                     ; 1DE5  06 00
	add hl,bc                     ; 1DE7  09
	ld bc,WORK_RAM+0x1A5          ; 1DE8  01 4D 3C  ; в каноне +0x100 этот операнд стухший
	add hl,bc                     ; 1DEB  09
L_1DEC:
	ld a,0x00                     ; 1DEC  3E 00
	ld (hl),a                     ; 1DEE  77
	pop hl                        ; 1DEF  E1
	ret                           ; 1DF0  C9

L_1DF1:
	call L_1D9B                   ; 1DF1  CD 9B 1D
	jp L_159A                     ; 1DF4  C3 9A 15

L_1DF7:
	call L_1DA9                   ; 1DF7  CD A9 1D
	jp L_15A7                     ; 1DFA  C3 A7 15

D_1DFD:			; данные 1DFD..1EFF (259 байт)
	db	0xFF,0xF7,0xFF,0x00,0x80,0x40,0xC0,0x20,0xA0,0x60,0xE0,0x10,0x90,0x50,0xD0,0x30	; 1DFD
	db	0xB0,0x70,0xF0,0x08,0x88,0x48,0xC8,0x28,0xA8,0x68,0xE8,0x18,0x98,0x58,0xD8,0x38	; 1E0D
	db	0xB8,0x78,0xF8,0x04,0x84,0x44,0xC4,0x24,0xA4,0x64,0xE4,0x14,0x94,0x54,0xD4,0x34	; 1E1D
	db	0xB4,0x74,0xF4,0x0C,0x8C,0x4C,0xCC,0x2C,0xAC,0x6C,0xEC,0x1C,0x9C,0x5C,0xDC,0x3C	; 1E2D
	db	0xBC,0x7C,0xFC,0x02,0x82,0x42,0xC2,0x22,0xA2,0x62,0xE2,0x12,0x92,0x52,0xD2,0x32	; 1E3D
	db	0xB2,0x72,0xF2,0x0A,0x8A,0x4A,0xCA,0x2A,0xAA,0x6A,0xEA,0x1A,0x9A,0x5A,0xDA,0x3A	; 1E4D
	db	0xBA,0x7A,0xFA,0x06,0x86,0x46,0xC6,0x26,0xA6,0x66,0xE6,0x16,0x96,0x56,0xD6,0x36	; 1E5D
	db	0xB6,0x76,0xF6,0x0E,0x8E,0x4E,0xCE,0x2E,0xAE,0x6E,0xEE,0x1E,0x9E,0x5E,0xDE,0x3E	; 1E6D
	db	0xBE,0x7E,0xFE,0x01,0x81,0x41,0xC1,0x21,0xA1,0x61,0xE1,0x11,0x91,0x51,0xD1,0x31	; 1E7D
	db	0xB1,0x71,0xF1,0x09,0x89,0x49,0xC9,0x29,0xA9,0x69,0xE9,0x19,0x99,0x59,0xD9,0x39	; 1E8D
	db	0xB9,0x79,0xF9,0x05,0x85,0x45,0xC5,0x25,0xA5,0x65,0xE5,0x15,0x95,0x55,0xD5,0x35	; 1E9D
	db	0xB5,0x75,0xF5,0x0D,0x8D,0x4D,0xCD,0x2D,0xAD,0x6D,0xED,0x1D,0x9D,0x5D,0xDD,0x3D	; 1EAD
	db	0xBD,0x7D,0xFD,0x03,0x83,0x43,0xC3,0x23,0xA3,0x63,0xE3,0x13,0x93,0x53,0xD3,0x33	; 1EBD
	db	0xB3,0x73,0xF3,0x0B,0x8B,0x4B,0xCB,0x2B,0xAB,0x6B,0xEB,0x1B,0x9B,0x5B,0xDB,0x3B	; 1ECD
	db	0xBB,0x7B,0xFB,0x07,0x87,0x47,0xC7,0x27,0xA7,0x67,0xE7,0x17,0x97,0x57,0xD7,0x37	; 1EDD
	db	0xB7,0x77,0xF7,0x0F,0x8F,0x4F,0xCF,0x2F,0xAF,0x6F,0xEF,0x1F,0x9F,0x5F,0xDF,0x3F	; 1EED
	db	0xBF,0x7F,0xFF	; 1EFD
ATTR_ADDR:
	ld a,c                        ; 1F00  79
	and 0xF8                      ; 1F01  E6 F8
	ld c,a                        ; 1F03  4F
	ld a,b                        ; 1F04  78
	and 0xF8                      ; 1F05  E6 F8
	rra                           ; 1F07  1F
	rra                           ; 1F08  1F
	rra                           ; 1F09  1F
	ld l,c                        ; 1F0A  69
	ld h,0x00                     ; 1F0B  26 00
	ld b,h                        ; 1F0D  44
	add hl,hl                     ; 1F0E  29
	add hl,bc                     ; 1F0F  09
	ld bc,WORK_RAM+0x1A5          ; 1F10  01 4D 3C  ; в каноне +0x100 этот операнд стухший
	add hl,bc                     ; 1F13  09
	ld c,a                        ; 1F14  4F
	ld b,0x00                     ; 1F15  06 00
	add hl,bc                     ; 1F17  09
	ret                           ; 1F18  C9

L_1F19:
	ld b,0x20                     ; 1F19  06 20
	ld hl,0x5B00                  ; 1F1B  21 00 5B
L_1F1E:
	call VDP_RD_BYTE              ; 1F1E  CD 20 1C
	cp 0x60                       ; 1F21  FE 60
	jr nc,L_1F2A                  ; 1F23  30 05
	ld a,0xD1                     ; 1F25  3E D1
	call VDP_WR_BYTE              ; 1F27  CD 28 1C
L_1F2A:
	ld a,0x04                     ; 1F2A  3E 04
	add a,l                       ; 1F2C  85
	ld l,a                        ; 1F2D  6F
	djnz L_1F1E                   ; 1F2E  10 EE
	jp L_0C8C                     ; 1F30  C3 8C 0C

D_1F33:			; данные 1F33..1F35 (3 байт)
	db	0xFF,0xFF,0xFF	; 1F33
L_1F36:
	xor a                         ; 1F36  AF
	sbc hl,de                     ; 1F37  ED 52
	ld b,l                        ; 1F39  45
L_1F3A:
	ld (de),a                     ; 1F3A  12
	inc de                        ; 1F3B  13
	djnz L_1F3A                   ; 1F3C  10 FC
	ret                           ; 1F3E  C9

L_1F3F:
	push hl                       ; 1F3F  E5
	push de                       ; 1F40  D5
	push bc                       ; 1F41  C5
	ld hl,WORK_RAM+0x3E5          ; 1F42  21 8D 3E  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x3E6          ; 1F45  11 8E 3E  ; в каноне +0x100 этот операнд стухший
	ld bc,0x01F0                  ; 1F48  01 F0 01
	ld (hl),0x00                  ; 1F4B  36 00
	ldir                          ; 1F4D  ED B0
	pop bc                        ; 1F4F  C1
	pop de                        ; 1F50  D1
	pop hl                        ; 1F51  E1
	jp L_0F98                     ; 1F52  C3 98 0F

L_1F55:
	push bc                       ; 1F55  C5
	ld bc,0x03                    ; 1F56  01 03 00
	lddr                          ; 1F59  ED B8
	ld a,(hl)                     ; 1F5B  7E
	add a,0x60                    ; 1F5C  C6 60
	ld (de),a                     ; 1F5E  12
	dec de                        ; 1F5F  1B
	dec hl                        ; 1F60  2B
	pop bc                        ; 1F61  C1
	djnz L_1F55                   ; 1F62  10 F1
L_1F64:
	ld hl,WORK_RAM+0x5D6          ; 1F64  21 7E 40  ; в каноне +0x100 этот операнд стухший
	ld de,0x1B00                  ; 1F67  11 00 1B
	ld bc,0x80                    ; 1F6A  01 80 00
	call L_1C32                   ; 1F6D  CD 32 1C
	ld hl,WORK_RAM+0x658          ; 1F70  21 00 41  ; в каноне +0x100 этот операнд стухший
	ld de,0x3800                  ; 1F73  11 00 38
	ld bc,0x0800                  ; 1F76  01 00 08
	call L_1C32                   ; 1F79  CD 32 1C
	ld ix,WORK_RAM+0x81           ; 1F7C  DD 21 29 3B  ; в каноне +0x100 этот операнд стухший
	jp L_228E                     ; 1F80  C3 8E 22

D_1F83:			; данные 1F83..1F83 (1 байт)
	db	0xC9	; 1F83
KBD_CHK_F3B5:
	ld a,0xF3                     ; 1F84  3E F3
	out (0xAA),a                  ; 1F86  D3 AA
	in a,(0xA9)                   ; 1F88  DB A9
	bit 5,a                       ; 1F8A  CB 6F
	ret nz                        ; 1F8C  C0

	jp L_155D                     ; 1F8D  C3 5D 15

D_1F90:			; данные 1F90..1F91 (2 байт)
	db	0x70,0x45	; 1F90
L_1F92:
	ld a,(GAME_VARS+0xA)          ; 1F92  3A F4 0A
	cp 0x61                       ; 1F95  FE 61
	ret nc                        ; 1F97  D0

	ld bc,(GAME_VARS+0xA)         ; 1F98  ED 4B F4 0A
	jp L_1FA9                     ; 1F9C  C3 A9 1F

L_1F9F:
	ld a,(GAME_VARS+0xA)          ; 1F9F  3A F4 0A
	cp 0x60                       ; 1FA2  FE 60
	ret c                         ; 1FA4  D8

	ld bc,(GAME_VARS+0xA)         ; 1FA5  ED 4B F4 0A
L_1FA9:
	call SCR_ADDR_BIT14           ; 1FA9  CD 70 1B
	ld a,l                        ; 1FAC  7D
	and 0xF8                      ; 1FAD  E6 F8
	ld l,a                        ; 1FAF  6F
	ld de,0x0500                  ; 1FB0  11 00 05
	sbc hl,de                     ; 1FB3  ED 52
	ld (D_1F90),hl                ; 1FB5  22 90 1F
	ld de,0x08                    ; 1FB8  11 08 00
	and a                         ; 1FBB  A7
	sbc hl,de                     ; 1FBC  ED 52
	push hl                       ; 1FBE  E5
	ld de,0x8030                  ; 1FBF  11 30 80
	ld b,0x06                     ; 1FC2  06 06
L_1FC4:
	ld c,0x30                     ; 1FC4  0E 30
	push hl                       ; 1FC6  E5
	call VDP_SET_RADDR            ; 1FC7  CD FD 1B
L_1FCA:
	and a                         ; 1FCA  A7
	in a,(0x98)                   ; 1FCB  DB 98
	ld (de),a                     ; 1FCD  12
	inc de                        ; 1FCE  13
	dec c                         ; 1FCF  0D
	jr nz,L_1FCA                  ; 1FD0  20 F8
	pop hl                        ; 1FD2  E1
	inc h                         ; 1FD3  24
	djnz L_1FC4                   ; 1FD4  10 EE
	pop hl                        ; 1FD6  E1
	jp L_22AA                     ; 1FD7  C3 AA 22

SFX_64D7:
	push hl                       ; 1FDA  E5
	push bc                       ; 1FDB  C5
	ld hl,P1_SFX_64D7             ; 1FDC  21 D7 4E
	call L_03F5                   ; 1FDF  CD F5 03
	pop bc                        ; 1FE2  C1
	pop hl                        ; 1FE3  E1
	ret                           ; 1FE4  C9

SFX_64E6:
	ld hl,P1_SFX_64E6             ; 1FE5  21 E6 4E
	jp L_03F5                     ; 1FE8  C3 F5 03

D_1FEB:			; данные 1FEB..1FF1 (7 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 1FEB
SFX_64D7_x25:
	ld b,0x19                     ; 1FF2  06 19
L_1FF4:
	push bc                       ; 1FF4  C5
	ld hl,P1_SFX_64D7             ; 1FF5  21 D7 4E
	call L_03F5                   ; 1FF8  CD F5 03
	ld hl,0x1388                  ; 1FFB  21 88 13
L_1FFE:
	dec hl                        ; 1FFE  2B
	ld a,h                        ; 1FFF  7C
	or l                          ; 2000  B5
	jr nz,L_1FFE                  ; 2001  20 FB
	pop bc                        ; 2003  C1
	djnz L_1FF4                   ; 2004  10 EE
	jp SFX_64F5                   ; 2006  C3 9A 20

D_2009:			; данные 2009..200C (4 байт)
	db	0x00,0x00,0x08,0x00	; 2009
L_200D:
	ld a,0xD0                     ; 200D  3E D0
	ld (L_2389+0x1),a             ; 200F  32 8A 23
	ld de,0x8180                  ; 2012  11 80 81
	ld a,l                        ; 2015  7D
	ld c,0x20                     ; 2016  0E 20
	cp 0xA0                       ; 2018  FE A0
	jr z,L_2038                   ; 201A  28 1C
	ld c,0x28                     ; 201C  0E 28
	cp 0x98                       ; 201E  FE 98
	jr z,L_2038                   ; 2020  28 16
	cp 0xF8                       ; 2022  FE F8
	jr nz,L_2036                  ; 2024  20 10
	ld a,0xD1                     ; 2026  3E D1
	ld (L_2389+0x1),a             ; 2028  32 8A 23
	ld l,0x00                     ; 202B  2E 00
	inc h                         ; 202D  24
	ld a,e                        ; 202E  7B
	add a,0x08                    ; 202F  C6 08
	ld e,a                        ; 2031  5F
	ld c,0x28                     ; 2032  0E 28
	jr L_2038                     ; 2034  18 02

L_2036:
	ld c,0x30                     ; 2036  0E 30
L_2038:
	ld a,c                        ; 2038  79
	ld (L_2362+0x1),a             ; 2039  32 63 23
	srl a                         ; 203C  CB 3F
	srl a                         ; 203E  CB 3F
	srl a                         ; 2040  CB 3F
	ld (L_23A6+0x1),a             ; 2042  32 A7 23
	jp L_2356                     ; 2045  C3 56 23

D_2048:			; данные 2048..2048 (1 байт)
	db	0xDA	; 2048
L_2049:
	ld b,0x06                     ; 2049  06 06
L_204B:
	ld c,0x08                     ; 204B  0E 08
	call VDP_SET_RADDR            ; 204D  CD FD 1B
L_2050:
	and a                         ; 2050  A7
	in a,(0x98)                   ; 2051  DB 98
	ld (de),a                     ; 2053  12
	inc de                        ; 2054  13
	nop                           ; 2055  00
	nop                           ; 2056  00
	dec c                         ; 2057  0D
	jr nz,L_2050                  ; 2058  20 F6
	push hl                       ; 205A  E5
	ld hl,0x28                    ; 205B  21 28 00
	add hl,de                     ; 205E  19
	ex de,hl                      ; 205F  EB
	pop hl                        ; 2060  E1
	inc h                         ; 2061  24
	djnz L_204B                   ; 2062  10 E7
	ret                           ; 2064  C9

D_2065:			; данные 2065..206D (9 байт)
	db	0x42,0x00,0x86,0x00,0x82,0x00,0x06,0x00,0x46	; 2065
L_206E:
	ld c,0x30                     ; 206E  0E 30
	call VDP_SET_RADDR            ; 2070  CD FD 1B
L_2073:
	and a                         ; 2073  A7
	in a,(0x98)                   ; 2074  DB 98
	ld (de),a                     ; 2076  12
	inc de                        ; 2077  13
	nop                           ; 2078  00
	nop                           ; 2079  00
	dec c                         ; 207A  0D
	jr nz,L_2073                  ; 207B  20 F6
	ret                           ; 207D  C9

L_207E:
	ld a,(GAME_VARS+0x7)          ; 207E  3A F1 0A
	cp 0x01                       ; 2081  FE 01
	jr z,SFX_64AA                 ; 2083  28 09
	cp 0x04                       ; 2085  FE 04
	ret nz                        ; 2087  C0

SFX_64B9:
	ld hl,P1_SFX_64B9             ; 2088  21 B9 4E
	jp L_03F5                     ; 208B  C3 F5 03

SFX_64AA:
	ld hl,P1_SFX_64AA             ; 208E  21 AA 4E
	jp L_03F5                     ; 2091  C3 F5 03

SFX_64C8:
	ld hl,P1_SFX_64C8             ; 2094  21 C8 4E
	jp L_03F5                     ; 2097  C3 F5 03

SFX_64F5:
	ld hl,P1_SFX_64F5             ; 209A  21 F5 4E
	jp L_03F5                     ; 209D  C3 F5 03

D_20A0:			; данные 20A0..20A7 (8 байт)
	db	0xFB,0x00,0x00,0x00,0x08,0x00,0x00,0x07	; 20A0
L_20A8:
	push hl                       ; 20A8  E5
	ld b,(ix+0x02)                ; 20A9  DD 46 02
	ld a,b                        ; 20AC  78
	srl b                         ; 20AD  CB 38
	srl b                         ; 20AF  CB 38
	srl b                         ; 20B1  CB 38
	and 0x07                      ; 20B3  E6 07
	jr z,L_20B8                   ; 20B5  28 01
	inc b                         ; 20B7  04
L_20B8:
	ld hl,0x8278                  ; 20B8  21 78 82
	ld de,0x30                    ; 20BB  11 30 00
L_20BE:
	and a                         ; 20BE  A7
	sbc hl,de                     ; 20BF  ED 52
	djnz L_20BE                   ; 20C1  10 FB
	ex de,hl                      ; 20C3  EB
	pop hl                        ; 20C4  E1
	push ix                       ; 20C5  DD E5
	ld a,(D_20A0+0x5)             ; 20C7  3A A5 20
	add a,e                       ; 20CA  83
	ld e,a                        ; 20CB  5F
	ld a,(ix+0x02)                ; 20CC  DD 7E 02
	push de                       ; 20CF  D5
	pop ix                        ; 20D0  DD E1
	ld b,a                        ; 20D2  47
L_20D3:
	ld e,(hl)                     ; 20D3  5E
	inc hl                        ; 20D4  23
	ld d,(hl)                     ; 20D5  56
	inc hl                        ; 20D6  23
	ld c,(hl)                     ; 20D7  4E
	inc hl                        ; 20D8  23
	push bc                       ; 20D9  C5
	ld b,0x00                     ; 20DA  06 00
	ld a,(D_20A0+0x7)             ; 20DC  3A A7 20
L_20DF:
	cp 0x00                       ; 20DF  FE 00
	jr z,L_20EE                   ; 20E1  28 0B
	dec a                         ; 20E3  3D
	srl e                         ; 20E4  CB 3B
	rr d                          ; 20E6  CB 1A
	rr c                          ; 20E8  CB 19
	rr b                          ; 20EA  CB 18
	jr L_20DF                     ; 20EC  18 F1

L_20EE:
	ld a,e                        ; 20EE  7B
	or (ix+0x00)                  ; 20EF  DD B6 00
	ld (ix+0x00),a                ; 20F2  DD 77 00
	ld a,d                        ; 20F5  7A
	or (ix+0x08)                  ; 20F6  DD B6 08
	ld (ix+0x08),a                ; 20F9  DD 77 08
	ld a,c                        ; 20FC  79
	or (ix+0x10)                  ; 20FD  DD B6 10
	ld (ix+0x10),a                ; 2100  DD 77 10
	ld a,b                        ; 2103  78
	or (ix+0x18)                  ; 2104  DD B6 18
	ld (ix+0x18),a                ; 2107  DD 77 18
	pop bc                        ; 210A  C1
	ld a,ixl                      ; 210B  DD 7D
	and 0x07                      ; 210D  E6 07
	cp 0x07                       ; 210F  FE 07
	jr nz,L_2118                  ; 2111  20 05
	ld de,0x28                    ; 2113  11 28 00
	add ix,de                     ; 2116  DD 19
L_2118:
	inc ix                        ; 2118  DD 23
	djnz L_20D3                   ; 211A  10 B7
	pop ix                        ; 211C  DD E1
	ld hl,0x82D7                  ; 211E  21 D7 82
	ld c,0x04                     ; 2121  0E 04
	ld a,0x03                     ; 2123  3E 03
	ld (L_213C+0x1),a             ; 2125  32 3D 21
	ld (L_2144+0x1),a             ; 2128  32 45 21
	ld a,(ix+0x04)                ; 212B  DD 7E 04
	cp 0xA8                       ; 212E  FE A8
	jr nc,L_213C                  ; 2130  30 0A
	ld a,0x04                     ; 2132  3E 04
	ld (L_213C+0x1),a             ; 2134  32 3D 21
	ld a,0x02                     ; 2137  3E 02
	ld (L_2144+0x1),a             ; 2139  32 45 21
L_213C:
	ld b,0x04                     ; 213C  06 04
	ld a,0xF1                     ; 213E  3E F1
L_2140:
	ld (hl),a                     ; 2140  77
	inc hl                        ; 2141  23
	djnz L_2140                   ; 2142  10 FC
L_2144:
	ld de,0x02                    ; 2144  11 02 00
	add hl,de                     ; 2147  19
	dec c                         ; 2148  0D
	jr nz,L_213C                  ; 2149  20 F1
	ret                           ; 214B  C9

D_214C:			; данные 214C..2167 (28 байт)
	db	0xCC,0xD2,0xDD,0x7E,0xFE,0xDD,0x77,0x07,0xDD,0x7E,0xFD,0xDD,0x77,0x06,0xCD,0xA8	; 214C
	db	0xD7,0x01,0x09,0x00,0xDD,0x09,0xC9,0x00,0x00,0x18,0x00,0x20	; 215C
L_2168:
	ld (L_2197+0x1),bc            ; 2168  ED 43 98 21
	ld (L_21A0+0x1),a             ; 216C  32 A1 21
	and 0x7F                      ; 216F  E6 7F
	ld (ix+0x08),a                ; 2171  DD 77 08
	push bc                       ; 2174  C5
	ld b,a                        ; 2175  47
	call SPR_HDR                  ; 2176  CD 44 1B
	ld (L_219D+0x1),hl            ; 2179  22 9E 21
	ld (ix+0x02),b                ; 217C  DD 70 02
	ld (ix+0x03),a                ; 217F  DD 77 03
	ld a,b                        ; 2182  78
	neg                           ; 2183  ED 44
	pop bc                        ; 2185  C1
	add a,c                       ; 2186  81
	ld (ix+0x00),a                ; 2187  DD 77 00
	ld (ix+0x01),b                ; 218A  DD 70 01
	ld c,a                        ; 218D  4F
L_218E:
	call SCR_ADDR_BIT14           ; 218E  CD 70 1B
	ld (ix+0x04),l                ; 2191  DD 75 04
	ld (ix+0x05),h                ; 2194  DD 74 05
L_2197:
	ld bc,0x7750                  ; 2197  01 50 77
	call L_21CF                   ; 219A  CD CF 21
L_219D:
	ld hl,SPR_BANK_294B+0x2       ; 219D  21 4D 29
L_21A0:
	ld a,0x80                     ; 21A0  3E 80
	and 0x80                      ; 21A2  E6 80
	call nz,L_1BCC                ; 21A4  C4 CC 1B
	ld a,(ix-0x02)                ; 21A7  DD 7E FE
	ld (ix+0x07),a                ; 21AA  DD 77 07
	ld a,(ix-0x03)                ; 21AD  DD 7E FD
	ld (ix+0x06),a                ; 21B0  DD 77 06
	call L_20A8                   ; 21B3  CD A8 20
	ld bc,0x09                    ; 21B6  01 09 00
	add ix,bc                     ; 21B9  DD 09
	ret                           ; 21BB  C9

D_21BC:			; данные 21BC..21CE (19 байт)
	db	0x91,0xD6,0xBC,0xF5,0x11,0x08,0x01,0xA7,0xED,0x52,0xF1,0x28,0x2B,0x30,0x17,0x7C	; 21BC
	db	0xC6,0x06,0x67	; 21CC
L_21CF:
	call SCR_ADDR_BIT14           ; 21CF  CD 70 1B
	ld (D_20A0+0x7),a             ; 21D2  32 A7 20
	ld a,l                        ; 21D5  7D
	and 0x07                      ; 21D6  E6 07
	ld (D_20A0+0x5),a             ; 21D8  32 A5 20
	ld a,l                        ; 21DB  7D
	and 0xF8                      ; 21DC  E6 F8
	ld l,a                        ; 21DE  6F
	and a                         ; 21DF  A7
	ld de,0x0500                  ; 21E0  11 00 05
	sbc hl,de                     ; 21E3  ED 52
	push hl                       ; 21E5  E5
	ld a,(D_1F90)                 ; 21E6  3A 90 1F
	cp l                          ; 21E9  BD
	jr z,L_222A                   ; 21EA  28 3E
	ld a,(D_1F90+0x1)             ; 21EC  3A 91 1F
	ld h,a                        ; 21EF  67
	jr nc,L_220E                  ; 21F0  30 1C
	ld de,0x20                    ; 21F2  11 20 00
	add hl,de                     ; 21F5  19
	push hl                       ; 21F6  E5
	ld de,0x8060                  ; 21F7  11 60 80
	call L_2049                   ; 21FA  CD 49 20
	ld de,0x8030                  ; 21FD  11 30 80
	ld hl,0x8038                  ; 2200  21 38 80
	ld bc,0x0120                  ; 2203  01 20 01
	ldir                          ; 2206  ED B0
	pop hl                        ; 2208  E1
	call L_22D2                   ; 2209  CD D2 22
	jr L_222A                     ; 220C  18 1C

L_220E:
	ld de,0x08                    ; 220E  11 08 00
	and a                         ; 2211  A7
	sbc hl,de                     ; 2212  ED 52
	push hl                       ; 2214  E5
	ld de,0x8028                  ; 2215  11 28 80
	call L_2049                   ; 2218  CD 49 20
	ld hl,0x8147                  ; 221B  21 47 81
	ld de,0x814F                  ; 221E  11 4F 81
	ld bc,0x0120                  ; 2221  01 20 01
	lddr                          ; 2224  ED B8
	pop hl                        ; 2226  E1
	call L_22E4                   ; 2227  CD E4 22
L_222A:
	pop hl                        ; 222A  E1
	push hl                       ; 222B  E5
	ld a,(D_1F90+0x1)             ; 222C  3A 91 1F
	cp h                          ; 222F  BC
	push af                       ; 2230  F5
	ld de,0x08                    ; 2231  11 08 00
	and a                         ; 2234  A7
	sbc hl,de                     ; 2235  ED 52
	pop af                        ; 2237  F1
	jr z,L_226F                   ; 2238  28 35
	jr nc,L_2258                  ; 223A  30 1C
	ld a,h                        ; 223C  7C
	add a,0x05                    ; 223D  C6 05
	ld h,a                        ; 223F  67
	ld de,0x8150                  ; 2240  11 50 81
	push hl                       ; 2243  E5
	call L_206E                   ; 2244  CD 6E 20
	ld de,0x8030                  ; 2247  11 30 80
	ld hl,0x8060                  ; 224A  21 60 80
	ld bc,0x0120                  ; 224D  01 20 01
	ldir                          ; 2250  ED B0
	pop hl                        ; 2252  E1
	call L_230B                   ; 2253  CD 0B 23
	jr L_226F                     ; 2256  18 17

L_2258:
	nop                           ; 2258  00
	ld de,0x8000                  ; 2259  11 00 80
	push hl                       ; 225C  E5
	call L_206E                   ; 225D  CD 6E 20
	ld hl,0x811F                  ; 2260  21 1F 81
	ld de,0x814F                  ; 2263  11 4F 81
	ld bc,0x0120                  ; 2266  01 20 01
	lddr                          ; 2269  ED B8
	pop hl                        ; 226B  E1
	call L_231D                   ; 226C  CD 1D 23
L_226F:
	ld hl,0x8030                  ; 226F  21 30 80
	ld de,0x8180                  ; 2272  11 80 81
	ld bc,0x0120                  ; 2275  01 20 01
	ldir                          ; 2278  ED B0
	ld hl,0x82A6                  ; 227A  21 A6 82
	ld de,0x82D0                  ; 227D  11 D0 82
	ld bc,0x24                    ; 2280  01 24 00
	ldir                          ; 2283  ED B0
	pop hl                        ; 2285  E1
	ld (D_1F90),hl                ; 2286  22 90 1F
	ret                           ; 2289  C9

D_228A:			; данные 228A..228D (4 байт)
	db	0x00,0x00,0x00,0x00	; 228A
L_228E:
	ld hl,(D_1F90)                ; 228E  2A 90 1F
	ld de,0x08                    ; 2291  11 08 00
	and a                         ; 2294  A7
	sbc hl,de                     ; 2295  ED 52
	push hl                       ; 2297  E5
	call L_200D                   ; 2298  CD 0D 20
	pop hl                        ; 229B  E1
	ld a,(D_1A23)                 ; 229C  3A 23 1A
	and a                         ; 229F  A7
	ret z                         ; 22A0  C8

	ld a,h                        ; 22A1  7C
	add a,0x0C                    ; 22A2  C6 0C
	ld h,a                        ; 22A4  67
	jp L_200D                     ; 22A5  C3 0D 20

D_22A8:			; данные 22A8..22A9 (2 байт)
	db	0x00,0x00	; 22A8
L_22AA:
	ld bc,0x2000                  ; 22AA  01 00 20
	add hl,bc                     ; 22AD  09
	ld de,0x82A6                  ; 22AE  11 A6 82
	ld c,0x06                     ; 22B1  0E 06
L_22B3:
	push hl                       ; 22B3  E5
	ld b,0x06                     ; 22B4  06 06
L_22B6:
	push bc                       ; 22B6  C5
	call VDP_RD_BYTE              ; 22B7  CD 20 1C
	ld (de),a                     ; 22BA  12
	inc de                        ; 22BB  13
	ld bc,0x08                    ; 22BC  01 08 00
	add hl,bc                     ; 22BF  09
	pop bc                        ; 22C0  C1
	djnz L_22B6                   ; 22C1  10 F3
	pop hl                        ; 22C3  E1
	inc h                         ; 22C4  24
	dec c                         ; 22C5  0D
	jr nz,L_22B3                  ; 22C6  20 EB
	ret                           ; 22C8  C9

D_22C9:			; данные 22C9..22D1 (9 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF	; 22C9
L_22D2:
	ld de,0x82AC                  ; 22D2  11 AC 82
	call L_22F6                   ; 22D5  CD F6 22
	ld de,0x82A6                  ; 22D8  11 A6 82
	ld hl,0x82A7                  ; 22DB  21 A7 82
	ld bc,0x24                    ; 22DE  01 24 00
	ldir                          ; 22E1  ED B0
	ret                           ; 22E3  C9

L_22E4:
	ld de,0x82A5                  ; 22E4  11 A5 82
	call L_22F6                   ; 22E7  CD F6 22
	ld hl,0x82C8                  ; 22EA  21 C8 82
	ld de,0x82C9                  ; 22ED  11 C9 82
	ld bc,0x24                    ; 22F0  01 24 00
	lddr                          ; 22F3  ED B8
	ret                           ; 22F5  C9

L_22F6:
	ld bc,0x2000                  ; 22F6  01 00 20
	add hl,bc                     ; 22F9  09
	ld b,0x06                     ; 22FA  06 06
L_22FC:
	call VDP_RD_BYTE              ; 22FC  CD 20 1C
	ld (de),a                     ; 22FF  12
	push hl                       ; 2300  E5
	ld hl,0x06                    ; 2301  21 06 00
	add hl,de                     ; 2304  19
	ex de,hl                      ; 2305  EB
	pop hl                        ; 2306  E1
	inc h                         ; 2307  24
	djnz L_22FC                   ; 2308  10 F2
	ret                           ; 230A  C9

L_230B:
	ld de,0x82CA                  ; 230B  11 CA 82
	call L_232F                   ; 230E  CD 2F 23
	ld de,0x82A6                  ; 2311  11 A6 82
	ld hl,0x82AC                  ; 2314  21 AC 82
	ld bc,0x24                    ; 2317  01 24 00
	ldir                          ; 231A  ED B0
	ret                           ; 231C  C9

L_231D:
	ld de,0x82A0                  ; 231D  11 A0 82
	call L_232F                   ; 2320  CD 2F 23
	ld hl,0x82C3                  ; 2323  21 C3 82
	ld de,0x82C9                  ; 2326  11 C9 82
	ld bc,0x24                    ; 2329  01 24 00
	lddr                          ; 232C  ED B8
	ret                           ; 232E  C9

L_232F:
	ld bc,0x2000                  ; 232F  01 00 20
	add hl,bc                     ; 2332  09
	ld b,0x06                     ; 2333  06 06
L_2335:
	call VDP_RD_BYTE              ; 2335  CD 20 1C
	ld (de),a                     ; 2338  12
	inc de                        ; 2339  13
	push bc                       ; 233A  C5
	ld bc,0x08                    ; 233B  01 08 00
	add hl,bc                     ; 233E  09
	pop bc                        ; 233F  C1
	djnz L_2335                   ; 2340  10 F3
	ret                           ; 2342  C9

D_2343:			; данные 2343..2355 (19 байт)
	db	0x00,0x08,0x00,0x31,0x00,0x11,0x00,0x30,0x00,0x49,0x00,0x38,0x00,0xFF,0xC7,0xFF	; 2343
	db	0xEF,0xFF,0xC7	; 2353
L_2356:
	push hl                       ; 2356  E5
	ld b,0x06                     ; 2357  06 06
	ld a,h                        ; 2359  7C
	cp 0x4B                       ; 235A  FE 4B
	jr nz,L_2361                  ; 235C  20 03
	push bc                       ; 235E  C5
	jr L_236A                     ; 235F  18 09

L_2361:
	push bc                       ; 2361  C5
L_2362:
	ld bc,0x30                    ; 2362  01 30 00
	ld a,h                        ; 2365  7C
	cp 0x58                       ; 2366  FE 58
	jr c,L_2373                   ; 2368  38 09
L_236A:
	push hl                       ; 236A  E5
	ld hl,0x30                    ; 236B  21 30 00
	add hl,de                     ; 236E  19
	ex de,hl                      ; 236F  EB
	pop hl                        ; 2370  E1
	jr L_237F                     ; 2371  18 0C

L_2373:
	push hl                       ; 2373  E5
	push de                       ; 2374  D5
	call VDP_COPY_TO_VRAM         ; 2375  CD 33 1C
	pop de                        ; 2378  D1
	ld hl,0x30                    ; 2379  21 30 00
	add hl,de                     ; 237C  19
	ex de,hl                      ; 237D  EB
	pop hl                        ; 237E  E1
L_237F:
	inc h                         ; 237F  24
	pop bc                        ; 2380  C1
	djnz L_2361                   ; 2381  10 DE
	pop hl                        ; 2383  E1
	ld a,0x60                     ; 2384  3E 60
	ld (L_1C0C+0x1),a             ; 2386  32 0D 1C
L_2389:
	ld de,0x82D0                  ; 2389  11 D0 82
	ld c,0x06                     ; 238C  0E 06
	ld a,h                        ; 238E  7C
	cp 0x4B                       ; 238F  FE 4B
	jr nz,L_2396                  ; 2391  20 03
	push hl                       ; 2393  E5
	jr L_239D                     ; 2394  18 07

L_2396:
	push hl                       ; 2396  E5
	push de                       ; 2397  D5
	ld a,h                        ; 2398  7C
	cp 0x58                       ; 2399  FE 58
	jr c,L_23A6                   ; 239B  38 09
L_239D:
	push hl                       ; 239D  E5
	ld hl,0x06                    ; 239E  21 06 00
	add hl,de                     ; 23A1  19
	ex de,hl                      ; 23A2  EB
	pop hl                        ; 23A3  E1
	jr L_23B9                     ; 23A4  18 13

L_23A6:
	ld b,0x06                     ; 23A6  06 06
L_23A8:
	push bc                       ; 23A8  C5
	ld bc,0x08                    ; 23A9  01 08 00
	ld a,(de)                     ; 23AC  1A
	nop                           ; 23AD  00
	call VDP_FILL                 ; 23AE  CD 11 1C
	inc de                        ; 23B1  13
	ld bc,0x08                    ; 23B2  01 08 00
	add hl,bc                     ; 23B5  09
	pop bc                        ; 23B6  C1
	djnz L_23A8                   ; 23B7  10 EF
L_23B9:
	pop de                        ; 23B9  D1
	ld hl,0x06                    ; 23BA  21 06 00
	add hl,de                     ; 23BD  19
	ex de,hl                      ; 23BE  EB
	pop hl                        ; 23BF  E1
	inc h                         ; 23C0  24
	dec c                         ; 23C1  0D
	jr nz,L_2396                  ; 23C2  20 D2
	ld a,0x40                     ; 23C4  3E 40
	ld (L_1C0C+0x1),a             ; 23C6  32 0D 1C
	ret                           ; 23C9  C9

D_23CA:			; данные 23CA..23CE (5 байт)
	db	0x00,0xCD,0x68,0xD8,0xCD	; 23CA
L_23CF:
	ld a,0xC9                     ; 23CF  3E C9
	ld (L_20A8),a                 ; 23D1  32 A8 20
	ld bc,(GAME_VARS+0xA)         ; 23D4  ED 4B F4 0A
	ld a,0x00                     ; 23D8  3E 00
	call L_2168                   ; 23DA  CD 68 21
	call L_228E                   ; 23DD  CD 8E 22
	ld a,0xE5                     ; 23E0  3E E5
	ld (L_20A8),a                 ; 23E2  32 A8 20
	ret                           ; 23E5  C9

	jp L_228E                     ; 23E6  C3 8E 22  ; в каноне +0x100 этот операнд стухший

L_23E9:
	call L_16CD                   ; 23E9  CD CD 16
	ld hl,LOW_TILE_SRC            ; 23EC  21 F4 01
	ld (L_1736+0x1),hl            ; 23EF  22 37 17
	ld hl,D_240E                  ; 23F2  21 0E 24
	ld b,0x11                     ; 23F5  06 11
	ld de,0x1518                  ; 23F7  11 18 15
	call L_16F9                   ; 23FA  CD F9 16
	ld hl,HUD_TILES+0x8C          ; 23FD  21 E2 9B
	ld (L_1736+0x1),hl            ; 2400  22 37 17
	ld b,0x04                     ; 2403  06 04
	ld de,0x171A                  ; 2405  11 1A 17
	ld hl,D_240E+0x11             ; 2408  21 1F 24
	jp L_16F9                     ; 240B  C3 F9 16

D_240E:			; данные 240E..2423 (22 байт)
	db	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x18,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F	; 240E
	db	0x30,0x3B,0x43,0x42,0x41,0x00	; 241E
L_2424:
	call SFX_64E6                 ; 2424  CD E5 1F
	ld bc,0x2710                  ; 2427  01 10 27
L_242A:
	dec bc                        ; 242A  0B
	ld a,b                        ; 242B  78
	or c                          ; 242C  B1
	jr nz,L_242A                  ; 242D  20 FB
	ret                           ; 242F  C9

D_2430:			; данные 2430..2439 (10 байт)
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2430
MUS_START:
	ld hl,(D_256F+0x14)           ; 243A  2A 83 25
	ld (D_256F+0xA),hl            ; 243D  22 79 25
	ld hl,(D_256F+0x16)           ; 2440  2A 85 25
	ld (D_256F+0xC),hl            ; 2443  22 7B 25
	ld hl,(D_256F+0x18)           ; 2446  2A 87 25
	ld (D_256F+0xE),hl            ; 2449  22 7D 25
	ld hl,D_256F                  ; 244C  21 6F 25
	ld b,(hl)                     ; 244F  46
	inc hl                        ; 2450  23
L_2451:
	push bc                       ; 2451  C5
	ld a,(hl)                     ; 2452  7E
	inc hl                        ; 2453  23
	ld c,(hl)                     ; 2454  4E
	inc hl                        ; 2455  23
	call PSG_WR                   ; 2456  CD 69 25
	pop bc                        ; 2459  C1
	djnz L_2451                   ; 245A  10 F5
L_245C:
	ld bc,(D_256F+0x12)           ; 245C  ED 4B 81 25
L_2460:
	push bc                       ; 2460  C5
	ld b,0x09                     ; 2461  06 09
	ld c,0xF0                     ; 2463  0E F0
L_2465:
	ld a,c                        ; 2465  79
	out (0xAA),a                  ; 2466  D3 AA
	in a,(0xA9)                   ; 2468  DB A9
	cp 0xFF                       ; 246A  FE FF
	jp nz,L_255C                  ; 246C  C2 5C 25
	inc c                         ; 246F  0C
	djnz L_2465                   ; 2470  10 F3
	pop bc                        ; 2472  C1
	dec bc                        ; 2473  0B
	ld a,b                        ; 2474  78
	or c                          ; 2475  B1
	jr nz,L_2460                  ; 2476  20 E8
	ld hl,(D_256F+0xA)            ; 2478  2A 79 25
	ld a,(D_256F+0x9)             ; 247B  3A 78 25
	or 0x01                       ; 247E  F6 01
	ld (D_256F+0x9),a             ; 2480  32 78 25
	ld c,a                        ; 2483  4F
	ld a,0x07                     ; 2484  3E 07
	call PSG_WR                   ; 2486  CD 69 25
	ld a,(hl)                     ; 2489  7E
	cp 0xFE                       ; 248A  FE FE
	jr nz,L_2495                  ; 248C  20 07
	ld hl,(D_256F+0x14)           ; 248E  2A 83 25
	ld (D_256F+0xA),hl            ; 2491  22 79 25
	ld a,(hl)                     ; 2494  7E
L_2495:
	cp 0xFF                       ; 2495  FE FF
	jr z,L_24BF                   ; 2497  28 26
	sla a                         ; 2499  CB 27
	ld d,0x00                     ; 249B  16 00
	ld e,a                        ; 249D  5F
	push hl                       ; 249E  E5
	ld hl,(D_256F+0x10)           ; 249F  2A 7F 25
	add hl,de                     ; 24A2  19
	ld a,0x00                     ; 24A3  3E 00
	ld c,(hl)                     ; 24A5  4E
	call PSG_WR                   ; 24A6  CD 69 25
	ld a,0x01                     ; 24A9  3E 01
	inc hl                        ; 24AB  23
	ld c,(hl)                     ; 24AC  4E
	call PSG_WR                   ; 24AD  CD 69 25
	ld a,(D_256F+0x9)             ; 24B0  3A 78 25
	and 0xFE                      ; 24B3  E6 FE
	ld (D_256F+0x9),a             ; 24B5  32 78 25
	ld c,a                        ; 24B8  4F
	ld a,0x07                     ; 24B9  3E 07
	call PSG_WR                   ; 24BB  CD 69 25
	pop hl                        ; 24BE  E1
L_24BF:
	inc hl                        ; 24BF  23
	ld (D_256F+0xA),hl            ; 24C0  22 79 25
	ld hl,(D_256F+0xC)            ; 24C3  2A 7B 25
	ld a,(D_256F+0x9)             ; 24C6  3A 78 25
	or 0x02                       ; 24C9  F6 02
	ld (D_256F+0x9),a             ; 24CB  32 78 25
	ld c,a                        ; 24CE  4F
	ld a,0x07                     ; 24CF  3E 07
	call PSG_WR                   ; 24D1  CD 69 25
	ld a,(hl)                     ; 24D4  7E
	cp 0xFE                       ; 24D5  FE FE
	jr nz,L_24E0                  ; 24D7  20 07
	ld hl,(D_256F+0x16)           ; 24D9  2A 85 25
	ld (D_256F+0xC),hl            ; 24DC  22 7B 25
	ld a,(hl)                     ; 24DF  7E
L_24E0:
	cp 0xFF                       ; 24E0  FE FF
	jr z,L_250A                   ; 24E2  28 26
	sla a                         ; 24E4  CB 27
	ld d,0x00                     ; 24E6  16 00
	ld e,a                        ; 24E8  5F
	push hl                       ; 24E9  E5
	ld hl,(D_256F+0x10)           ; 24EA  2A 7F 25
	add hl,de                     ; 24ED  19
	ld a,0x02                     ; 24EE  3E 02
	ld c,(hl)                     ; 24F0  4E
	call PSG_WR                   ; 24F1  CD 69 25
	ld a,0x03                     ; 24F4  3E 03
	inc hl                        ; 24F6  23
	ld c,(hl)                     ; 24F7  4E
	call PSG_WR                   ; 24F8  CD 69 25
	ld a,(D_256F+0x9)             ; 24FB  3A 78 25
	and 0xFD                      ; 24FE  E6 FD
	ld (D_256F+0x9),a             ; 2500  32 78 25
	ld c,a                        ; 2503  4F
	ld a,0x07                     ; 2504  3E 07
	call PSG_WR                   ; 2506  CD 69 25
	pop hl                        ; 2509  E1
L_250A:
	inc hl                        ; 250A  23
	ld (D_256F+0xC),hl            ; 250B  22 7B 25
	ld hl,(D_256F+0xE)            ; 250E  2A 7D 25
	ld a,(D_256F+0x9)             ; 2511  3A 78 25
	or 0x04                       ; 2514  F6 04
	ld (D_256F+0x9),a             ; 2516  32 78 25
	ld c,a                        ; 2519  4F
	ld a,0x07                     ; 251A  3E 07
	call PSG_WR                   ; 251C  CD 69 25
	ld a,(hl)                     ; 251F  7E
	cp 0xFE                       ; 2520  FE FE
	jr nz,L_252B                  ; 2522  20 07
	ld hl,(D_256F+0x18)           ; 2524  2A 87 25
	ld (D_256F+0xE),hl            ; 2527  22 7D 25
	ld a,(hl)                     ; 252A  7E
L_252B:
	cp 0xFF                       ; 252B  FE FF
	jr z,L_2555                   ; 252D  28 26
	sla a                         ; 252F  CB 27
	ld d,0x00                     ; 2531  16 00
	ld e,a                        ; 2533  5F
	push hl                       ; 2534  E5
	ld hl,(D_256F+0x10)           ; 2535  2A 7F 25
	add hl,de                     ; 2538  19
	ld a,0x04                     ; 2539  3E 04
	ld c,(hl)                     ; 253B  4E
	call PSG_WR                   ; 253C  CD 69 25
	ld a,0x05                     ; 253F  3E 05
	inc hl                        ; 2541  23
	ld c,(hl)                     ; 2542  4E
	call PSG_WR                   ; 2543  CD 69 25
	ld a,(D_256F+0x9)             ; 2546  3A 78 25
	and 0xFB                      ; 2549  E6 FB
	ld (D_256F+0x9),a             ; 254B  32 78 25
	ld c,a                        ; 254E  4F
	ld a,0x07                     ; 254F  3E 07
	call PSG_WR                   ; 2551  CD 69 25
	pop hl                        ; 2554  E1
L_2555:
	inc hl                        ; 2555  23
	ld (D_256F+0xE),hl            ; 2556  22 7D 25
	jp L_245C                     ; 2559  C3 5C 24

L_255C:
	pop bc                        ; 255C  C1
	ld a,0x3F                     ; 255D  3E 3F
	ld (D_256F+0x9),a             ; 255F  32 78 25
	ld c,a                        ; 2562  4F
	ld a,0x07                     ; 2563  3E 07
	call PSG_WR                   ; 2565  CD 69 25
	ret                           ; 2568  C9

PSG_WR:
	out (0xA0),a                  ; 2569  D3 A0
	ld a,c                        ; 256B  79
	out (0xA1),a                  ; 256C  D3 A1
	ret                           ; 256E  C9

D_256F:			; данные 256F..28E6 (888 байт)
	db	0x04,0x07,0x3F,0x08,0x00,0x09,0x00,0x0A,0x00,0x3F,0x00,0x00,0x00,0x00,0x00,0x00	; 256F
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 257F
	dw	D_256F+0x376	; 2587  E5 28
	db	0x5C,0x0D,0x9C,0x0C,0xE7,0x0B,0x3C,0x0B,0x9A,0x0A,0x02,0x0A,0x72,0x09,0xEA,0x08	; 2589
	db	0x6A,0x08,0xF1,0x07,0x7F,0x07,0x13,0x07,0xAE,0x06,0x4E,0x06,0xF3,0x05,0x9E,0x05	; 2599
	db	0x4D,0x05,0x01,0x05,0xB9,0x04,0x75,0x04,0x35,0x04,0xF8,0x03,0xBF,0x03,0x89,0x03	; 25A9
	db	0x57,0x03,0x27,0x03,0xF9,0x02,0xCF,0x02,0xA6,0x02,0x80,0x02,0x5C,0x02,0x3A,0x02	; 25B9
	db	0x1A,0x02,0xFC,0x01,0xDF,0x01,0xC4,0x01,0xAB,0x01,0x93,0x01,0x7C,0x01,0x67,0x01	; 25C9
	db	0x53,0x01,0x40,0x01,0x2E,0x01,0x1D,0x01,0x0D,0x01,0xFE,0x00,0xEF,0x00,0xE2,0x00	; 25D9
	db	0xD5,0x00,0xC9,0x00,0xBE,0x00,0xB3,0x00,0xA9,0x00,0xA0,0x00,0x97,0x00,0x8E,0x00	; 25E9
	db	0x86,0x00,0x7F,0x00,0x77,0x00,0x71,0x00,0x6A,0x00,0x64,0x00,0x5F,0x00,0x59,0x00	; 25F9
	db	0x54,0x00,0x50,0x00,0x4B,0x00,0x47,0x00,0x43,0x00,0x3F,0x00,0x3B,0x00,0x38,0x00	; 2609
	db	0x35,0x00,0x32,0x00,0x2F,0x00,0x2C,0x00,0x2A,0x00,0x28,0x00,0x25,0x00,0x23,0x00	; 2619
	db	0x21,0x00,0x1F,0x00,0x1D,0x00,0x1C,0x00,0x1A,0x00,0x19,0x00,0x17,0x00,0x16,0x00	; 2629
	db	0x15,0x00,0x14,0x00,0x12,0x00,0x11,0x00,0x10,0x00,0x0F,0x00,0x0E,0x00,0x0E,0x00	; 2639
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 2649
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01	; 2659
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 2669
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 2679
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 2689
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 2699
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 26A9
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 26B9
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 26C9
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 26D9
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 26E9
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 26F9
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 2709
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 2719
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0xFE,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2729
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2739
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2749
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2759
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2769
	db	0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03	; 2779
	db	0xFF,0x01,0xFF,0x01,0xFF,0x01,0xFF,0x01,0xFF,0x0A,0xFF,0x0A,0xFF,0x0C,0xFF,0x0C	; 2789
	db	0xFF,0x06,0xFF,0x06,0xFF,0x01,0xFF,0x01,0xFF,0x06,0xFF,0x06,0xFF,0x03,0xFF,0x08	; 2799
	db	0xFF,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03	; 27A9
	db	0x03,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x0A,0x0A,0x0A,0x0A,0x0C,0x0C,0x0C	; 27B9
	db	0x0C,0x06,0x06,0x06,0x06,0x01,0x01,0x01,0x01,0x06,0x06,0x06,0x06,0x03,0x03,0x08	; 27C9
	db	0x08,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F	; 27D9
	db	0x03,0x0D,0x01,0x0D,0x01,0x0D,0x01,0x0D,0x01,0x16,0x0A,0x16,0x0A,0x18,0x0C,0x18	; 27E9
	db	0x0C,0x12,0x06,0x12,0x06,0x0D,0x01,0x0D,0x01,0x12,0x06,0x12,0x06,0x0F,0x03,0x14	; 27F9
	db	0x08,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0xFE,0x01,0x01,0x01,0x0C,0x08,0x08	; 2809
	db	0x06,0x05,0x01,0x01,0x01,0x0C,0x08,0x08,0x06,0x05,0x05,0x05,0x05,0x10,0x0C,0x0C	; 2819
	db	0x0A,0x08,0x05,0x05,0x05,0x10,0x0C,0x0C,0x0A,0x08,0x0A,0x0A,0x0A,0x15,0x11,0x11	; 2829
	db	0x0F,0x0D,0x0A,0x0A,0x0A,0x15,0x11,0x11,0x0F,0x0D,0x06,0x06,0x06,0x11,0x0D,0x0D	; 2839
	db	0x0C,0x0A,0x06,0x06,0x06,0x11,0x0D,0x0D,0x0C,0x0A,0x03,0x03,0x03,0x0E,0x0A,0x0A	; 2849
	db	0x08,0x06,0x03,0x03,0x03,0x0E,0x0A,0x0A,0x08,0x06,0x08,0x08,0x08,0x13,0x0F,0x0D	; 2859
	db	0x0F,0x0D,0x08,0x08,0x08,0x13,0x0F,0x0F,0x0D,0x0C,0x08,0x08,0x08,0x13,0x08,0x08	; 2869
	db	0x08,0x13,0xFE,0x11,0x0D,0x11,0x0D,0x11,0x0D,0x11,0x08,0x11,0x0D,0x11,0x0D,0x0F	; 2879
	db	0x0D,0x0F,0x08,0x11,0x05,0x11,0x05,0x11,0x05,0x11,0x0C,0x11,0x05,0x11,0x05,0x14	; 2889
	db	0x05,0x14,0x0C,0x0D,0x0A,0x0D,0x0A,0x0D,0x0A,0x0D,0x05,0x0D,0x0A,0x0D,0x0A,0x0F	; 2899
	db	0x0A,0x11,0x05,0x12,0x06,0x12,0x06,0x12,0x06,0x12,0x0D,0x12,0x06,0x12,0x06,0x11	; 28A9
	db	0x06,0x11,0x0D,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x0A,0x0F,0x03,0x0F,0x03,0x16	; 28B9
	db	0x03,0x18,0x0A,0x19,0x08,0x19,0x08,0x19,0x08,0x19,0x0D,0x19,0x08,0x19,0x08,0x19	; 28C9
	db	0x08,0x19,0x0D,0x18,0x08,0x18,0x08,0x18,0x08,0x18,0x08,0xFE,0xFF,0xFE	; 28D9
MUS_TRACK_1:
	ld hl,D_256F+0xE2             ; 28E7  21 51 26
	ld (D_256F+0x14),hl           ; 28EA  22 83 25
	ld hl,D_256F+0x1C3            ; 28ED  21 32 27
	ld (D_256F+0x16),hl           ; 28F0  22 85 25
	ld hl,0x0480                  ; 28F3  21 80 04
	ld (D_256F+0x12),hl           ; 28F6  22 81 25
	ld hl,D_256F+0x56             ; 28F9  21 C5 25
	ld (D_256F+0x10),hl           ; 28FC  22 7F 25
	ld a,0x0F                     ; 28FF  3E 0F
	ld (D_256F+0x4),a             ; 2901  32 73 25
	ld a,0x0E                     ; 2904  3E 0E
	ld (D_256F+0x6),a             ; 2906  32 75 25
	jp MUS_START                  ; 2909  C3 3A 24

D_290C:			; данные 290C..2918 (13 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 290C
MUS_TRACK_2:
	ld hl,D_256F+0x2A4            ; 2919  21 13 28
	ld (D_256F+0x14),hl           ; 291C  22 83 25
	ld hl,D_256F+0x30D            ; 291F  21 7C 28
	ld (D_256F+0x16),hl           ; 2922  22 85 25
	ld hl,0x04FF                  ; 2925  21 FF 04
	ld (D_256F+0x12),hl           ; 2928  22 81 25
	ld hl,D_256F+0x60             ; 292B  21 CF 25
	ld (D_256F+0x10),hl           ; 292E  22 7F 25
	ld a,0x0C                     ; 2931  3E 0C
	ld (D_256F+0x4),a             ; 2933  32 73 25
	ld a,0x0F                     ; 2936  3E 0F
	ld (D_256F+0x6),a             ; 2938  32 75 25
	jp MUS_START                  ; 293B  C3 3A 24

D_293E:			; данные 293E..294A (13 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 293E
