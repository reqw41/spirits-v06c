; Spirits (Topo Soft, 1987), MSX — STAGE2 [РАСКЛАДКА ВЕКТОРА-06Ц, кусок spirits2_tail]
; Источник — ref/msx/SPIRITS.2.payload в раскладке ОРИГИНАЛА (канон сдвинут на +0x100).
; Оригинал BB89..D000  ->  Вектор 0489..1900 (5240 байт)
; Достижимый код 4761 байт, остальное — db (графика/таблицы).
;
; Абсолютных адресов 655: символом 655, числом 0. Относительных 225.
; Раскладка и проверки — docs/v06-memory.md, tools/verify_v06.py.
; Адреса в комментариях — уже ВЕКТОРНЫЕ; пояснения к областям данных
; цитируют адреса канона +0x100 (это разбор, а не операнды).
;
; Сгенерировано tools/disasm_msx.py --v06 — правки вносить туда или в tools/entries.json.
; Наложения (цель внутри предыдущей инструкции): 1412

; Символы вне этого образа: резидентный слой (он копируется в верхнюю RAM
; из SPIRITS.1 — см. docs/msx-vdp-abi.md), копия в page 1, BIOS и цели,
; попавшие внутрь чужой инструкции. equ байтов не порождает — канон не
; трогается, а при смене org правится в одном месте.
L_0374:	equ	0x0374
ROOM_MAPS:	equ	0x6847
SPR_DATA_8E76:	equ	0x8E76
GFX_9940:	equ	0x9940
TEXT_ES:	equ	0x99E0
OBJ_TABLE_9AA2:	equ	0x9AA2
HUD_TILES:	equ	0x9B56
TEXT_SHORT:	equ	0x9BF9
VRAM_COLOR_ROWS:	equ	0x9C22
L_1907:	equ	0x1907
L_1921:	equ	0x1921
SCR_ADDR_BIT13:	equ	0x1992
L_19A0:	equ	0x19A0
L_19F2:	equ	0x19F2
D_1A23:	equ	0x1A23
L_1A24:	equ	0x1A24
L_1A49:	equ	0x1A49
L_1A6C:	equ	0x1A6C
L_1A84:	equ	0x1A84
L_1AC2:	equ	0x1AC2
L_1B02:	equ	0x1B02
VDP_WR_STRIDE8:	equ	0x1B1D
SPR_BANK_VAR:	equ	0x1B52
SCR_ADDR_BIT14:	equ	0x1B70
VDP_FILL:	equ	0x1C11
VDP_RD_BYTE:	equ	0x1C20
VDP_WR_BYTE:	equ	0x1C28
VDP_COPY_TO_VRAM:	equ	0x1C33
VDP_RD_STRIDE8:	equ	0x1CB4
KBD_SCAN:	equ	0x1CDF
RET_STUB:	equ	0x1CF8
THUNK_CDC5_D00:	equ	0x1CFE
THUNK_CDC5_D60:	equ	0x1D03
D_1D08:	equ	0x1D08
L_1DF1:	equ	0x1DF1
L_1DF7:	equ	0x1DF7
ATTR_ADDR:	equ	0x1F00
L_1F19:	equ	0x1F19
L_1F36:	equ	0x1F36
L_1F3F:	equ	0x1F3F
KBD_CHK_F3B5:	equ	0x1F84
L_1F92:	equ	0x1F92
L_1F9F:	equ	0x1F9F
SFX_64D7:	equ	0x1FDA
SFX_64E6:	equ	0x1FE5
SFX_64D7_x25:	equ	0x1FF2
L_207E:	equ	0x207E
SFX_64B9:	equ	0x2088
SFX_64C8:	equ	0x2094
SFX_64F5:	equ	0x209A
L_20A8:	equ	0x20A8
L_2168:	equ	0x2168
L_228E:	equ	0x228E
L_23CF:	equ	0x23CF
L_23E9:	equ	0x23E9
L_2424:	equ	0x2424
MUS_TRACK_1:	equ	0x28E7
MUS_TRACK_2:	equ	0x2919
SPR_BANK_294B:	equ	0x294B
WORK_RAM:	equ	0x3AA8

	org	0x0489

L_0489:
	call L_183E                   ; 0489  CD 3E 18
	call L_133D                   ; 048C  CD 3D 13
L_048F:
	call L_0834                   ; 048F  CD 34 08
	ld a,(D_04D4)                 ; 0492  3A D4 04
	or a                          ; 0495  B7
	jp nz,L_05F6                  ; 0496  C2 F6 05
	ld a,(L_0837+0x1)             ; 0499  3A 38 08
	cp 0x01                       ; 049C  FE 01
	jr z,L_04A5                   ; 049E  28 05
	call KBD_CHK_F3B5             ; 04A0  CD 84 1F
	jr L_048F                     ; 04A3  18 EA

L_04A5:
	call L_137B                   ; 04A5  CD 7B 13
	ld a,(GAME_VARS+0x8)          ; 04A8  3A F2 0A
	or a                          ; 04AB  B7
	jr z,L_04CC                   ; 04AC  28 1E
	call L_130C                   ; 04AE  CD 0C 13
	ld hl,GAME_VARS+0x10          ; 04B1  21 FA 0A
	ld de,GAME_VARS+0xA           ; 04B4  11 F4 0A
	ld bc,0x05                    ; 04B7  01 05 00
	ldir                          ; 04BA  ED B0
	call L_0C8C                   ; 04BC  CD 8C 0C
	ld a,0x01                     ; 04BF  3E 01
	call L_0D64                   ; 04C1  CD 64 0D
	ld (L_0837+0x1),a             ; 04C4  32 38 08
	call L_0ADC                   ; 04C7  CD DC 0A
	jr L_048F                     ; 04CA  18 C3

L_04CC:
	call L_150D                   ; 04CC  CD 0D 15
	call L_18AA                   ; 04CF  CD AA 18
	jr L_0489                     ; 04D2  18 B5

D_04D4:			; данные 04D4..04D4 (1 байт)
	db	0x00	; 04D4
L_04D5:
	ld iy,D_05BA+0x9              ; 04D5  FD 21 C3 05
	ld b,0x06                     ; 04D9  06 06
L_04DB:
	push bc                       ; 04DB  C5
	ld a,(GAME_VARS+0xC)          ; 04DC  3A F6 0A
	cp (iy+0x00)                  ; 04DF  FD BE 00
	jr nz,L_04F0                  ; 04E2  20 0C
	dec (iy+0x03)                 ; 04E4  FD 35 03
	call z,L_0525                 ; 04E7  CC 25 05
	xor a                         ; 04EA  AF
	call L_0518                   ; 04EB  CD 18 05
	jr L_050F                     ; 04EE  18 1F

L_04F0:
	ld a,(LEVEL_VARS)             ; 04F0  3A 7B 16
	cp (iy+0x00)                  ; 04F3  FD BE 00
	jr nz,L_04FF                  ; 04F6  20 07
	ld a,0x60                     ; 04F8  3E 60
	call L_0518                   ; 04FA  CD 18 05
	jr L_050F                     ; 04FD  18 10

L_04FF:
	ld a,(iy+0x04)                ; 04FF  FD 7E 04
	cp (iy+0x02)                  ; 0502  FD BE 02
	jr z,L_050F                   ; 0505  28 08
	ld (iy+0x02),a                ; 0507  FD 77 02
	ld a,r                        ; 050A  ED 5F
	ld (iy+0x03),a                ; 050C  FD 77 03
L_050F:
	ld bc,0x05                    ; 050F  01 05 00
	add iy,bc                     ; 0512  FD 09
	pop bc                        ; 0514  C1
	djnz L_04DB                   ; 0515  10 C4
	ret                           ; 0517  C9

L_0518:
	ld b,(iy+0x01)                ; 0518  FD 46 01
	ld c,(iy+0x02)                ; 051B  FD 4E 02
	add a,c                       ; 051E  81
	ld c,a                        ; 051F  4F
	ld a,0x1E                     ; 0520  3E 1E
	jp L_19A0                     ; 0522  C3 A0 19

L_0525:
	ld a,(iy+0x02)                ; 0525  FD 7E 02
	ld c,a                        ; 0528  4F
	ex af,af'                     ; 0529  08
	ld b,(iy+0x01)                ; 052A  FD 46 01
	ld d,0x40                     ; 052D  16 40
	push bc                       ; 052F  C5
	call L_0BD6                   ; 0530  CD D6 0B
	pop bc                        ; 0533  C1
	jr nc,L_0549                  ; 0534  30 13
	inc (iy+0x03)                 ; 0536  FD 34 03
	ex af,af'                     ; 0539  08
	add a,0x04                    ; 053A  C6 04
	ld (iy+0x02),a                ; 053C  FD 77 02
	ld c,a                        ; 053F  4F
	call L_11F2                   ; 0540  CD F2 11
	xor a                         ; 0543  AF
	cp e                          ; 0544  BB
	ret z                         ; 0545  C8

	jp L_0F25                     ; 0546  C3 25 0F

L_0549:
	ex af,af'                     ; 0549  08
	sub 0x24                      ; 054A  D6 24
	ld c,a                        ; 054C  4F
	ld b,(iy+0x01)                ; 054D  FD 46 01
	call SCR_ADDR_BIT13           ; 0550  CD 92 19
	ld a,0xED                     ; 0553  3E ED
	jp L_1AC2                     ; 0555  C3 C2 1A

L_0558:
	ld iy,D_05BA                  ; 0558  FD 21 BA 05
	ld b,0x03                     ; 055C  06 03
L_055E:
	push bc                       ; 055E  C5
	ld a,(GAME_VARS+0xC)          ; 055F  3A F6 0A
	cp (iy+0x00)                  ; 0562  FD BE 00
	jr nz,L_0570                  ; 0565  20 09
	xor a                         ; 0567  AF
	call L_0586                   ; 0568  CD 86 05
	call L_05E1                   ; 056B  CD E1 05
	jr L_057D                     ; 056E  18 0D

L_0570:
	ld a,(LEVEL_VARS)             ; 0570  3A 7B 16
	cp (iy+0x00)                  ; 0573  FD BE 00
	jr nz,L_057D                  ; 0576  20 05
	ld a,0x60                     ; 0578  3E 60
	call L_0586                   ; 057A  CD 86 05
L_057D:
	ld bc,0x03                    ; 057D  01 03 00
	add iy,bc                     ; 0580  FD 09
	pop bc                        ; 0582  C1
	djnz L_055E                   ; 0583  10 D9
	ret                           ; 0585  C9

L_0586:
	ld b,(iy+0x01)                ; 0586  FD 46 01
	ld c,0x58                     ; 0589  0E 58
	add a,c                       ; 058B  81
	ld c,a                        ; 058C  4F
	push bc                       ; 058D  C5
	ld a,(iy+0x02)                ; 058E  FD 7E 02
	xor 0x01                      ; 0591  EE 01
	ld (iy+0x02),a                ; 0593  FD 77 02
	add a,0x24                    ; 0596  C6 24
	call L_19A0                   ; 0598  CD A0 19
	pop bc                        ; 059B  C1
	call SCR_ADDR_BIT13           ; 059C  CD 92 19
	ld bc,0xFFD0                  ; 059F  01 D0 FF
	add hl,bc                     ; 05A2  09
	ld b,0x04                     ; 05A3  06 04
L_05A5:
	ld (hl),0x02                  ; 05A5  36 02
	inc hl                        ; 05A7  23
	djnz L_05A5                   ; 05A8  10 FB
	ld bc,0x14                    ; 05AA  01 14 00
	add hl,bc                     ; 05AD  09
	ld (hl),0x02                  ; 05AE  36 02
	inc hl                        ; 05B0  23
	ld (hl),0x16                  ; 05B1  36 16
	inc hl                        ; 05B3  23
	ld (hl),0x16                  ; 05B4  36 16
	inc hl                        ; 05B6  23
	ld (hl),0x02                  ; 05B7  36 02
	ret                           ; 05B9  C9

D_05BA:			; данные 05BA..05E0 (39 байт)
	db	0x27,0x98,0x00,0x51,0x18,0x01,0x53,0x50,0x00,0x0C,0x40,0x28,0x36,0x28,0x19,0x60	; 05BA
	db	0x20,0x1C,0x20,0x2D,0x50,0x20,0x35,0x20,0x30,0x40,0x28,0x4E,0x28,0x3F,0x38,0x20	; 05CA
	db	0x67,0x20,0x17,0x38,0x28,0x1B,0x28	; 05DA
L_05E1:
	ld a,(iy+0x01)                ; 05E1  FD 7E 01
	ld hl,(GAME_VARS+0xA)         ; 05E4  2A F4 0A
	add a,0x1C                    ; 05E7  C6 1C
	cp h                          ; 05E9  BC
	ret c                         ; 05EA  D8

	sub 0x28                      ; 05EB  D6 28
	cp h                          ; 05ED  BC
	ret nc                        ; 05EE  D0

	ld a,0x28                     ; 05EF  3E 28
	cp l                          ; 05F1  BD
	ret nc                        ; 05F2  D0

L_05F3:
	jp L_122C                     ; 05F3  C3 2C 12

L_05F6:
	call L_18AA                   ; 05F6  CD AA 18
	call L_19F2                   ; 05F9  CD F2 19
	ld a,0xC9                     ; 05FC  3E C9
	ld (L_228E),a                 ; 05FE  32 8E 22
	call L_0F47                   ; 0601  CD 47 0F
	call L_0F2B                   ; 0604  CD 2B 0F
	ld bc,(GAME_VARS+0xA)         ; 0607  ED 4B F4 0A
	ld a,0x0C                     ; 060B  3E 0C
	push bc                       ; 060D  C5
	call L_19A0                   ; 060E  CD A0 19
	pop bc                        ; 0611  C1
	ld a,c                        ; 0612  79
	add a,0x60                    ; 0613  C6 60
	ld c,a                        ; 0615  4F
	ld a,0x0B                     ; 0616  3E 0B
	call L_19A0                   ; 0618  CD A0 19
	call L_1A24                   ; 061B  CD 24 1A
	ld hl,0x2A                    ; 061E  21 2A 00
	ld (L_228E),a                 ; 0621  32 8E 22
	call MUS_TRACK_2              ; 0624  CD 19 29
	call L_18AA                   ; 0627  CD AA 18
	jp L_0489                     ; 062A  C3 89 04

DEAD_062D:			; данные 062D..0641 (21 байт)
; мёртвый кусок: декодируется как код (call D0A0 / 9 nop / call D3F8 /
; call CFAA / jp BB89), но D0A0, CFAA и BB89 — данные, а не начала
; процедур. Похоже на остаток прошлой сборки, чьи адреса не пережили сдвиг
; +0x100
	db	0xCD,0xA0,0xD0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xCD,0xF8,0xD3,0xCD	; 062D
	db	0xAA,0xCF,0xC3,0x89,0xBB	; 063D
L_0642:
	ld a,(OBJ_BLOCK_0809)         ; 0642  3A 09 08
	cp 0x01                       ; 0645  FE 01
	ret nz                        ; 0647  C0

	ld a,(OBJ_BLOCK_0809+0x5)     ; 0648  3A 0E 08
	sub 0x18                      ; 064B  D6 18
	cp (iy+0x01)                  ; 064D  FD BE 01
	ret nc                        ; 0650  D0

	add a,0x20                    ; 0651  C6 20
	cp (iy+0x01)                  ; 0653  FD BE 01
	ret c                         ; 0656  D8

	ld a,(OBJ_BLOCK_0809+0x4)     ; 0657  3A 0D 08
	sub 0x08                      ; 065A  D6 08
	cp (iy+0x00)                  ; 065C  FD BE 00
	ret nc                        ; 065F  D0

	add a,0x30                    ; 0660  C6 30
	cp (iy+0x00)                  ; 0662  FD BE 00
	ret c                         ; 0665  D8

	ld a,(iy+0x04)                ; 0666  FD 7E 04
	add a,0x32                    ; 0669  C6 32
	ld (iy+0x04),a                ; 066B  FD 77 04
	push iy                       ; 066E  FD E5
	ld iy,OBJ_BLOCK_0809          ; 0670  FD 21 09 08
	call L_06DD                   ; 0674  CD DD 06
	pop iy                        ; 0677  FD E1
	ret                           ; 0679  C9

L_067A:
	ld a,(OBJ_BLOCK_0809)         ; 067A  3A 09 08
	or a                          ; 067D  B7
	ret z                         ; 067E  C8

	ld iy,OBJ_BLOCK_0809          ; 067F  FD 21 09 08
	jr L_06A6                     ; 0683  18 21

L_0685:
	ld a,(OBJ_BLOCK_0809+0xB)     ; 0685  3A 14 08
	or a                          ; 0688  B7
	ret z                         ; 0689  C8

	ld iy,OBJ_BLOCK_0809+0xB      ; 068A  FD 21 14 08
	jr L_06A6                     ; 068E  18 16

L_0690:
	ld a,(OBJ_BLOCK_0809+0x16)    ; 0690  3A 1F 08
	or a                          ; 0693  B7
	ret z                         ; 0694  C8

	ld iy,OBJ_BLOCK_0809+0x16     ; 0695  FD 21 1F 08
	jr L_06A6                     ; 0699  18 0B

L_069B:
	ld a,(OBJ_BLOCK_0809+0x21)    ; 069B  3A 2A 08
	or a                          ; 069E  B7
	jp z,L_07B7                   ; 069F  CA B7 07
	ld iy,OBJ_BLOCK_0809+0x21     ; 06A2  FD 21 2A 08
L_06A6:
	ld a,(iy+0x01)                ; 06A6  FD 7E 01
	ld b,a                        ; 06A9  47
	ld a,(GAME_VARS+0xC)          ; 06AA  3A F6 0A
	cp b                          ; 06AD  B8
	jr z,L_06BA                   ; 06AE  28 0A
	ld d,0x60                     ; 06B0  16 60
	ld a,(LEVEL_VARS)             ; 06B2  3A 7B 16
	cp b                          ; 06B5  B8
	jr nz,L_06ED                  ; 06B6  20 35
	jr L_06DF                     ; 06B8  18 25

L_06BA:
	ld l,(iy+0x02)                ; 06BA  FD 6E 02
	ld h,(iy+0x03)                ; 06BD  FD 66 03
	call L_06F2                   ; 06C0  CD F2 06
	jr nc,L_06DD                  ; 06C3  30 18
	ld l,(iy+0x08)                ; 06C5  FD 6E 08
	ld h,(iy+0x09)                ; 06C8  FD 66 09
	call L_06F2                   ; 06CB  CD F2 06
	ld b,(iy+0x05)                ; 06CE  FD 46 05
	ld c,(iy+0x04)                ; 06D1  FD 4E 04
	ld a,(iy+0x06)                ; 06D4  FD 7E 06
	or (iy+0x07)                  ; 06D7  FD B6 07
	jp L_19A0                     ; 06DA  C3 A0 19

L_06DD:
	ld d,0x00                     ; 06DD  16 00
L_06DF:
	ld b,(iy+0x05)                ; 06DF  FD 46 05
	ld a,(iy+0x04)                ; 06E2  FD 7E 04
	add a,d                       ; 06E5  82
	ld c,a                        ; 06E6  4F
	ld a,(iy+0x06)                ; 06E7  FD 7E 06
	call L_15CF                   ; 06EA  CD CF 15
L_06ED:
	xor a                         ; 06ED  AF
	ld (iy+0x00),a                ; 06EE  FD 77 00
	ret                           ; 06F1  C9

L_06F2:
	jp (hl)                       ; 06F2  E9
L_06F3:
	ld b,(iy+0x05)                ; 06F3  FD 46 05
	ld c,(iy+0x04)                ; 06F6  FD 4E 04
	ld a,(iy+0x07)                ; 06F9  FD 7E 07
	ld e,(iy+0x0A)                ; 06FC  FD 5E 0A
	call L_0D6C                   ; 06FF  CD 6C 0D  ; в каноне +0x100 этот операнд стухший
	ld (iy+0x04),c                ; 0702  FD 71 04
	ld (iy+0x05),b                ; 0705  FD 70 05
	ret                           ; 0708  C9

L_0709:
	ld a,(OBJ_BLOCK_0809+0x21)    ; 0709  3A 2A 08  ; в каноне +0x100 этот операнд стухший
	cp 0x07                       ; 070C  FE 07
	scf                           ; 070E  37
	ret nz                        ; 070F  C0

	ccf                           ; 0710  3F
	ret                           ; 0711  C9

L_0712:
	call L_06F3                   ; 0712  CD F3 06  ; в каноне +0x100 этот операнд стухший
	ret nc                        ; 0715  D0

	ld a,c                        ; 0716  79
	cp 0x61                       ; 0717  FE 61
	ret                           ; 0719  C9

L_071A:
	ld d,0x1A                     ; 071A  16 1A
L_071C:
	ld a,(iy+0x06)                ; 071C  FD 7E 06
	dec a                         ; 071F  3D
	sub d                         ; 0720  92
	jr nz,L_0725                  ; 0721  20 02
	ld a,0x03                     ; 0723  3E 03
L_0725:
	add a,d                       ; 0725  82
	ld (iy+0x06),a                ; 0726  FD 77 06
	ld a,(iy+0x00)                ; 0729  FD 7E 00
	cp 0x01                       ; 072C  FE 01
	ret z                         ; 072E  C8

	ld (iy+0x00),0x01             ; 072F  FD 36 00 01
	jp L_122C                     ; 0733  C3 2C 12  ; в каноне +0x100 этот операнд стухший

L_0736:
	ld a,0x03                     ; 0736  3E 03
	jp L_1226                     ; 0738  C3 26 12  ; в каноне +0x100 этот операнд стухший

L_073B:
	ld a,(OBJ_BLOCK_0809+0x21)    ; 073B  3A 2A 08  ; в каноне +0x100 этот операнд стухший
	inc a                         ; 073E  3C
	ld (OBJ_BLOCK_0809+0x21),a    ; 073F  32 2A 08  ; в каноне +0x100 этот операнд стухший
	cp 0x04                       ; 0742  FE 04
	call z,L_0768                 ; 0744  CC 68 07  ; в каноне +0x100 этот операнд стухший
	cpl                           ; 0747  2F
	rrca                          ; 0748  0F
	and 0x01                      ; 0749  E6 01
	add a,0x22                    ; 074B  C6 22
	ld (iy+0x06),a                ; 074D  FD 77 06
	ret                           ; 0750  C9

L_0751:
	ld d,0x1E                     ; 0751  16 1E
	call L_071C                   ; 0753  CD 1C 07  ; в каноне +0x100 этот операнд стухший
	call L_0BBF                   ; 0756  CD BF 0B  ; в каноне +0x100 этот операнд стухший
	jr nc,L_0763                  ; 0759  30 08
	ld a,(OBJ_BLOCK_0809+0x1A)    ; 075B  3A 23 08  ; в каноне +0x100 этот операнд стухший
	add a,0x04                    ; 075E  C6 04
	ld (OBJ_BLOCK_0809+0x1A),a    ; 0760  32 23 08  ; в каноне +0x100 этот операнд стухший
L_0763:
	ld a,0x0E                     ; 0763  3E 0E
	jp L_1226                     ; 0765  C3 26 12  ; в каноне +0x100 этот операнд стухший

L_0768:
	ld (OBJ_BLOCK_0809+0xB),a     ; 0768  32 14 08  ; в каноне +0x100 этот операнд стухший
	ld a,(OBJ_BLOCK_0809+0x22)    ; 076B  3A 2B 08  ; в каноне +0x100 этот операнд стухший
	ld (OBJ_BLOCK_0809+0xC),a     ; 076E  32 15 08  ; в каноне +0x100 этот операнд стухший
	ld hl,(OBJ_BLOCK_0809+0x25)   ; 0771  2A 2E 08  ; в каноне +0x100 этот операнд стухший
	ld a,l                        ; 0774  7D
	sub 0x09                      ; 0775  D6 09
	ld l,a                        ; 0777  6F
	ld a,(OBJ_BLOCK_0809+0x28)    ; 0778  3A 31 08  ; в каноне +0x100 этот операнд стухший
	ld (OBJ_BLOCK_0809+0x12),a    ; 077B  32 1B 08  ; в каноне +0x100 этот операнд стухший
	or a                          ; 077E  B7
	jr z,L_0783                   ; 077F  28 02
	ld a,0x18                     ; 0781  3E 18
L_0783:
	add a,h                       ; 0783  84
	sub 0x04                      ; 0784  D6 04
	ld h,a                        ; 0786  67
	ld (OBJ_BLOCK_0809+0xF),hl    ; 0787  22 18 08  ; в каноне +0x100 этот операнд стухший
	ld a,0x04                     ; 078A  3E 04
	ret                           ; 078C  C9

L_078D:
	ld a,ixl                      ; 078D  DD 7D
	cp 0x81                       ; 078F  FE 81
	ret nc                        ; 0791  D0

	ld a,(GAME_VARS+0xB)          ; 0792  3A F5 0A
	ld h,0x18                     ; 0795  26 18
	cp 0x54                       ; 0797  FE 54
	jr nc,L_079C                  ; 0799  30 01
	ld h,d                        ; 079B  62
L_079C:
	ld a,h                        ; 079C  7C
	cpl                           ; 079D  2F
	and 0x80                      ; 079E  E6 80
	ld e,a                        ; 07A0  5F
	ld a,r                        ; 07A1  ED 5F
	ld d,a                        ; 07A3  57
	and 0x3F                      ; 07A4  E6 3F
	cp 0x03                       ; 07A6  FE 03
	ccf                           ; 07A8  3F
	ret nc                        ; 07A9  D0

	ld b,a                        ; 07AA  47
	ld a,(D_07B6)                 ; 07AB  3A B6 07
	dec a                         ; 07AE  3D
	ld (D_07B6),a                 ; 07AF  32 B6 07
	cp 0x01                       ; 07B2  FE 01
	ld a,b                        ; 07B4  78
	ret                           ; 07B5  C9

D_07B6:			; данные 07B6..07B6 (1 байт)
	db	0xE3	; 07B6
L_07B7:
	ld a,(OBJ_BLOCK_0809+0xB)     ; 07B7  3A 14 08
	or a                          ; 07BA  B7
	ret nz                        ; 07BB  C0

	ld a,(OBJ_BLOCK_0809+0x16)    ; 07BC  3A 1F 08
	or a                          ; 07BF  B7
	ret nz                        ; 07C0  C0

	ld d,0x98                     ; 07C1  16 98
	call L_078D                   ; 07C3  CD 8D 07
	ret nc                        ; 07C6  D0

	and 0x01                      ; 07C7  E6 01
	jp z,L_07EF                   ; 07C9  CA EF 07
	ld a,(GAME_VARS+0xC)          ; 07CC  3A F6 0A
	ld (OBJ_BLOCK_0809+0x22),a    ; 07CF  32 2B 08
	ld a,e                        ; 07D2  7B
	ld (OBJ_BLOCK_0809+0x28),a    ; 07D3  32 31 08
	ld a,d                        ; 07D6  7A
	and 0x40                      ; 07D7  E6 40
	rrca                          ; 07D9  0F
	rrca                          ; 07DA  0F
	ld d,a                        ; 07DB  57
	ld a,(GAME_VARS+0xA)          ; 07DC  3A F4 0A
	cp 0x30                       ; 07DF  FE 30
	jr c,L_07E5                   ; 07E1  38 02
	sub d                         ; 07E3  92
	inc a                         ; 07E4  3C
L_07E5:
	ld l,a                        ; 07E5  6F
	ld (OBJ_BLOCK_0809+0x25),hl   ; 07E6  22 2E 08
	ld a,0x01                     ; 07E9  3E 01
	ld (OBJ_BLOCK_0809+0x21),a    ; 07EB  32 2A 08
	ret                           ; 07EE  C9

L_07EF:
	ld a,0x01                     ; 07EF  3E 01
	ld (OBJ_BLOCK_0809+0x16),a    ; 07F1  32 1F 08
	ld a,0x21                     ; 07F4  3E 21
	ld (OBJ_BLOCK_0809+0x1C),a    ; 07F6  32 25 08
	ld a,(GAME_VARS+0xC)          ; 07F9  3A F6 0A
	ld (OBJ_BLOCK_0809+0x17),a    ; 07FC  32 20 08
	ld l,0x50                     ; 07FF  2E 50
	ld (OBJ_BLOCK_0809+0x1A),hl   ; 0801  22 23 08
	ld a,e                        ; 0804  7B
	ld (OBJ_BLOCK_0809+0x1D),a    ; 0805  32 26 08
	ret                           ; 0808  C9

OBJ_BLOCK_0809:			; данные 0809..0833 (43 байт)
; блок состояния объектов: 4 записи по 0x0B байт, C009..C034. База берётся
; из BE70/BE7F/BE8A/BE95/BEA2 (ld iy,C009 / C014 / C01F / C02A). Поля
; iy+2/3 и iy+8/9 читаются в hl (BEBA..BEC9) и уходят в call (hl) — это 8
; указателей на обработчики. ВСЕ ВОСЕМЬ СТУХЛИ: сверка с кассетой
; показывает, что инструмент сдвига данные не трогал вовсе, и указатели
; остались от раскладки 82A0 (см. docs/msx-relocation.md)
	db	0x00,0x16	; 0809
	dw	L_06F3	; 080B  F3 06
	db	0x46,0xFF,0x1B,0x00	; 080D
	dw	L_071A	; 0811  1A 07
	db	0x00,0x00,0x0C	; 0813
	dw	L_06F3	; 0816  F3 06
	db	0x48,0xAA,0x26,0x80	; 0818
	dw	L_0736	; 081C  36 07
	db	0x08,0x00,0x16	; 081E
	dw	L_0712	; 0821  12 07
	db	0x50,0xFC,0x20,0x00	; 0823
	dw	L_0751	; 0827  51 07
	db	0x08,0x00,0x0C	; 0829
	dw	L_0709	; 082C  09 07
	db	0x51,0x18,0x22,0x80	; 082E
	dw	L_073B	; 0832  3B 07
L_0834:
	call L_19F2                   ; 0834  CD F2 19
L_0837:
	ld a,0x00                     ; 0837  3E 00
	or a                          ; 0839  B7
	jr nz,L_0841                  ; 083A  20 05
	call L_0A60                   ; 083C  CD 60 0A
	jr L_084C                     ; 083F  18 0B

L_0841:
	dec a                         ; 0841  3D
	ld (L_0837+0x1),a             ; 0842  32 38 08
	ld bc,(GAME_VARS+0xA)         ; 0845  ED 4B F4 0A
	call L_15D0                   ; 0849  CD D0 15
L_084C:
	call L_0883                   ; 084C  CD 83 08
	call L_10DB                   ; 084F  CD DB 10
	call L_067A                   ; 0852  CD 7A 06
	call L_1275                   ; 0855  CD 75 12
	call L_04D5                   ; 0858  CD D5 04
	call L_0558                   ; 085B  CD 58 05
	call L_12E0                   ; 085E  CD E0 12
	call L_0690                   ; 0861  CD 90 06
	call L_069B                   ; 0864  CD 9B 06
	call L_0685                   ; 0867  CD 85 06
	ld a,(GAME_VARS+0xC)          ; 086A  3A F6 0A
	ld b,a                        ; 086D  47
	ld a,(LEVEL_VARS)             ; 086E  3A 7B 16
	cp b                          ; 0871  B8
	jr nz,L_0879                  ; 0872  20 05
	ld a,0x01                     ; 0874  3E 01
	ld (D_1A23),a                 ; 0876  32 23 1A
L_0879:
	call L_1A24                   ; 0879  CD 24 1A
	xor a                         ; 087C  AF
	ld (D_1A23),a                 ; 087D  32 23 1A
	jp L_0DE3                     ; 0880  C3 E3 0D

L_0883:
	ld a,(LEVEL_VARS+0x7)         ; 0883  3A 82 16
	or a                          ; 0886  B7
	ret z                         ; 0887  C8

	ld hl,L_08FB                  ; 0888  21 FB 08
	push hl                       ; 088B  E5
	ld a,0xF0                     ; 088C  3E F0
	out (0xAA),a                  ; 088E  D3 AA
	nop                           ; 0890  00
	in a,(0xA9)                   ; 0891  DB A9
	and 0x3E                      ; 0893  E6 3E
	cp 0x3E                       ; 0895  FE 3E
	jr nz,L_089F                  ; 0897  20 06
L_0899:
	ld a,0x00                     ; 0899  3E 00
	ld c,0x00                     ; 089B  0E 00
	jr L_08A1                     ; 089D  18 02

L_089F:
	ld c,0x01                     ; 089F  0E 01
L_08A1:
	ld (L_08EE+0x1),a             ; 08A1  32 EF 08
	cp 0x3C                       ; 08A4  FE 3C
	jr z,L_08D0                   ; 08A6  28 28
	cp 0x3A                       ; 08A8  FE 3A
	jr z,L_08DA                   ; 08AA  28 2E
	cp 0x36                       ; 08AC  FE 36
	jr z,L_08C6                   ; 08AE  28 16
	cp 0x2E                       ; 08B0  FE 2E
	jr z,L_08BC                   ; 08B2  28 08
	cp 0x1E                       ; 08B4  FE 1E
	ret nz                        ; 08B6  C0

	ld a,(OBJ_ARRAY_14BF+0x20)    ; 08B7  3A DF 14
	jr L_08E4                     ; 08BA  18 28

L_08BC:
	ld a,(OBJ_ARRAY_14BF+0x9)     ; 08BC  3A C8 14
	dec a                         ; 08BF  3D
	ret z                         ; 08C0  C8

	ld a,(OBJ_ARRAY_14BF+0x6)     ; 08C1  3A C5 14
	jr L_08E4                     ; 08C4  18 1E

L_08C6:
	ld a,(OBJ_ARRAY_14BF+0x16)    ; 08C6  3A D5 14
	dec a                         ; 08C9  3D
	ret z                         ; 08CA  C8

	ld a,(OBJ_ARRAY_14BF+0x13)    ; 08CB  3A D2 14
	jr L_08E4                     ; 08CE  18 14

L_08D0:
	ld a,(LEVEL_VARS+0x9)         ; 08D0  3A 84 16
	or a                          ; 08D3  B7
	ret nz                        ; 08D4  C0

	ld a,(LEVEL_VARS+0x3)         ; 08D5  3A 7E 16
	jr L_08E4                     ; 08D8  18 0A

L_08DA:
	ld a,(LEVEL_VARS+0xB)         ; 08DA  3A 86 16
	or a                          ; 08DD  B7
	ret nz                        ; 08DE  C0

	ld a,(LEVEL_VARS+0x5)         ; 08DF  3A 80 16
	jr L_08E4                     ; 08E2  18 00

L_08E4:
	ld b,a                        ; 08E4  47
	ld a,(LEVEL_VARS)             ; 08E5  3A 7B 16
L_08E8:
	cp b                          ; 08E8  B8
	ret z                         ; 08E9  C8

	ld a,b                        ; 08EA  78
	ld (LEVEL_VARS),a             ; 08EB  32 7B 16
L_08EE:
	ld a,0x00                     ; 08EE  3E 00
	ld (L_0899+0x1),a             ; 08F0  32 9A 08
	xor a                         ; 08F3  AF
	cp c                          ; 08F4  B9
	call nz,RET_STUB              ; 08F5  C4 F8 1C
	jp L_1372                     ; 08F8  C3 72 13

L_08FB:
	ld iy,OBJ_ARRAY_14BF          ; 08FB  FD 21 BF 14  ; в каноне +0x100 этот операнд стухший
	ld b,0x03                     ; 08FF  06 03
L_0901:
	push bc                       ; 0901  C5
	ld a,(iy+0x09)                ; 0902  FD 7E 09
	cp 0x01                       ; 0905  FE 01
	jr z,L_0948                   ; 0907  28 3F
	call L_0962                   ; 0909  CD 62 09  ; в каноне +0x100 этот операнд стухший
	ld a,(GAME_VARS+0xC)          ; 090C  3A F6 0A  ; в каноне +0x100 этот операнд стухший
	cp (iy+0x06)                  ; 090F  FD BE 06
	jr nz,L_092F                  ; 0912  20 1B
	ld d,0x00                     ; 0914  16 00
	call L_0951                   ; 0916  CD 51 09  ; в каноне +0x100 этот операнд стухший
	call L_11F2                   ; 0919  CD F2 11  ; в каноне +0x100 этот операнд стухший
	pop bc                        ; 091C  C1
	push bc                       ; 091D  C5
	xor a                         ; 091E  AF
	cp e                          ; 091F  BB
	call nz,L_0979                ; 0920  C4 79 09  ; в каноне +0x100 этот операнд стухший
	pop af                        ; 0923  F1
	push af                       ; 0924  F5
	call L_09AF                   ; 0925  CD AF 09  ; в каноне +0x100 этот операнд стухший
	jr L_0948                     ; 0928  18 1E

L_092A:
	call L_0951                   ; 092A  CD 51 09  ; в каноне +0x100 этот операнд стухший
	jr L_0948                     ; 092D  18 19

L_092F:
	ld a,(LEVEL_VARS)             ; 092F  3A 7B 16  ; в каноне +0x100 этот операнд стухший
	ld d,0x60                     ; 0932  16 60
	cp (iy+0x06)                  ; 0934  FD BE 06
	jr z,L_092A                   ; 0937  28 F1
	ld a,(iy+0x09)                ; 0939  FD 7E 09
	cp 0x04                       ; 093C  FE 04
	jr nc,L_0948                  ; 093E  30 08
	cp 0x02                       ; 0940  FE 02
	jr c,L_0948                   ; 0942  38 04
	ld (iy+0x09),0x01             ; 0944  FD 36 09 01
L_0948:
	ld bc,0x0D                    ; 0948  01 0D 00
	add iy,bc                     ; 094B  FD 09
	pop bc                        ; 094D  C1
	djnz L_0901                   ; 094E  10 B1
	ret                           ; 0950  C9

L_0951:
	ld a,(iy+0x07)                ; 0951  FD 7E 07
	add a,d                       ; 0954  82
	ld c,a                        ; 0955  4F
	ld b,(iy+0x08)                ; 0956  FD 46 08
	ld a,(iy+0x0B)                ; 0959  FD 7E 0B
	push bc                       ; 095C  C5
	call L_19A0                   ; 095D  CD A0 19  ; в каноне +0x100 этот операнд стухший
	pop bc                        ; 0960  C1
	ret                           ; 0961  C9

L_0962:
	or a                          ; 0962  B7
	jp z,L_09E8                   ; 0963  CA E8 09  ; в каноне +0x100 этот операнд стухший
	cp 0x04                       ; 0966  FE 04
	jr c,L_096D                   ; 0968  38 03
	dec (iy+0x09)                 ; 096A  FD 35 09
L_096D:
	ld b,0x00                     ; 096D  06 00
	ld c,a                        ; 096F  4F
	ld hl,L_09E0+0x2              ; 0970  21 E2 09  ; в каноне +0x100 этот операнд стухший
	add hl,bc                     ; 0973  09
	ld a,(hl)                     ; 0974  7E
	ld (iy+0x0B),a                ; 0975  FD 77 0B
	ret                           ; 0978  C9

L_0979:
	ld a,(iy+0x09)                ; 0979  FD 7E 09
	or a                          ; 097C  B7
	ret nz                        ; 097D  C0

	ld a,b                        ; 097E  78
	cp 0x03                       ; 097F  FE 03
	jr z,L_099B                   ; 0981  28 18
	cp 0x02                       ; 0983  FE 02
	jp nz,L_0F25                  ; 0985  C2 25 0F  ; в каноне +0x100 этот операнд стухший
	ld a,(LEVEL_VARS+0xB)         ; 0988  3A 86 16  ; в каноне +0x100 этот операнд стухший
	or a                          ; 098B  B7
	ret z                         ; 098C  C8

	ld a,0x05                     ; 098D  3E 05
	ld (OBJ_ARRAY_14BF+0x16),a    ; 098F  32 D5 14  ; в каноне +0x100 этот операнд стухший
	ld a,(OBJ_ARRAY_14BF+0x9)     ; 0992  3A C8 14  ; в каноне +0x100 этот операнд стухший
	or a                          ; 0995  B7
	jp z,L_13AF                   ; 0996  CA AF 13  ; в каноне +0x100 этот операнд стухший
	jr L_09AC                     ; 0999  18 11

L_099B:
	ld a,(LEVEL_VARS+0x9)         ; 099B  3A 84 16  ; в каноне +0x100 этот операнд стухший
	or a                          ; 099E  B7
	ret z                         ; 099F  C8

	ld a,0x02                     ; 09A0  3E 02
	ld (OBJ_ARRAY_14BF+0x9),a     ; 09A2  32 C8 14  ; в каноне +0x100 этот операнд стухший
	ld a,(OBJ_ARRAY_14BF+0x16)    ; 09A5  3A D5 14  ; в каноне +0x100 этот операнд стухший
	or a                          ; 09A8  B7
	jp z,L_13B7                   ; 09A9  CA B7 13  ; в каноне +0x100 этот операнд стухший
L_09AC:
	jp L_13A0                     ; 09AC  C3 A0 13  ; в каноне +0x100 этот операнд стухший

L_09AF:
	cp 0x01                       ; 09AF  FE 01
	ret nz                        ; 09B1  C0

	ld a,(OBJ_BLOCK_0809)         ; 09B2  3A 09 08  ; в каноне +0x100 этот операнд стухший
	cp 0x01                       ; 09B5  FE 01
	ret nz                        ; 09B7  C0

	ld a,(OBJ_ARRAY_14BF+0x16)    ; 09B8  3A D5 14  ; в каноне +0x100 этот операнд стухший
	or a                          ; 09BB  B7
	ret z                         ; 09BC  C8

	ld a,(OBJ_ARRAY_14BF+0x9)     ; 09BD  3A C8 14  ; в каноне +0x100 этот операнд стухший
	or a                          ; 09C0  B7
	ret z                         ; 09C1  C8

	ld b,(iy+0x08)                ; 09C2  FD 46 08
	ld c,(iy+0x07)                ; 09C5  FD 4E 07
	ld a,(OBJ_BLOCK_0809+0x5)     ; 09C8  3A 0E 08  ; в каноне +0x100 этот операнд стухший
	sub 0x18                      ; 09CB  D6 18
	cp b                          ; 09CD  B8
	ret nc                        ; 09CE  D0

	add a,0x20                    ; 09CF  C6 20
	cp b                          ; 09D1  B8
	ret c                         ; 09D2  D8

	ld a,(OBJ_BLOCK_0809+0x4)     ; 09D3  3A 0D 08  ; в каноне +0x100 этот операнд стухший
	sub 0x08                      ; 09D6  D6 08
	cp c                          ; 09D8  B9
	ret nc                        ; 09D9  D0

	add a,0x30                    ; 09DA  C6 30
	cp c                          ; 09DC  B9
	ret c                         ; 09DD  D8

	ld a,0x01                     ; 09DE  3E 01
L_09E0:
	ld (D_04D4),a                 ; 09E0  32 D4 04  ; в каноне +0x100 этот операнд стухший
	ret                           ; 09E3  C9

D_09E4:			; данные 09E4..09E7 (4 байт)
	db	0x27,0x34,0x32,0x33	; 09E4
L_09E8:
	call L_1411+0x1               ; 09E8  CD 12 14  ; в каноне +0x100 этот операнд стухший
	xor a                         ; 09EB  AF
	cp d                          ; 09EC  BA
	jr z,L_09F7                   ; 09ED  28 08
	ld a,(iy+0x0A)                ; 09EF  FD 7E 0A
	or e                          ; 09F2  B3
	xor 0x80                      ; 09F3  EE 80
	jr L_0A02                     ; 09F5  18 0B

L_09F7:
	ld a,(iy+0x03)                ; 09F7  FD 7E 03
	push bc                       ; 09FA  C5
	call L_15FA                   ; 09FB  CD FA 15  ; в каноне +0x100 этот операнд стухший
	pop bc                        ; 09FE  C1
	and 0x3F                      ; 09FF  E6 3F
	or e                          ; 0A01  B3
L_0A02:
	ld (iy+0x0B),a                ; 0A02  FD 77 0B
	ld e,0x00                     ; 0A05  1E 00
	ld h,b                        ; 0A07  60
	ld l,0x60                     ; 0A08  2E 60
	ld a,0x1F                     ; 0A0A  3E 1F
	cp c                          ; 0A0C  B9
	jr nc,L_0A28                  ; 0A0D  30 19
	ld l,0x20                     ; 0A0F  2E 20
	inc e                         ; 0A11  1C
	ld a,0x60                     ; 0A12  3E 60
	cp c                          ; 0A14  B9
	jr c,L_0A28                   ; 0A15  38 11
	ld l,c                        ; 0A17  69
	ld h,0xA8                     ; 0A18  26 A8
	inc e                         ; 0A1A  1C
	ld a,0xE6                     ; 0A1B  3E E6
	cp b                          ; 0A1D  B8
	jr c,L_0A28                   ; 0A1E  38 08
	ld h,0x00                     ; 0A20  26 00
	inc e                         ; 0A22  1C
	ld a,0xA8                     ; 0A23  3E A8
	cp b                          ; 0A25  B8
	jr nc,L_0A59                  ; 0A26  30 31
L_0A28:
	push hl                       ; 0A28  E5
	ld d,0x00                     ; 0A29  16 00
	push de                       ; 0A2B  D5
	ld b,(iy+0x08)                ; 0A2C  FD 46 08
	ld c,(iy+0x07)                ; 0A2F  FD 4E 07
	ld a,(GAME_VARS+0xC)          ; 0A32  3A F6 0A  ; в каноне +0x100 этот операнд стухший
	cp (iy+0x06)                  ; 0A35  FD BE 06
	jr z,L_0A46                   ; 0A38  28 0C
	ld a,(LEVEL_VARS)             ; 0A3A  3A 7B 16  ; в каноне +0x100 этот операнд стухший
	cp (iy+0x06)                  ; 0A3D  FD BE 06
	jr nz,L_0A4A                  ; 0A40  20 08
	ld a,c                        ; 0A42  79
	add a,0x60                    ; 0A43  C6 60
	ld c,a                        ; 0A45  4F
L_0A46:
	xor a                         ; 0A46  AF
	call L_15CF                   ; 0A47  CD CF 15  ; в каноне +0x100 этот операнд стухший
L_0A4A:
	ld a,(iy+0x06)                ; 0A4A  FD 7E 06
	call L_1A6C                   ; 0A4D  CD 6C 1A  ; в каноне +0x100 этот операнд стухший
	pop de                        ; 0A50  D1
	add hl,de                     ; 0A51  19
	ld a,(hl)                     ; 0A52  7E
	ld (iy+0x06),a                ; 0A53  FD 77 06
	pop hl                        ; 0A56  E1
	ld b,h                        ; 0A57  44
	ld c,l                        ; 0A58  4D
L_0A59:
	ld (iy+0x07),c                ; 0A59  FD 71 07
	ld (iy+0x08),b                ; 0A5C  FD 70 08
	ret                           ; 0A5F  C9

L_0A60:
	ld hl,L_0B45                  ; 0A60  21 45 0B
	push hl                       ; 0A63  E5
	ld a,(GAME_VARS+0x9)          ; 0A64  3A F3 0A
	or a                          ; 0A67  B7
	jr z,L_0A81                   ; 0A68  28 17
	call L_0B40                   ; 0A6A  CD 40 0B
	jr nz,L_0A81                  ; 0A6D  20 12
	call L_0BBA                   ; 0A6F  CD BA 0B
	jp c,L_0CEF                   ; 0A72  DA EF 0C
	ld a,(GAME_VARS+0x7)          ; 0A75  3A F1 0A
	cp 0x08                       ; 0A78  FE 08
	jr nc,L_0A81                  ; 0A7A  30 05
	cp 0x06                       ; 0A7C  FE 06
	call nc,L_0ABE                ; 0A7E  D4 BE 0A
L_0A81:
	xor a                         ; 0A81  AF
	ld (GAME_VARS+0x2),a          ; 0A82  32 EC 0A
	ld a,(GAME_VARS+0x5)          ; 0A85  3A EF 0A
	or a                          ; 0A88  B7
	jp nz,L_0CA8                  ; 0A89  C2 A8 0C
	ld a,(GAME_VARS+0x6)          ; 0A8C  3A F0 0A
	or a                          ; 0A8F  B7
	jp nz,L_0D25                  ; 0A90  C2 25 0D
	call L_0B1F                   ; 0A93  CD 1F 0B
	call L_157B                   ; 0A96  CD 7B 15
	bit 4,b                       ; 0A99  CB 60
	jp nz,L_0C9F                  ; 0A9B  C2 9F 0C
	bit 0,b                       ; 0A9E  CB 40
	jp nz,L_0B90                  ; 0AA0  C2 90 0B
	bit 1,b                       ; 0AA3  CB 48
	jp nz,L_0B7C                  ; 0AA5  C2 7C 0B
	ld a,0x01                     ; 0AA8  3E 01
	ld (GAME_VARS+0x4),a          ; 0AAA  32 EE 0A
	bit 2,b                       ; 0AAD  CB 50
	jp nz,L_0B74                  ; 0AAF  C2 74 0B
	bit 3,b                       ; 0AB2  CB 58
	jp nz,L_0B5D                  ; 0AB4  C2 5D 0B
	xor a                         ; 0AB7  AF
	ld (GAME_VARS+0x4),a          ; 0AB8  32 EE 0A
	jp L_0BB1                     ; 0ABB  C3 B1 0B

L_0ABE:
	call SFX_64B9                 ; 0ABE  CD 88 20
	ld a,(GAME_VARS+0x3)          ; 0AC1  3A ED 0A
	cp 0x10                       ; 0AC4  FE 10
	jr c,L_0ADC                   ; 0AC6  38 14
	ld a,(L_122C+0x1)             ; 0AC8  3A 2D 12
	ld b,a                        ; 0ACB  47
	ld a,(GAME_VARS+0x3)          ; 0ACC  3A ED 0A
	sub 0x0F                      ; 0ACF  D6 0F
	cp b                          ; 0AD1  B8
	jr nc,L_0AD5                  ; 0AD2  30 01
	ld b,a                        ; 0AD4  47
L_0AD5:
	push bc                       ; 0AD5  C5
	call L_122C                   ; 0AD6  CD 2C 12
	pop bc                        ; 0AD9  C1
	djnz L_0AD5                   ; 0ADA  10 F9
L_0ADC:
	xor a                         ; 0ADC  AF
	ld (GAME_VARS+0x3),a          ; 0ADD  32 ED 0A
	ret                           ; 0AE0  C9

L_0AE1:
	ld a,(GAME_VARS+0xE)          ; 0AE1  3A F8 0A
	xor 0x80                      ; 0AE4  EE 80
	ld (GAME_VARS+0xE),a          ; 0AE6  32 F8 0A
	ret                           ; 0AE9  C9

GAME_VARS:			; данные 0AEA..0AFE (21 байт)
; главный блок переменных игры: 19 адресов, 105 обращений из живого кода
; (C2EA..C2FA, C2FC, C2FE)
	db	0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x07,0x50,0x77,0x16,0x00,0x80,0x01	; 0AEA
	db	0x20,0x4B,0x16,0x00,0x80	; 0AFA
L_0AFF:
	ld hl,GAME_VARS               ; 0AFF  21 EA 0A
	ld de,GAME_VARS+0x1           ; 0B02  11 EB 0A
	ld bc,0x14                    ; 0B05  01 14 00
	ld (hl),0x00                  ; 0B08  36 00
	ldir                          ; 0B0A  ED B0
	ld hl,0x4050                  ; 0B0C  21 50 40
	ld (GAME_VARS+0xA),hl         ; 0B0F  22 F4 0A
	ld hl,0x0103                  ; 0B12  21 03 01
	ld (GAME_VARS+0x8),hl         ; 0B15  22 F2 0A
	ld hl,0x0180                  ; 0B18  21 80 01
	ld (GAME_VARS+0xE),hl         ; 0B1B  22 F8 0A
	ret                           ; 0B1E  C9

L_0B1F:
	ld a,(GAME_VARS)              ; 0B1F  3A EA 0A
	or a                          ; 0B22  B7
	ret nz                        ; 0B23  C0

	ld a,(L_0837+0x1)             ; 0B24  3A 38 08
	or a                          ; 0B27  B7
	ret nz                        ; 0B28  C0

	inc a                         ; 0B29  3C
	ld (GAME_VARS),a              ; 0B2A  32 EA 0A
	ld hl,(GAME_VARS+0xA)         ; 0B2D  2A F4 0A
	ld (GAME_VARS+0x10),hl        ; 0B30  22 FA 0A
	ld hl,(GAME_VARS+0xC)         ; 0B33  2A F6 0A
	ld (GAME_VARS+0x12),hl        ; 0B36  22 FC 0A
	ld a,(GAME_VARS+0xE)          ; 0B39  3A F8 0A
	ld (GAME_VARS+0x14),a         ; 0B3C  32 FE 0A
	ret                           ; 0B3F  C9

L_0B40:
	ld a,(GAME_VARS+0xD)          ; 0B40  3A F7 0A
	or a                          ; 0B43  B7
	ret                           ; 0B44  C9

L_0B45:
	call L_0C2C                   ; 0B45  CD 2C 0C
	call L_0DBB                   ; 0B48  CD BB 0D
	call L_207E                   ; 0B4B  CD 7E 20
	ld a,(GAME_VARS+0xE)          ; 0B4E  3A F8 0A
	ld b,a                        ; 0B51  47
	ld a,(GAME_VARS+0x7)          ; 0B52  3A F1 0A
	or b                          ; 0B55  B0
	ld bc,(GAME_VARS+0xA)         ; 0B56  ED 4B F4 0A
	jp L_2168                     ; 0B5A  C3 68 21

L_0B5D:
	ld a,(GAME_VARS+0xE)          ; 0B5D  3A F8 0A
	or a                          ; 0B60  B7
	jr nz,L_0B69                  ; 0B61  20 06
L_0B63:
	call L_0AE1                   ; 0B63  CD E1 0A
L_0B66:
	jp L_0BB1                     ; 0B66  C3 B1 0B

L_0B69:
	ld d,0x80                     ; 0B69  16 80
	call L_0D95                   ; 0B6B  CD 95 0D
	jr nc,L_0B66                  ; 0B6E  30 F6
	call L_0BE9                   ; 0B70  CD E9 0B
	ret                           ; 0B73  C9

L_0B74:
	ld a,(GAME_VARS+0xE)          ; 0B74  3A F8 0A
	or a                          ; 0B77  B7
	jr z,L_0B69                   ; 0B78  28 EF
	jr L_0B63                     ; 0B7A  18 E7

L_0B7C:
	call L_0B40                   ; 0B7C  CD 40 0B
	jr nz,L_0B87                  ; 0B7F  20 06
	ld a,0x05                     ; 0B81  3E 05
	ld (GAME_VARS+0x7),a          ; 0B83  32 F1 0A
	ret                           ; 0B86  C9

L_0B87:
	call L_0BBA                   ; 0B87  CD BA 0B
	ret nc                        ; 0B8A  D0

	call L_0AE1                   ; 0B8B  CD E1 0A
	jr L_0BA3                     ; 0B8E  18 13

L_0B90:
	call L_0B40                   ; 0B90  CD 40 0B
	jp z,L_0D41                   ; 0B93  CA 41 0D
	call L_0BA7                   ; 0B96  CD A7 0B
	call L_0AE1                   ; 0B99  CD E1 0A
	call L_0DBB                   ; 0B9C  CD BB 0D
	ret z                         ; 0B9F  C8

	call L_0AE1                   ; 0BA0  CD E1 0A
L_0BA3:
	ld b,0x04                     ; 0BA3  06 04
	jr L_0BA9                     ; 0BA5  18 02

L_0BA7:
	ld b,0xFC                     ; 0BA7  06 FC
L_0BA9:
	ld a,(GAME_VARS+0xA)          ; 0BA9  3A F4 0A
	add a,b                       ; 0BAC  80
	ld (GAME_VARS+0xA),a          ; 0BAD  32 F4 0A
	ret                           ; 0BB0  C9

L_0BB1:
	xor a                         ; 0BB1  AF
	ld (GAME_VARS+0x7),a          ; 0BB2  32 F1 0A
	inc a                         ; 0BB5  3C
	ld (GAME_VARS+0xF),a          ; 0BB6  32 F9 0A
	ret                           ; 0BB9  C9

L_0BBA:
	xor a                         ; 0BBA  AF
	ld d,0x40                     ; 0BBB  16 40
	jr L_0BCC                     ; 0BBD  18 0D

L_0BBF:
	ld bc,(OBJ_BLOCK_0809+0x1A)   ; 0BBF  ED 4B 23 08  ; в каноне +0x100 этот операнд стухший
	ld de,0x2002                  ; 0BC3  11 02 20
	jr L_0BD8                     ; 0BC6  18 10

L_0BC8:
	ld a,0xDF                     ; 0BC8  3E DF
	ld d,0x80                     ; 0BCA  16 80
L_0BCC:
	ld bc,(GAME_VARS+0xA)         ; 0BCC  ED 4B F4 0A
	add a,c                       ; 0BD0  81
	cp 0x60                       ; 0BD1  FE 60
	ccf                           ; 0BD3  3F
	ret c                         ; 0BD4  D8

	ld c,a                        ; 0BD5  4F
L_0BD6:
	ld e,0x03                     ; 0BD6  1E 03
L_0BD8:
	ld a,0x06                     ; 0BD8  3E 06
	add a,b                       ; 0BDA  80
	ld b,a                        ; 0BDB  47
	push bc                       ; 0BDC  C5
	call ATTR_ADDR                ; 0BDD  CD 00 1F
	pop bc                        ; 0BE0  C1
	ld a,(hl)                     ; 0BE1  7E
	cp d                          ; 0BE2  BA
	ret nc                        ; 0BE3  D0

	dec e                         ; 0BE4  1D
	jr nz,L_0BD8                  ; 0BE5  20 F1
	scf                           ; 0BE7  37
	ret                           ; 0BE8  C9

L_0BE9:
	ld a,(GAME_VARS+0x7)          ; 0BE9  3A F1 0A
	cp 0x05                       ; 0BEC  FE 05
	jr c,L_0BF2                   ; 0BEE  38 02
	ld a,0x01                     ; 0BF0  3E 01
L_0BF2:
	ld b,a                        ; 0BF2  47
	cp 0x04                       ; 0BF3  FE 04
	jr nz,L_0BFE                  ; 0BF5  20 07
	ld a,0xFF                     ; 0BF7  3E FF
	ld (GAME_VARS+0xF),a          ; 0BF9  32 F9 0A
	jr L_0C0A                     ; 0BFC  18 0C

L_0BFE:
	cp 0x01                       ; 0BFE  FE 01
	jr nz,L_0C07                  ; 0C00  20 05
	ld a,0x01                     ; 0C02  3E 01
	ld (GAME_VARS+0xF),a          ; 0C04  32 F9 0A
L_0C07:
	ld a,(GAME_VARS+0xF)          ; 0C07  3A F9 0A
L_0C0A:
	add a,b                       ; 0C0A  80
	ld (GAME_VARS+0x7),a          ; 0C0B  32 F1 0A
	ld a,(GAME_VARS+0xE)          ; 0C0E  3A F8 0A
	ld b,0xFD                     ; 0C11  06 FD
	or a                          ; 0C13  B7
	jr z,L_0C18                   ; 0C14  28 02
	ld b,0x03                     ; 0C16  06 03
L_0C18:
	ld a,(GAME_VARS+0xB)          ; 0C18  3A F5 0A
	add a,b                       ; 0C1B  80
	ld (GAME_VARS+0xB),a          ; 0C1C  32 F5 0A
	ret                           ; 0C1F  C9

L_0C20:
	ld a,(GAME_VARS+0xE)          ; 0C20  3A F8 0A
	ld b,0xFE                     ; 0C23  06 FE
	or a                          ; 0C25  B7
	jr z,L_0C18                   ; 0C26  28 F0
	ld b,0x02                     ; 0C28  06 02
	jr L_0C18                     ; 0C2A  18 EC

L_0C2C:
	ld hl,D_1D08                  ; 0C2C  21 08 1D
	ld b,(hl)                     ; 0C2F  46
	inc hl                        ; 0C30  23
	ld c,(hl)                     ; 0C31  4E
	inc hl                        ; 0C32  23
	ld d,(hl)                     ; 0C33  56
	inc hl                        ; 0C34  23
	ld e,(hl)                     ; 0C35  5E
	ld hl,GAME_VARS+0xB           ; 0C36  21 F5 0A
	ld a,(hl)                     ; 0C39  7E
	cp 0xA9                       ; 0C3A  FE A9
	jr c,L_0C54                   ; 0C3C  38 16
	call L_0C6F                   ; 0C3E  CD 6F 0C
	ld a,(hl)                     ; 0C41  7E
	cp 0xE6                       ; 0C42  FE E6
	jr c,L_0C4F                   ; 0C44  38 09
	ld (hl),0xA8                  ; 0C46  36 A8
	ld a,d                        ; 0C48  7A
L_0C49:
	ld (GAME_VARS+0xC),a          ; 0C49  32 F6 0A
	jp L_1F19                     ; 0C4C  C3 19 1F

L_0C4F:
	ld (hl),0x00                  ; 0C4F  36 00
	ld a,e                        ; 0C51  7B
	jr L_0C49                     ; 0C52  18 F5

L_0C54:
	dec hl                        ; 0C54  2B
	ld a,(hl)                     ; 0C55  7E
	cp 0x20                       ; 0C56  FE 20
	jr c,L_0C65                   ; 0C58  38 0B
	cp 0x61                       ; 0C5A  FE 61
	ret c                         ; 0C5C  D8

	call L_0C6F                   ; 0C5D  CD 6F 0C
	ld (hl),0x20                  ; 0C60  36 20
	ld a,c                        ; 0C62  79
	jr L_0C49                     ; 0C63  18 E4

L_0C65:
	ld (hl),0x20                  ; 0C65  36 20
	call L_0C6F                   ; 0C67  CD 6F 0C
	ld (hl),0x60                  ; 0C6A  36 60
L_0C6C:
	ld a,b                        ; 0C6C  78
	jr L_0C49                     ; 0C6D  18 DA

L_0C6F:
	push bc                       ; 0C6F  C5
	ld a,(GAME_VARS+0xC)          ; 0C70  3A F6 0A
	ld b,a                        ; 0C73  47
	ld a,(LEVEL_VARS)             ; 0C74  3A 7B 16
	cp b                          ; 0C77  B8
	jr nz,L_0C8A                  ; 0C78  20 10
	push de                       ; 0C7A  D5
	push hl                       ; 0C7B  E5
	call L_0F2B                   ; 0C7C  CD 2B 0F
	xor a                         ; 0C7F  AF
	ld (D_1A23),a                 ; 0C80  32 23 1A
	nop                           ; 0C83  00
	nop                           ; 0C84  00
	nop                           ; 0C85  00
	nop                           ; 0C86  00
	nop                           ; 0C87  00
	pop hl                        ; 0C88  E1
	pop de                        ; 0C89  D1
L_0C8A:
	pop bc                        ; 0C8A  C1
	ret                           ; 0C8B  C9

L_0C8C:
	call L_0F47                   ; 0C8C  CD 47 0F
	xor a                         ; 0C8F  AF
	ld (GAME_VARS),a              ; 0C90  32 EA 0A
	ret                           ; 0C93  C9

D_0C94:			; данные 0C94..0C96 (3 байт)
	db	0x00,0x00,0x00	; 0C94
	call L_0F47                   ; 0C97  CD 47 0F  ; в каноне +0x100 этот операнд стухший
	xor a                         ; 0C9A  AF
	ld (GAME_VARS),a              ; 0C9B  32 EA 0A  ; в каноне +0x100 этот операнд стухший
	ret                           ; 0C9E  C9

L_0C9F:
	ld a,(OBJ_BLOCK_0809)         ; 0C9F  3A 09 08
	or a                          ; 0CA2  B7
	ret nz                        ; 0CA3  C0

	call L_0B40                   ; 0CA4  CD 40 0B
	ret nz                        ; 0CA7  C0

L_0CA8:
	inc a                         ; 0CA8  3C
	ld (GAME_VARS+0x5),a          ; 0CA9  32 EF 0A
	cp 0x05                       ; 0CAC  FE 05
	jr z,L_0CE8                   ; 0CAE  28 38
	ld b,0x08                     ; 0CB0  06 08
	cp 0x02                       ; 0CB2  FE 02
	jr c,L_0CE3                   ; 0CB4  38 2D
	cp 0x03                       ; 0CB6  FE 03
	jr nc,L_0CE3                  ; 0CB8  30 29
	inc b                         ; 0CBA  04
	cp 0x03                       ; 0CBB  FE 03
	jr z,L_0CE3                   ; 0CBD  28 24
	ld (OBJ_BLOCK_0809),a         ; 0CBF  32 09 08
	ld a,0x1C                     ; 0CC2  3E 1C
	ld (OBJ_BLOCK_0809+0x6),a     ; 0CC4  32 0F 08
	ld a,(GAME_VARS+0xC)          ; 0CC7  3A F6 0A
	ld (OBJ_BLOCK_0809+0x1),a     ; 0CCA  32 0A 08
	ld a,(GAME_VARS+0xE)          ; 0CCD  3A F8 0A
	ld (OBJ_BLOCK_0809+0x7),a     ; 0CD0  32 10 08
	ld d,0xF8                     ; 0CD3  16 F8
	or a                          ; 0CD5  B7
	jr z,L_0CDA                   ; 0CD6  28 02
	ld d,0x10                     ; 0CD8  16 10
L_0CDA:
	ld hl,(GAME_VARS+0xA)         ; 0CDA  2A F4 0A
	ld e,0xF6                     ; 0CDD  1E F6
	add hl,de                     ; 0CDF  19
	ld (OBJ_BLOCK_0809+0x4),hl    ; 0CE0  22 0D 08
L_0CE3:
	ld a,b                        ; 0CE3  78
	ld (GAME_VARS+0x7),a          ; 0CE4  32 F1 0A
	ret                           ; 0CE7  C9

L_0CE8:
	xor a                         ; 0CE8  AF
	ld (GAME_VARS+0x5),a          ; 0CE9  32 EF 0A
	jp L_0BB1                     ; 0CEC  C3 B1 0B

L_0CEF:
	call L_0BA3                   ; 0CEF  CD A3 0B
	ld a,(GAME_VARS+0x3)          ; 0CF2  3A ED 0A
	inc a                         ; 0CF5  3C
	ld (GAME_VARS+0x3),a          ; 0CF6  32 ED 0A
	ld a,(GAME_VARS+0x2)          ; 0CF9  3A EC 0A
	or a                          ; 0CFC  B7
	jr z,L_0D18                   ; 0CFD  28 19
	dec a                         ; 0CFF  3D
	ld (GAME_VARS+0x2),a          ; 0D00  32 EC 0A
	or a                          ; 0D03  B7
	jr z,L_0D14                   ; 0D04  28 0E
	ld a,(GAME_VARS+0x1)          ; 0D06  3A EB 0A
	or a                          ; 0D09  B7
	jr z,L_0D14                   ; 0D0A  28 08
	ld d,0x40                     ; 0D0C  16 40
	call L_0D95                   ; 0D0E  CD 95 0D
	call c,L_0C20                 ; 0D11  DC 20 0C
L_0D14:
	ld a,0x07                     ; 0D14  3E 07
	jr L_0D21                     ; 0D16  18 09

L_0D18:
	ld (GAME_VARS+0x1),a          ; 0D18  32 EB 0A
	inc a                         ; 0D1B  3C
	ld (GAME_VARS+0x2),a          ; 0D1C  32 EC 0A
	ld a,0x06                     ; 0D1F  3E 06
L_0D21:
	ld (GAME_VARS+0x7),a          ; 0D21  32 F1 0A
	ret                           ; 0D24  C9

L_0D25:
	cp 0x07                       ; 0D25  FE 07
	jr z,L_0D61                   ; 0D27  28 38
	inc a                         ; 0D29  3C
	ld (GAME_VARS+0x6),a          ; 0D2A  32 F0 0A
	call L_0BC8                   ; 0D2D  CD C8 0B
	call c,L_0BA7                 ; 0D30  DC A7 0B
	ld a,(GAME_VARS+0x1)          ; 0D33  3A EB 0A
	or a                          ; 0D36  B7
	ret z                         ; 0D37  C8

	ld d,0x40                     ; 0D38  16 40
	call L_0D95                   ; 0D3A  CD 95 0D
	call c,L_0C20                 ; 0D3D  DC 20 0C
	ret                           ; 0D40  C9

L_0D41:
	xor a                         ; 0D41  AF
	ld (GAME_VARS+0x9),a          ; 0D42  32 F3 0A
	inc a                         ; 0D45  3C
	ld (GAME_VARS+0x6),a          ; 0D46  32 F0 0A
	ld a,(GAME_VARS+0x4)          ; 0D49  3A EE 0A
	ld b,0x00                     ; 0D4C  06 00
	or a                          ; 0D4E  B7
	jr z,L_0D57                   ; 0D4F  28 06
	cp 0x05                       ; 0D51  FE 05
	jr nc,L_0D57                  ; 0D53  30 02
	ld b,0x01                     ; 0D55  06 01
L_0D57:
	ld a,b                        ; 0D57  78
	ld (GAME_VARS+0x1),a          ; 0D58  32 EB 0A
	ld a,0x06                     ; 0D5B  3E 06
	ld (GAME_VARS+0x7),a          ; 0D5D  32 F1 0A
	ret                           ; 0D60  C9

L_0D61:
	ld (GAME_VARS+0x2),a          ; 0D61  32 EC 0A
L_0D64:
	ld (GAME_VARS+0x9),a          ; 0D64  32 F3 0A
	xor a                         ; 0D67  AF
	ld (GAME_VARS+0x6),a          ; 0D68  32 F0 0A
	ret                           ; 0D6B  C9

L_0D6C:
	or a                          ; 0D6C  B7
	jr nz,L_0D74                  ; 0D6D  20 05
	ld a,0xFA                     ; 0D6F  3E FA
	ld d,a                        ; 0D71  57
	jr L_0D79                     ; 0D72  18 05

L_0D74:
	ld a,0x10                     ; 0D74  3E 10
	add a,e                       ; 0D76  83
	ld d,0x06                     ; 0D77  16 06
L_0D79:
	push bc                       ; 0D79  C5
	add a,b                       ; 0D7A  80
	cp 0xBC                       ; 0D7B  FE BC
	jr nc,L_0D8E                  ; 0D7D  30 0F
	ld b,a                        ; 0D7F  47
	ld a,c                        ; 0D80  79
	sub 0x04                      ; 0D81  D6 04
	ld c,a                        ; 0D83  4F
	call ATTR_ADDR                ; 0D84  CD 00 1F  ; в каноне +0x100 этот операнд стухший
	nop                           ; 0D87  00
	nop                           ; 0D88  00
	nop                           ; 0D89  00
	nop                           ; 0D8A  00
	ld a,(hl)                     ; 0D8B  7E
	cp 0x80                       ; 0D8C  FE 80
L_0D8E:
	ex af,af'                     ; 0D8E  08
	pop bc                        ; 0D8F  C1
	ld a,b                        ; 0D90  78
	add a,d                       ; 0D91  82
	ld b,a                        ; 0D92  47
	ex af,af'                     ; 0D93  08
	ret                           ; 0D94  C9

L_0D95:
	ld bc,(GAME_VARS+0xA)         ; 0D95  ED 4B F4 0A
	ld a,(GAME_VARS+0xE)          ; 0D99  3A F8 0A
	or a                          ; 0D9C  B7
	jr z,L_0DA3                   ; 0D9D  28 04
	ld a,0x16                     ; 0D9F  3E 16
	jr L_0DA5                     ; 0DA1  18 02

L_0DA3:
	ld a,0x02                     ; 0DA3  3E 02
L_0DA5:
	add a,b                       ; 0DA5  80
	ld b,a                        ; 0DA6  47
	dec c                         ; 0DA7  0D
	ld e,0x04                     ; 0DA8  1E 04
L_0DAA:
	push bc                       ; 0DAA  C5
	call ATTR_ADDR                ; 0DAB  CD 00 1F
	pop bc                        ; 0DAE  C1
	ld a,(hl)                     ; 0DAF  7E
	cp d                          ; 0DB0  BA
	ret nc                        ; 0DB1  D0

	ld a,c                        ; 0DB2  79
	sub 0x08                      ; 0DB3  D6 08
	ld c,a                        ; 0DB5  4F
	dec e                         ; 0DB6  1D
	jr nz,L_0DAA                  ; 0DB7  20 F1
	scf                           ; 0DB9  37
	ret                           ; 0DBA  C9

L_0DBB:
	ld bc,(GAME_VARS+0xA)         ; 0DBB  ED 4B F4 0A
	xor a                         ; 0DBF  AF
	ld (GAME_VARS+0xD),a          ; 0DC0  32 F7 0A
	ld a,c                        ; 0DC3  79
	sub 0x1C                      ; 0DC4  D6 1C
	ld c,a                        ; 0DC6  4F
	ld e,0x03                     ; 0DC7  1E 03
L_0DC9:
	ld a,b                        ; 0DC9  78
	add a,0x06                    ; 0DCA  C6 06
	ld b,a                        ; 0DCC  47
	push bc                       ; 0DCD  C5
	call ATTR_ADDR                ; 0DCE  CD 00 1F
	pop bc                        ; 0DD1  C1
	ld a,(hl)                     ; 0DD2  7E
	cpl                           ; 0DD3  2F
	and 0x20                      ; 0DD4  E6 20
	ret nz                        ; 0DD6  C0

	dec e                         ; 0DD7  1D
	jr nz,L_0DC9                  ; 0DD8  20 EF
	ld a,0x0A                     ; 0DDA  3E 0A
	ld (GAME_VARS+0x7),a          ; 0DDC  32 F1 0A
	ld (GAME_VARS+0xD),a          ; 0DDF  32 F7 0A
	ret                           ; 0DE2  C9

L_0DE3:
	ld a,(GAME_VARS+0xC)          ; 0DE3  3A F6 0A
	cp 0x04                       ; 0DE6  FE 04
	jr z,L_0E24                   ; 0DE8  28 3A
	cp 0x0D                       ; 0DEA  FE 0D
	jr z,L_0E3B                   ; 0DEC  28 4D
	cp 0x18                       ; 0DEE  FE 18
	jr z,L_0E4D                   ; 0DF0  28 5B
	cp 0x1F                       ; 0DF2  FE 1F
	jr z,L_0E64                   ; 0DF4  28 6E
	cp 0x3D                       ; 0DF6  FE 3D
	jp z,L_0E83                   ; 0DF8  CA 83 0E
	cp 0x4A                       ; 0DFB  FE 4A
	jp z,L_0EAB                   ; 0DFD  CA AB 0E
	cp 0x4C                       ; 0E00  FE 4C
	jp z,L_0EE0                   ; 0E02  CA E0 0E
	cp 0x56                       ; 0E05  FE 56
	jp z,L_0F0D                   ; 0E07  CA 0D 0F
	cp 0x50                       ; 0E0A  FE 50
	ret nz                        ; 0E0C  C0

	ld hl,ROOM_MAPS+0x2105        ; 0E0D  21 4C 89
	call L_0F5D                   ; 0E10  CD 5D 0F
	ret c                         ; 0E13  D8

	ld a,0x1E                     ; 0E14  3E 1E
	ld (ROOM_MAPS+0x2090),a       ; 0E16  32 D7 88
	ld hl,0x2F80                  ; 0E19  21 80 2F
	ld b,0x20                     ; 0E1C  06 20
	call L_0FA7                   ; 0E1E  CD A7 0F
	jp L_1907                     ; 0E21  C3 07 19

L_0E24:
	ld hl,ROOM_MAPS+0x201         ; 0E24  21 48 6A
	call L_0F5D                   ; 0E27  CD 5D 0F
	ret c                         ; 0E2A  D8

	ld a,0x21                     ; 0E2B  3E 21
	ld (ROOM_MAPS+0x180),a        ; 0E2D  32 C7 69
	ld hl,0x2F28                  ; 0E30  21 28 2F
	ld b,0x20                     ; 0E33  06 20
	call L_0FA7                   ; 0E35  CD A7 0F
	jp L_1907                     ; 0E38  C3 07 19

L_0E3B:
	ld hl,ROOM_MAPS+0x597         ; 0E3B  21 DE 6D
	call L_0F5D                   ; 0E3E  CD 5D 0F
	ret c                         ; 0E41  D8

	ld a,0x28                     ; 0E42  3E 28
	ld (ROOM_MAPS+0x7B6),a        ; 0E44  32 FD 6F
L_0E47:
	call SFX_64D7_x25             ; 0E47  CD F2 1F
	jp SFX_64D7_x25               ; 0E4A  C3 F2 1F

L_0E4D:
	ld hl,ROOM_MAPS+0xA65         ; 0E4D  21 AC 72
	call L_0F5D                   ; 0E50  CD 5D 0F
	ret c                         ; 0E53  D8

	ld a,0x1E                     ; 0E54  3E 1E
	ld (ROOM_MAPS+0x9F8),a        ; 0E56  32 3F 72
	ld hl,0x1778                  ; 0E59  21 78 17
	ld b,0x38                     ; 0E5C  06 38
	call L_0FA7                   ; 0E5E  CD A7 0F
	jp L_1907                     ; 0E61  C3 07 19

L_0E64:
	ld hl,ROOM_MAPS+0xD67         ; 0E64  21 AE 75
	call L_0F5D                   ; 0E67  CD 5D 0F
	ret c                         ; 0E6A  D8

	ld a,0x1D                     ; 0E6B  3E 1D
	ld (ROOM_MAPS+0xC7C),a        ; 0E6D  32 C3 74
	ld a,(LEVEL_VARS)             ; 0E70  3A 7B 16
	cp 0x1E                       ; 0E73  FE 1E
	jp nz,SFX_64D7_x25            ; 0E75  C2 F2 1F
	ld hl,0x6880                  ; 0E78  21 80 68
	ld b,0x47                     ; 0E7B  06 47
	call L_0FA7                   ; 0E7D  CD A7 0F
	jp L_1907                     ; 0E80  C3 07 19

L_0E83:
	ld hl,ROOM_MAPS+0x1933        ; 0E83  21 7A 81
	call L_0F5D                   ; 0E86  CD 5D 0F
	ret c                         ; 0E89  D8

L_0E8A:
	ld a,0x12                     ; 0E8A  3E 12
	ld (ROOM_MAPS+0x1992),a       ; 0E8C  32 D9 81
	ld a,0x14                     ; 0E8F  3E 14
	ld (ROOM_MAPS+0x19F8),a       ; 0E91  32 3F 82
	call SFX_64D7_x25             ; 0E94  CD F2 1F
	jp L_1907                     ; 0E97  C3 07 19

L_0E9A:
	ld de,ROOM_MAPS+0x1DF3        ; 0E9A  11 3A 86
	ld hl,D_1D08+0x4              ; 0E9D  21 0C 1D
	ld bc,0x08                    ; 0EA0  01 08 00
	ldir                          ; 0EA3  ED B0
	call SFX_64D7                 ; 0EA5  CD DA 1F
	jp L_1907                     ; 0EA8  C3 07 19

L_0EAB:
	ld hl,ROOM_MAPS+0x1E3D        ; 0EAB  21 84 86
	call L_0F5D                   ; 0EAE  CD 5D 0F
	jr nc,L_0E9A                  ; 0EB1  30 E7
	ld hl,ROOM_MAPS+0x1E39        ; 0EB3  21 80 86
	call L_0F5D                   ; 0EB6  CD 5D 0F
	jr nc,L_0ED0                  ; 0EB9  30 15
	ld hl,ROOM_MAPS+0x1E35        ; 0EBB  21 7C 86
	call L_0F5D                   ; 0EBE  CD 5D 0F
	ret c                         ; 0EC1  D8

	ld a,0x14                     ; 0EC2  3E 14
	ld (ROOM_MAPS+0x1E00),a       ; 0EC4  32 47 86
	ld hl,0x4950                  ; 0EC7  21 50 49
	call L_0374                   ; 0ECA  CD 74 03
	jp L_1907                     ; 0ECD  C3 07 19

L_0ED0:
	ld hl,0x0120                  ; 0ED0  21 20 01
	ld a,0x06                     ; 0ED3  3E 06
	call L_1019                   ; 0ED5  CD 19 10
	ld a,0x36                     ; 0ED8  3E 36
	ld (ROOM_MAPS+0x1E39),a       ; 0EDA  32 80 86
	jp L_0F25                     ; 0EDD  C3 25 0F

L_0EE0:
	ld hl,ROOM_MAPS+0x1F1D        ; 0EE0  21 64 87
	call L_0F5D                   ; 0EE3  CD 5D 0F
	jr nc,L_0EFD                  ; 0EE6  30 15
	ld hl,ROOM_MAPS+0x1F19        ; 0EE8  21 60 87
	call L_0F5D                   ; 0EEB  CD 5D 0F
	ret c                         ; 0EEE  D8

	ld a,0x22                     ; 0EEF  3E 22
	ld (ROOM_MAPS+0x1EBC),a       ; 0EF1  32 03 87
	ld hl,0x4A18                  ; 0EF4  21 18 4A
	call L_0374                   ; 0EF7  CD 74 03
	jp L_1907                     ; 0EFA  C3 07 19

L_0EFD:
	ld hl,0x0910                  ; 0EFD  21 10 09
	ld a,0x07                     ; 0F00  3E 07
	call L_1019                   ; 0F02  CD 19 10
	ld a,0x36                     ; 0F05  3E 36
	ld (ROOM_MAPS+0x1F1D),a       ; 0F07  32 64 87
	jp L_0F25                     ; 0F0A  C3 25 0F

L_0F0D:
	ld hl,0x6360                  ; 0F0D  21 60 63
	ld bc,0x0205                  ; 0F10  01 05 02
	ld a,0xF1                     ; 0F13  3E F1
	call L_1828                   ; 0F15  CD 28 18
	call L_13D5                   ; 0F18  CD D5 13
	nop                           ; 0F1B  00
	nop                           ; 0F1C  00
	nop                           ; 0F1D  00
	ld a,(L_122C+0x1)             ; 0F1E  3A 2D 12
	ld b,a                        ; 0F21  47
	call L_0AD5                   ; 0F22  CD D5 0A
L_0F25:
	ld a,0x01                     ; 0F25  3E 01
L_0F27:
	ld (L_0837+0x1),a             ; 0F27  32 38 08
	ret                           ; 0F2A  C9

L_0F2B:
	call L_1DF7                   ; 0F2B  CD F7 1D
L_0F2E:
	ld a,(LEVEL_VARS)             ; 0F2E  3A 7B 16
	add a,0x80                    ; 0F31  C6 80
	ld b,a                        ; 0F33  47
	call L_1A84                   ; 0F34  CD 84 1A
	ld a,(GAME_VARS+0xC)          ; 0F37  3A F6 0A
	call L_1A6C                   ; 0F3A  CD 6C 1A
	ld de,D_1D08                  ; 0F3D  11 08 1D
	ld c,0x04                     ; 0F40  0E 04
	ldir                          ; 0F42  ED B0
	jp L_1F9F                     ; 0F44  C3 9F 1F

L_0F47:
	call L_1DF1                   ; 0F47  CD F1 1D
L_0F4A:
	ld a,(GAME_VARS+0xC)          ; 0F4A  3A F6 0A
	ld hl,WORK_RAM+0x111          ; 0F4D  21 B9 3B  ; в каноне +0x100 этот операнд стухший
	ld c,a                        ; 0F50  4F
	ld b,0x00                     ; 0F51  06 00
	add hl,bc                     ; 0F53  09
	ld (hl),0x80                  ; 0F54  36 80
	ld b,a                        ; 0F56  47
	call L_1A84                   ; 0F57  CD 84 1A
	jp L_1F92                     ; 0F5A  C3 92 1F

L_0F5D:
	ld a,(hl)                     ; 0F5D  7E
	and 0x80                      ; 0F5E  E6 80
	jr z,L_0F64                   ; 0F60  28 02
	scf                           ; 0F62  37
	ret                           ; 0F63  C9

L_0F64:
	ld a,(GAME_VARS+0xB)          ; 0F64  3A F5 0A
	inc hl                        ; 0F67  23
	inc hl                        ; 0F68  23
	sub 0x08                      ; 0F69  D6 08
	cp (hl)                       ; 0F6B  BE
	ccf                           ; 0F6C  3F
	ret c                         ; 0F6D  D8

	add a,0x0E                    ; 0F6E  C6 0E
	cp (hl)                       ; 0F70  BE
	ret c                         ; 0F71  D8

	dec hl                        ; 0F72  2B
	ld a,(GAME_VARS+0xA)          ; 0F73  3A F4 0A
	sub 0x22                      ; 0F76  D6 22
	cp (hl)                       ; 0F78  BE
	ccf                           ; 0F79  3F
	ret c                         ; 0F7A  D8

	add a,0x06                    ; 0F7B  C6 06
	cp (hl)                       ; 0F7D  BE
	ret c                         ; 0F7E  D8

	dec hl                        ; 0F7F  2B
	ld (hl),0xB6                  ; 0F80  36 B6
	call L_23CF                   ; 0F82  CD CF 23
	jp L_2424                     ; 0F85  C3 24 24

	ret z                         ; 0F88  C8

	nop                           ; 0F89  00
L_0F8A:
	push bc                       ; 0F8A  C5
	push hl                       ; 0F8B  E5
	ld de,0x01                    ; 0F8C  11 01 00
	call RET_STUB                 ; 0F8F  CD F8 1C  ; в каноне +0x100 этот операнд стухший
	pop hl                        ; 0F92  E1
	inc hl                        ; 0F93  23
	pop bc                        ; 0F94  C1
	djnz L_0F8A                   ; 0F95  10 F3
	ret                           ; 0F97  C9

L_0F98:
	ld a,(GAME_VARS+0xC)          ; 0F98  3A F6 0A
	ld d,a                        ; 0F9B  57
	ld a,(LEVEL_VARS)             ; 0F9C  3A 7B 16
	cp d                          ; 0F9F  BA
	jr z,L_0FA4                   ; 0FA0  28 02
	xor a                         ; 0FA2  AF
	ret                           ; 0FA3  C9

L_0FA4:
	ld a,0x0C                     ; 0FA4  3E 0C
	ret                           ; 0FA6  C9

L_0FA7:
	ld c,0x20                     ; 0FA7  0E 20
	push bc                       ; 0FA9  C5
	call L_1F3F                   ; 0FAA  CD 3F 1F
	ld (D_1D08+0xC),a             ; 0FAD  32 14 1D
	ld a,b                        ; 0FB0  78
	ld (L_0FEB+0x1),a             ; 0FB1  32 EC 0F
	rlca                          ; 0FB4  07
	ld (L_0FD6+0x1),a             ; 0FB5  32 D7 0F
	ld b,l                        ; 0FB8  45
	ld c,h                        ; 0FB9  4C
	call SCR_ADDR_BIT14           ; 0FBA  CD 70 1B
	ld (L_0FE3+0x1),hl            ; 0FBD  22 E4 0F
	ld a,(D_1D08+0xC)             ; 0FC0  3A 14 1D
	add a,h                       ; 0FC3  84
	ld h,a                        ; 0FC4  67
	ld (L_0FF4+0x1),hl            ; 0FC5  22 F5 0F
	pop bc                        ; 0FC8  C1
	push bc                       ; 0FC9  C5
	ld c,0x02                     ; 0FCA  0E 02
	ld de,WORK_RAM+0x3E5          ; 0FCC  11 8D 3E  ; в каноне +0x100 этот операнд стухший
	call VDP_RD_STRIDE8           ; 0FCF  CD B4 1C
	pop bc                        ; 0FD2  C1
L_0FD3:
	push bc                       ; 0FD3  C5
	ld b,0x00                     ; 0FD4  06 00
L_0FD6:
	ld c,0x00                     ; 0FD6  0E 00
	ld hl,WORK_RAM+0x3E7          ; 0FD8  21 8F 3E  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x3E5          ; 0FDB  11 8D 3E  ; в каноне +0x100 этот операнд стухший
	ldir                          ; 0FDE  ED B0
	call L_1F36                   ; 0FE0  CD 36 1F
L_0FE3:
	ld hl,0x00                    ; 0FE3  21 00 00
	ld de,WORK_RAM+0x3E5          ; 0FE6  11 8D 3E  ; в каноне +0x100 этот операнд стухший
	ld c,0x02                     ; 0FE9  0E 02
L_0FEB:
	ld b,0x00                     ; 0FEB  06 00
	push bc                       ; 0FED  C5
	call VDP_WR_STRIDE8           ; 0FEE  CD 1D 1B
	ld de,WORK_RAM+0x3E5          ; 0FF1  11 8D 3E  ; в каноне +0x100 этот операнд стухший
L_0FF4:
	ld hl,0x00                    ; 0FF4  21 00 00
	pop bc                        ; 0FF7  C1
	call VDP_WR_STRIDE8           ; 0FF8  CD 1D 1B
	call SFX_64D7                 ; 0FFB  CD DA 1F
	pop bc                        ; 0FFE  C1
	dec c                         ; 0FFF  0D
	jr nz,L_0FD3                  ; 1000  20 D1
	call SFX_64F5                 ; 1002  CD 9A 20
	call L_0F4A                   ; 1005  CD 4A 0F
	jp L_0F2E                     ; 1008  C3 2E 0F

D_100B:			; данные 100B..1018 (14 байт)
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 100B
L_1019:
	ld (L_1084+0x1),a             ; 1019  32 85 10
	ld (L_104B+0x1),a             ; 101C  32 4C 10
	ld (L_103B+0x1),a             ; 101F  32 3C 10
	ld (L_1077+0x1),a             ; 1022  32 78 10
	call L_1F3F                   ; 1025  CD 3F 1F
	ld (D_1D08+0xC),a             ; 1028  32 14 1D
	ld b,l                        ; 102B  45
	ld c,h                        ; 102C  4C
	call SCR_ADDR_BIT14           ; 102D  CD 70 1B
	ld (L_1071+0x1),hl            ; 1030  22 72 10
	ld a,(D_1D08+0xC)             ; 1033  3A 14 1D
	add a,h                       ; 1036  84
	ld h,a                        ; 1037  67
	ld (L_107E+0x1),hl            ; 1038  22 7F 10
L_103B:
	ld c,0x00                     ; 103B  0E 00
	ld b,0x45                     ; 103D  06 45
	ld de,WORK_RAM+0x3EC          ; 103F  11 94 3E  ; в каноне +0x100 этот операнд стухший
	call VDP_RD_STRIDE8           ; 1042  CD B4 1C
	ex de,hl                      ; 1045  EB
	dec hl                        ; 1046  2B
	ld (L_1068+0x1),hl            ; 1047  22 69 10
	push hl                       ; 104A  E5
L_104B:
	ld de,0x00                    ; 104B  11 00 00
	and a                         ; 104E  A7
	sbc hl,de                     ; 104F  ED 52
	ld (L_1065+0x1),hl            ; 1051  22 66 10
	pop hl                        ; 1054  E1
	ld de,WORK_RAM+0x3EC          ; 1055  11 94 3E  ; в каноне +0x100 этот операнд стухший
	and a                         ; 1058  A7
	sbc hl,de                     ; 1059  ED 52
	ld (L_1062+0x1),hl            ; 105B  22 63 10
	ld bc,0x4530                  ; 105E  01 30 45
L_1061:
	push bc                       ; 1061  C5
L_1062:
	ld bc,0x00                    ; 1062  01 00 00
L_1065:
	ld hl,0x00                    ; 1065  21 00 00
L_1068:
	ld de,0x00                    ; 1068  11 00 00
	lddr                          ; 106B  ED B8
	ex de,hl                      ; 106D  EB
	call L_1F36                   ; 106E  CD 36 1F
L_1071:
	ld hl,0x00                    ; 1071  21 00 00
	ld de,WORK_RAM+0x3EC          ; 1074  11 94 3E  ; в каноне +0x100 этот операнд стухший
L_1077:
	ld c,0x00                     ; 1077  0E 00
	ld b,0x45                     ; 1079  06 45
	call VDP_WR_STRIDE8           ; 107B  CD 1D 1B
L_107E:
	ld hl,0x00                    ; 107E  21 00 00
	ld de,WORK_RAM+0x3EC          ; 1081  11 94 3E  ; в каноне +0x100 этот операнд стухший
L_1084:
	ld c,0x00                     ; 1084  0E 00
	ld b,0x45                     ; 1086  06 45
	call VDP_WR_STRIDE8           ; 1088  CD 1D 1B
	call SFX_64D7                 ; 108B  CD DA 1F
	pop bc                        ; 108E  C1
	dec c                         ; 108F  0D
	jr nz,L_1061                  ; 1090  20 CF
	ret                           ; 1092  C9

	ret nz                        ; 1093  C0

	jp c,SPR_BANK_294B+0x17C      ; 1094  DA C7 2A  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x3EC          ; 1097  11 94 3E  ; в каноне +0x100 этот операнд стухший
	and a                         ; 109A  A7
	sbc hl,de                     ; 109B  ED 52
	ld (L_10A4+0x1),hl            ; 109D  22 A5 10  ; в каноне +0x100 этот операнд стухший
	ld bc,0x4517                  ; 10A0  01 17 45
L_10A3:
	push bc                       ; 10A3  C5
L_10A4:
	ld bc,0x00                    ; 10A4  01 00 00
	ld hl,0x00                    ; 10A7  21 00 00
	ld de,0x00                    ; 10AA  11 00 00
	lddr                          ; 10AD  ED B8
	ex de,hl                      ; 10AF  EB
	call L_1F36                   ; 10B0  CD 36 1F  ; в каноне +0x100 этот операнд стухший
	ld hl,0x00                    ; 10B3  21 00 00
	ld de,WORK_RAM+0x3EC          ; 10B6  11 94 3E  ; в каноне +0x100 этот операнд стухший
	ld c,0x00                     ; 10B9  0E 00
	ld b,0x45                     ; 10BB  06 45
	call VDP_WR_STRIDE8           ; 10BD  CD 1D 1B  ; в каноне +0x100 этот операнд стухший
	ld hl,0x00                    ; 10C0  21 00 00
	ld de,WORK_RAM+0x3EC          ; 10C3  11 94 3E  ; в каноне +0x100 этот операнд стухший
	ld c,0x00                     ; 10C6  0E 00
	ld b,0x45                     ; 10C8  06 45
	call VDP_WR_STRIDE8           ; 10CA  CD 1D 1B  ; в каноне +0x100 этот операнд стухший
	pop bc                        ; 10CD  C1
	dec c                         ; 10CE  0D
	jr nz,L_10A3                  ; 10CF  20 D2
	ret                           ; 10D1  C9

D_10D2:			; данные 10D2..10DA (9 байт)
	db	0x45,0xCD,0x1D,0xD2,0xC1,0x0D,0x20,0xD2,0xC9	; 10D2
L_10DB:
	ld iy,OBJ_TABLE_9AA2          ; 10DB  FD 21 A2 9A
	ld b,0x14                     ; 10DF  06 14
L_10E1:
	push bc                       ; 10E1  C5
	call L_116A                   ; 10E2  CD 6A 11
	ld a,(GAME_VARS+0xC)          ; 10E5  3A F6 0A
	cp (iy+0x02)                  ; 10E8  FD BE 02
	jr nz,L_1122                  ; 10EB  20 35
	ld a,(iy+0x04)                ; 10ED  FD 7E 04
	and 0x7F                      ; 10F0  E6 7F
L_10F2:
	jr nz,L_110B                  ; 10F2  20 17
	ld a,(L_0837+0x1)             ; 10F4  3A 38 08
	or a                          ; 10F7  B7
	jr nz,L_110B                  ; 10F8  20 11
	call L_114B                   ; 10FA  CD 4B 11
	ld b,(iy+0x01)                ; 10FD  FD 46 01
	ld c,(iy+0x00)                ; 1100  FD 4E 00
	ld a,0x1E                     ; 1103  3E 1E
	call L_1226                   ; 1105  CD 26 12
	call L_0642                   ; 1108  CD 42 06
L_110B:
	ld a,(iy+0x03)                ; 110B  FD 7E 03
	and 0x3F                      ; 110E  E6 3F
	ld b,a                        ; 1110  47
	ld a,(iy+0x04)                ; 1111  FD 7E 04
	and 0x80                      ; 1114  E6 80
	or b                          ; 1116  B0
	ld b,(iy+0x01)                ; 1117  FD 46 01
	ld c,(iy+0x00)                ; 111A  FD 4E 00
	call L_19A0                   ; 111D  CD A0 19
	jr L_1142                     ; 1120  18 20

L_1122:
	ld a,(LEVEL_VARS)             ; 1122  3A 7B 16
	cp (iy+0x02)                  ; 1125  FD BE 02
	jr nz,L_1142                  ; 1128  20 18
	ld b,(iy+0x01)                ; 112A  FD 46 01
	ld a,(iy+0x00)                ; 112D  FD 7E 00
	add a,0x60                    ; 1130  C6 60
	ld c,a                        ; 1132  4F
	ld a,(iy+0x03)                ; 1133  FD 7E 03
	and 0x3F                      ; 1136  E6 3F
	ld d,a                        ; 1138  57
	ld a,(iy+0x04)                ; 1139  FD 7E 04
	and 0x80                      ; 113C  E6 80
	or d                          ; 113E  B2
	call L_19A0                   ; 113F  CD A0 19
L_1142:
	ld bc,0x09                    ; 1142  01 09 00
	add iy,bc                     ; 1145  FD 09
	pop bc                        ; 1147  C1
	djnz L_10E1                   ; 1148  10 97
	ret                           ; 114A  C9

L_114B:
	ld a,r                        ; 114B  ED 5F
	and 0x7F                      ; 114D  E6 7F
	cp 0x6E                       ; 114F  FE 6E
	ret c                         ; 1151  D8

	ld hl,(GAME_VARS+0xA)         ; 1152  2A F4 0A
	ld a,(iy+0x01)                ; 1155  FD 7E 01
	ld b,(iy+0x04)                ; 1158  FD 46 04
	cp h                          ; 115B  BC
	jr nc,L_1163                  ; 115C  30 05
	ld a,b                        ; 115E  78
L_115F:
	and 0x7F                      ; 115F  E6 7F
	jr L_1166                     ; 1161  18 03

L_1163:
	ld a,b                        ; 1163  78
	or 0x80                       ; 1164  F6 80
L_1166:
	ld (iy+0x04),a                ; 1166  FD 77 04
	ret                           ; 1169  C9

L_116A:
	ld a,(iy+0x04)                ; 116A  FD 7E 04
	and 0x7F                      ; 116D  E6 7F
	jr z,L_1175                   ; 116F  28 04
	dec (iy+0x04)                 ; 1171  FD 35 04
	ret                           ; 1174  C9

L_1175:
	call L_15F1                   ; 1175  CD F1 15
	ld a,(iy+0x04)                ; 1178  FD 7E 04
	and 0x80                      ; 117B  E6 80
	ld a,(iy+0x01)                ; 117D  FD 7E 01
L_1180:
	jr nz,L_118C                  ; 1180  20 0A
	add a,0x03                    ; 1182  C6 03
	ld b,(iy+0x05)                ; 1184  FD 46 05
	ld c,(iy+0x06)                ; 1187  FD 4E 06
	jr L_1194                     ; 118A  18 08

L_118C:
	sub 0x03                      ; 118C  D6 03
	ld b,(iy+0x07)                ; 118E  FD 46 07
	ld c,(iy+0x08)                ; 1191  FD 4E 08
L_1194:
	ld (iy+0x01),a                ; 1194  FD 77 01
	ld a,(iy+0x02)                ; 1197  FD 7E 02
	cp b                          ; 119A  B8
	jr nz,L_11AE                  ; 119B  20 11
	ld a,(iy+0x01)                ; 119D  FD 7E 01
	cp c                          ; 11A0  B9
	jr nz,L_11AE                  ; 11A1  20 0B
	ld a,(iy+0x04)                ; 11A3  FD 7E 04
	xor 0x80                      ; 11A6  EE 80
	ld (iy+0x04),a                ; 11A8  FD 77 04
	call L_116A                   ; 11AB  CD 6A 11
L_11AE:
	ld a,(iy+0x01)                ; 11AE  FD 7E 01
	cp 0xE6                       ; 11B1  FE E6
	jr nc,L_11D5                  ; 11B3  30 20
	cp 0xA3                       ; 11B5  FE A3
	ret c                         ; 11B7  D8

	ld b,(iy+0x02)                ; 11B8  FD 46 02
	inc (iy+0x02)                 ; 11BB  FD 34 02
	ld a,(GAME_VARS+0xC)          ; 11BE  3A F6 0A
	cp b                          ; 11C1  B8
	jr nz,L_11C9                  ; 11C2  20 05
	call THUNK_CDC5_D00           ; 11C4  CD FE 1C
	jr L_11D0                     ; 11C7  18 07

L_11C9:
	ld a,(LEVEL_VARS)             ; 11C9  3A 7B 16
	cp b                          ; 11CC  B8
	call z,THUNK_CDC5_D60         ; 11CD  CC 03 1D
L_11D0:
	ld (iy+0x01),0x00             ; 11D0  FD 36 01 00
	ret                           ; 11D4  C9

L_11D5:
	ld b,(iy+0x02)                ; 11D5  FD 46 02
	dec (iy+0x02)                 ; 11D8  FD 35 02
	ld a,(GAME_VARS+0xC)          ; 11DB  3A F6 0A
	cp b                          ; 11DE  B8
	jr nz,L_11E6                  ; 11DF  20 05
	call THUNK_CDC5_D00           ; 11E1  CD FE 1C
	jr L_11ED                     ; 11E4  18 07

L_11E6:
	ld a,(LEVEL_VARS)             ; 11E6  3A 7B 16
	cp b                          ; 11E9  B8
	call z,THUNK_CDC5_D60         ; 11EA  CC 03 1D
L_11ED:
	ld (iy+0x01),0xA2             ; 11ED  FD 36 01 A2
	ret                           ; 11F1  C9

L_11F2:
	ld de,0x1C00                  ; 11F2  11 00 1C
	ld (L_1208+0x1),a             ; 11F5  32 09 12
	ld (L_120C+0x1),a             ; 11F8  32 0D 12
	ld a,(GAME_VARS+0x7)          ; 11FB  3A F1 0A
	cp 0x05                       ; 11FE  FE 05
	jr nz,L_1204                  ; 1200  20 02
	ld d,0x14                     ; 1202  16 14
L_1204:
	ld hl,(GAME_VARS+0xA)         ; 1204  2A F4 0A
	ld a,l                        ; 1207  7D
L_1208:
	add a,0x1E                    ; 1208  C6 1E
	cp c                          ; 120A  B9
	ret c                         ; 120B  D8

L_120C:
	sub 0x1E                      ; 120C  D6 1E
	sub d                         ; 120E  92
	cp 0xE6                       ; 120F  FE E6
	jr c,L_1214                   ; 1211  38 01
	xor a                         ; 1213  AF
L_1214:
	cp c                          ; 1214  B9
	ret nc                        ; 1215  D0

	ld a,h                        ; 1216  7C
	add a,0x0C                    ; 1217  C6 0C
	cp b                          ; 1219  B8
	ret c                         ; 121A  D8

	sub 0x20                      ; 121B  D6 20
	cp 0xE6                       ; 121D  FE E6
	jr c,L_1222                   ; 121F  38 01
	xor a                         ; 1221  AF
L_1222:
	cp b                          ; 1222  B8
	ret nc                        ; 1223  D0

	inc e                         ; 1224  1C
	ret                           ; 1225  C9

L_1226:
	call L_11F2                   ; 1226  CD F2 11
	xor a                         ; 1229  AF
	cp e                          ; 122A  BB
	ret z                         ; 122B  C8

L_122C:
	ld a,0x13                     ; 122C  3E 13
	dec a                         ; 122E  3D
	push af                       ; 122F  F5
	ld (L_122C+0x1),a             ; 1230  32 2D 12
	push af                       ; 1233  F5
	and 0x38                      ; 1234  E6 38
	ld c,a                        ; 1236  4F
	pop af                        ; 1237  F1
	and 0x07                      ; 1238  E6 07
	ld b,0x00                     ; 123A  06 00
	ld hl,0x48C9                  ; 123C  21 C9 48
	add hl,bc                     ; 123F  09
	sub 0x08                      ; 1240  D6 08
	neg                           ; 1242  ED 44
	ld b,a                        ; 1244  47
	ld a,0xFF                     ; 1245  3E FF
L_1247:
	sla a                         ; 1247  CB 27
	djnz L_1247                   ; 1249  10 FC
	and 0x7F                      ; 124B  E6 7F
	ld bc,0x07                    ; 124D  01 07 00
	call VDP_FILL                 ; 1250  CD 11 1C
	ld hl,0x1388                  ; 1253  21 88 13
	ld de,0x01                    ; 1256  11 01 00
	call SFX_64C8                 ; 1259  CD 94 20
	pop af                        ; 125C  F1
	ret nz                        ; 125D  C0

	ld a,0x02                     ; 125E  3E 02
	jp L_0F27                     ; 1260  C3 27 0F

D_1263:			; данные 1263..1274 (18 байт)
	db	0xC9,0xCD,0xA7,0xCC,0x3A,0x7B,0xCD,0xC6,0x80,0x47,0xCD,0x84,0xD1,0x3A,0xF6,0xC1	; 1263
	db	0xCD,0x6C	; 1273
L_1275:
	ld iy,LEVEL_VARS+0x1          ; 1275  FD 21 7C 16
	ld b,0x03                     ; 1279  06 03
	ld a,(LEVEL_VARS+0x7)         ; 127B  3A 82 16
	or a                          ; 127E  B7
	jr nz,L_1283                  ; 127F  20 02
	ld b,0x01                     ; 1281  06 01
L_1283:
	push bc                       ; 1283  C5
	ld a,(GAME_VARS+0xC)          ; 1284  3A F6 0A
	cp (iy+0x00)                  ; 1287  FD BE 00
	jr nz,L_1296                  ; 128A  20 0A
	call L_12B5                   ; 128C  CD B5 12
	ld d,0x00                     ; 128F  16 00
	call L_12AB                   ; 1291  CD AB 12
	jr L_12A3                     ; 1294  18 0D

L_1296:
	ld a,(LEVEL_VARS)             ; 1296  3A 7B 16
	ld d,0x60                     ; 1299  16 60
	cp (iy+0x00)                  ; 129B  FD BE 00
	jr nz,L_12A3                  ; 129E  20 03
L_12A0:
	call L_12AB                   ; 12A0  CD AB 12
L_12A3:
	inc iy                        ; 12A3  FD 23
	inc iy                        ; 12A5  FD 23
	pop bc                        ; 12A7  C1
	djnz L_1283                   ; 12A8  10 D9
	ret                           ; 12AA  C9

L_12AB:
	ld l,(iy+0x0C)                ; 12AB  FD 6E 0C
	ld h,(iy+0x0D)                ; 12AE  FD 66 0D
	ld b,(iy+0x01)                ; 12B1  FD 46 01
	jp (hl)                       ; 12B4  E9
L_12B5:
	ld a,(iy+0x06)                ; 12B5  FD 7E 06
	or a                          ; 12B8  B7
	ret nz                        ; 12B9  C0

	ld a,0xF6                     ; 12BA  3E F6
	out (0xAA),a                  ; 12BC  D3 AA
	nop                           ; 12BE  00
	in a,(0xA9)                   ; 12BF  DB A9
	bit 0,a                       ; 12C1  CB 47
	nop                           ; 12C3  00
	nop                           ; 12C4  00
	ret nz                        ; 12C5  C0

	ld b,(iy+0x01)                ; 12C6  FD 46 01
	ld a,(GAME_VARS+0xB)          ; 12C9  3A F5 0A
	add a,0x04                    ; 12CC  C6 04
	cp b                          ; 12CE  B8
	ret c                         ; 12CF  D8

	sub 0x08                      ; 12D0  D6 08
	cp b                          ; 12D2  B8
	ret nc                        ; 12D3  D0

	ld a,0x01                     ; 12D4  3E 01
	ld (iy+0x06),a                ; 12D6  FD 77 06
	ld l,(iy+0x12)                ; 12D9  FD 6E 12
	ld h,(iy+0x13)                ; 12DC  FD 66 13
	jp (hl)                       ; 12DF  E9
L_12E0:
	ret                           ; 12E0  C9

L_12E1:
	ld a,0x07                     ; 12E1  3E 07
	out (0xA0),a                  ; 12E3  D3 A0
	ld a,0xFF                     ; 12E5  3E FF
	out (0xA1),a                  ; 12E7  D3 A1
	ld a,0x0E                     ; 12E9  3E 0E
	out (0xA0),a                  ; 12EB  D3 A0
	in a,(0xA2)                   ; 12ED  DB A2
	and 0x1F                      ; 12EF  E6 1F
	cp 0x1F                       ; 12F1  FE 1F
	ret z                         ; 12F3  C8

	cpl                           ; 12F4  2F
	ld b,a                        ; 12F5  47
	pop hl                        ; 12F6  E1
L_12F7:
	ret                           ; 12F7  C9

	push bc                       ; 12F8  C5
	ld a,0x1A                     ; 12F9  3E 1A
	call L_19A0                   ; 12FB  CD A0 19
	pop bc                        ; 12FE  C1
	ld a,b                        ; 12FF  78
	sub 0x08                      ; 1300  D6 08
	ld b,a                        ; 1302  47
	ld a,c                        ; 1303  79
	add a,0x08                    ; 1304  C6 08
	ld c,a                        ; 1306  4F
	pop af                        ; 1307  F1
	dec a                         ; 1308  3D
	jr nz,L_12F7                  ; 1309  20 EC
	ret                           ; 130B  C9

L_130C:
	ld hl,0x48C9                  ; 130C  21 C9 48
	ld b,0x06                     ; 130F  06 06
L_1311:
	push bc                       ; 1311  C5
L_1312:
	push hl                       ; 1312  E5
	ld a,0x77                     ; 1313  3E 77
	ld bc,0x07                    ; 1315  01 07 00
	call VDP_FILL                 ; 1318  CD 11 1C
	pop hl                        ; 131B  E1
	ld a,0x08                     ; 131C  3E 08
	add a,l                       ; 131E  85
	ld l,a                        ; 131F  6F
	pop bc                        ; 1320  C1
	djnz L_1311                   ; 1321  10 EE
	ld a,0x2F                     ; 1323  3E 2F
	ld (L_122C+0x1),a             ; 1325  32 2D 12
	ret                           ; 1328  C9

DEAD_1329:			; данные 1329..133C (20 байт)
; мёртвый обрывок: `jr nz` из него ведёт в середину инструкции по CB10, а
; хвост повторяет код по 84B1
	db	0x1D,0xD2,0x11,0x8D,0xF5,0x21,0x00,0x00,0xC1,0xCD,0x1D,0xD2,0xC1,0x0D,0x20,0xD7	; 1329
	db	0xC9,0x0E,0x20,0xFD	; 1339
L_133D:
	call L_18CA                   ; 133D  CD CA 18
	nop                           ; 1340  00
	nop                           ; 1341  00
	nop                           ; 1342  00
	call L_1694                   ; 1343  CD 94 16
	call L_23E9                   ; 1346  CD E9 23
	call L_130C                   ; 1349  CD 0C 13
	call L_1807                   ; 134C  CD 07 18
	call L_176A                   ; 134F  CD 6A 17
	call L_0AFF                   ; 1352  CD FF 0A
	call L_138D                   ; 1355  CD 8D 13
	ld hl,WORK_RAM+0x111          ; 1358  21 B9 3B  ; в каноне +0x100 этот операнд стухший
	ld de,WORK_RAM+0x112          ; 135B  11 BA 3B  ; в каноне +0x100 этот операнд стухший
	ld bc,0x56                    ; 135E  01 56 00
	ld (hl),0x00                  ; 1361  36 00
	ldir                          ; 1363  ED B0
	xor a                         ; 1365  AF
	ld (D_1642),a                 ; 1366  32 42 16
	ld a,(LEVEL_VARS+0x1)         ; 1369  3A 7C 16
	ld (LEVEL_VARS),a             ; 136C  32 7B 16
	call L_0C8C                   ; 136F  CD 8C 0C
L_1372:
	jp L_0F2B                     ; 1372  C3 2B 0F

D_1375:			; данные 1375..137A (6 байт)
	db	0xCB,0x01,0x16,0xDD,0xCB,0x00	; 1375
L_137B:
	nop                           ; 137B  00
	nop                           ; 137C  00
	nop                           ; 137D  00
	nop                           ; 137E  00
	nop                           ; 137F  00
	call SFX_64E6                 ; 1380  CD E5 1F
	ld a,(GAME_VARS+0x8)          ; 1383  3A F2 0A
	dec a                         ; 1386  3D
	ld (GAME_VARS+0x8),a          ; 1387  32 F2 0A
	jp L_16D8                     ; 138A  C3 D8 16

L_138D:
	ld hl,OBJ_ARRAY_INIT          ; 138D  21 E6 14
	ld de,OBJ_ARRAY_14BF          ; 1390  11 BF 14
	ld bc,0x27                    ; 1393  01 27 00
	ldir                          ; 1396  ED B0
	xor a                         ; 1398  AF
	ld (L_0899+0x1),a             ; 1399  32 9A 08
	ld (D_04D4),a                 ; 139C  32 D4 04
	ret                           ; 139F  C9

L_13A0:
	ld hl,TEXT_SHORT              ; 13A0  21 F9 9B  ; в каноне +0x100 этот операнд стухший
	ld de,0x0F1C                  ; 13A3  11 1C 0F
	ld b,0x13                     ; 13A6  06 13
	ld a,0x0F                     ; 13A8  3E 0F
	ld (L_0899+0x1),a             ; 13AA  32 9A 08  ; в каноне +0x100 этот операнд стухший
	jr L_13BF                     ; 13AD  18 10

L_13AF:
	ld hl,TEXT_SHORT+0x13         ; 13AF  21 0C 9C  ; в каноне +0x100 этот операнд стухший
L_13B2:
	ld de,0x0F1C                  ; 13B2  11 1C 0F
	jr L_13BD                     ; 13B5  18 06

L_13B7:
	ld hl,TEXT_SHORT+0x1E         ; 13B7  21 17 9C  ; в каноне +0x100 этот операнд стухший
	ld de,0x111C                  ; 13BA  11 1C 11
L_13BD:
	ld b,0x0B                     ; 13BD  06 0B
L_13BF:
	call L_16F9                   ; 13BF  CD F9 16  ; в каноне +0x100 этот операнд стухший
	ld b,0x00                     ; 13C2  06 00
	ld hl,0x01                    ; 13C4  21 01 00
	call L_0F8A                   ; 13C7  CD 8A 0F  ; в каноне +0x100 этот операнд стухший
	ld a,(D_1642)                 ; 13CA  3A 42 16  ; в каноне +0x100 этот операнд стухший
	add a,0x0F                    ; 13CD  C6 0F
	ld (D_1642),a                 ; 13CF  32 42 16  ; в каноне +0x100 этот операнд стухший
	jp L_130C                     ; 13D2  C3 0C 13  ; в каноне +0x100 этот операнд стухший

L_13D5:
	ld b,0x02                     ; 13D5  06 02
L_13D7:
	push bc                       ; 13D7  C5
	ld de,GFX_9940                ; 13D8  11 40 99
	call L_13E8                   ; 13DB  CD E8 13
	ld de,GFX_9940+0x50           ; 13DE  11 90 99
	call L_13E8                   ; 13E1  CD E8 13
	pop bc                        ; 13E4  C1
	djnz L_13D7                   ; 13E5  10 F0
	ret                           ; 13E7  C9

L_13E8:
	ld hl,0x4360                  ; 13E8  21 60 43
	ld b,0x02                     ; 13EB  06 02
L_13ED:
	push bc                       ; 13ED  C5
	ld bc,0x28                    ; 13EE  01 28 00
	push hl                       ; 13F1  E5
	call VDP_COPY_TO_VRAM         ; 13F2  CD 33 1C
	pop hl                        ; 13F5  E1
	inc h                         ; 13F6  24
	pop bc                        ; 13F7  C1
	djnz L_13ED                   ; 13F8  10 F3
	ld hl,0x00                    ; 13FA  21 00 00
L_13FD:
	dec hl                        ; 13FD  2B
	ld a,h                        ; 13FE  7C
	or l                          ; 13FF  B5
L_1400:
	jr nz,L_13FD                  ; 1400  20 FB
	ret                           ; 1402  C9

	jr nz,L_1400                  ; 1403  20 FB
	ret                           ; 1405  C9

D_1406:			; данные 1406..1407 (2 байт)
	db	0xFB,0xC9	; 1406
	ld c,0x00                     ; 1408  0E 00
	ld b,0x45                     ; 140A  06 45
	call VDP_WR_STRIDE8           ; 140C  CD 1D 1B  ; в каноне +0x100 этот операнд стухший
	pop bc                        ; 140F  C1
L_1410:
	dec c                         ; 1410  0D
L_1411:
	jr nz,L_1410                  ; 1411  20 FD
	ld a,(hl)                     ; 1413  7E
	nop                           ; 1414  00
	or a                          ; 1415  B7
	jr z,L_141D                   ; 1416  28 05
	dec (iy+0x00)                 ; 1418  FD 35 00
	jr L_1475                     ; 141B  18 58

L_141D:
	ld l,(iy+0x01)                ; 141D  FD 6E 01
	ld h,(iy+0x02)                ; 1420  FD 66 02
	ld a,(hl)                     ; 1423  7E
	inc hl                        ; 1424  23
	cp 0x0F                       ; 1425  FE 0F
	jr z,L_14A8                   ; 1427  28 7F
	cp 0x0C                       ; 1429  FE 0C
	jr z,L_149F                   ; 142B  28 72
	or a                          ; 142D  B7
	jp z,L_14B2                   ; 142E  CA B2 14  ; в каноне +0x100 этот операнд стухший
	ld e,a                        ; 1431  5F
	ld a,(hl)                     ; 1432  7E
	inc hl                        ; 1433  23
	ld (iy+0x00),a                ; 1434  FD 77 00
	ld (iy+0x01),l                ; 1437  FD 75 01
	ld (iy+0x02),h                ; 143A  FD 74 02
	ld bc,0x00                    ; 143D  01 00 00
	ld d,0x00                     ; 1440  16 00
	ld a,e                        ; 1442  7B
	and 0x0C                      ; 1443  E6 0C
	cp 0x08                       ; 1445  FE 08
	jr nz,L_144D                  ; 1447  20 04
	ld b,0x04                     ; 1449  06 04
	jr L_1453                     ; 144B  18 06

L_144D:
	cp 0x04                       ; 144D  FE 04
	jr nz,L_1453                  ; 144F  20 02
	ld b,0xFC                     ; 1451  06 FC
L_1453:
	ld a,e                        ; 1453  7B
	and 0x03                      ; 1454  E6 03
	cp 0x03                       ; 1456  FE 03
	jr nz,L_145E                  ; 1458  20 04
	ld d,0x01                     ; 145A  16 01
	jr L_146C                     ; 145C  18 0E

L_145E:
	cp 0x02                       ; 145E  FE 02
	jr nz,L_1466                  ; 1460  20 04
	ld c,0x02                     ; 1462  0E 02
	jr L_146C                     ; 1464  18 06

L_1466:
	cp 0x01                       ; 1466  FE 01
	jr nz,L_146C                  ; 1468  20 02
	ld c,0xFE                     ; 146A  0E FE
L_146C:
	ld (iy+0x0C),c                ; 146C  FD 71 0C
	ld (iy+0x04),b                ; 146F  FD 70 04
	ld (iy+0x05),d                ; 1472  FD 72 05
L_1475:
	ld d,(iy+0x05)                ; 1475  FD 56 05
	ld c,(iy+0x04)                ; 1478  FD 4E 04
	ld b,(iy+0x0C)                ; 147B  FD 46 0C
	ld a,(iy+0x0B)                ; 147E  FD 7E 0B
	and 0x80                      ; 1481  E6 80
	ld e,a                        ; 1483  5F
	ld a,0xFE                     ; 1484  3E FE
	cp b                          ; 1486  B8
	jr z,L_1492                   ; 1487  28 09
	ld a,0x02                     ; 1489  3E 02
	cp b                          ; 148B  B8
	jr nz,L_1494                  ; 148C  20 06
	ld e,0x80                     ; 148E  1E 80
	jr L_1494                     ; 1490  18 02

L_1492:
	ld e,0x00                     ; 1492  1E 00
L_1494:
	ld a,(iy+0x07)                ; 1494  FD 7E 07
	add a,c                       ; 1497  81
	ld c,a                        ; 1498  4F
	ld a,(iy+0x08)                ; 1499  FD 7E 08
	add a,b                       ; 149C  80
	ld b,a                        ; 149D  47
	ret                           ; 149E  C9

L_149F:
	ld e,(hl)                     ; 149F  5E
	inc hl                        ; 14A0  23
	ld d,(hl)                     ; 14A1  56
	inc hl                        ; 14A2  23
	ld a,(de)                     ; 14A3  1A
	and 0x80                      ; 14A4  E6 80
	jr z,L_14B2                   ; 14A6  28 0A
L_14A8:
	ld a,r                        ; 14A8  ED 5F
	ld bc,0x02                    ; 14AA  01 02 00
	and 0x01                      ; 14AD  E6 01
	jr z,L_14B2                   ; 14AF  28 01
	add hl,bc                     ; 14B1  09
L_14B2:
	ld e,(hl)                     ; 14B2  5E
	inc hl                        ; 14B3  23
	ld d,(hl)                     ; 14B4  56
	ex de,hl                      ; 14B5  EB
	ld (iy+0x01),l                ; 14B6  FD 75 01
	ld (iy+0x02),h                ; 14B9  FD 74 02
	jp L_141D                     ; 14BC  C3 1D 14  ; в каноне +0x100 этот операнд стухший

OBJ_ARRAY_14BF:			; данные 14BF..14E5 (39 байт)
; рабочий массив объектов: 3 записи по 0x0D байт (0x27 = 39 = 3*13 байт
; копирует ldir из CB8D). База для iy в блоке C0FB (там написано ld
; iy,0xCBBF — операнд не пережил сдвиг +0x100). Отдельные поля читает
; C083: CCC5, CCC8, CCD2, CCD5, CCDF. Указателей в записи НЕТ: пара
; iy+7/iy+8 читается как b,c (C1C2/C22C) и идёт в рисование спрайта
; координатами, а не адресом
	db	0x00,0x28,0x78,0x27,0x00,0x00,0x0B,0x50,0x32,0x00,0x2A,0x00,0x00,0x00,0x2E,0x78	; 14BF
	db	0x2B,0x00,0x00,0x32,0x50,0x80,0x00,0x2E,0x00,0x00,0x00,0x2B,0x78,0x2F,0x00,0x00	; 14CF
	db	0x53,0x30,0x52,0x00,0x30,0x00,0x00	; 14DF
OBJ_ARRAY_INIT:			; данные 14E6..150C (39 байт)
; начальные значения массива: CB8D делает ld hl,0xCCE6 / ld de,0xCCBF / ld
; bc,0x27 / ldir
	db	0x00,0x28,0x78,0x27,0x00,0x00,0x0B,0x50,0x32,0x00,0x2A,0x00,0x00,0x00,0x2E,0x78	; 14E6
	db	0x2B,0x00,0x00,0x32,0x50,0x80,0x00,0x2E,0x00,0x00,0x00,0x2B,0x78,0x2F,0x00,0x00	; 14F6
	db	0x53,0x30,0x52,0x00,0x30,0x00,0x00	; 1506
L_150D:
	call L_18CA                   ; 150D  CD CA 18
	ld hl,0x6000                  ; 1510  21 00 60
	ld bc,0x181F                  ; 1513  01 1F 18
	ld a,0x30                     ; 1516  3E 30
	call L_1828                   ; 1518  CD 28 18
	ld hl,WORK_RAM+0x111          ; 151B  21 B9 3B  ; в каноне +0x100 этот операнд стухший
	ld bc,0x5700                  ; 151E  01 00 57
L_1521:
	ld a,(hl)                     ; 1521  7E
	or a                          ; 1522  B7
	jr z,L_1526                   ; 1523  28 01
	inc c                         ; 1525  0C
L_1526:
	inc hl                        ; 1526  23
	djnz L_1521                   ; 1527  10 F8
	srl c                         ; 1529  CB 39
	srl c                         ; 152B  CB 39
	ld a,(D_1642)                 ; 152D  3A 42 16
	add a,c                       ; 1530  81
	ld c,0x00                     ; 1531  0E 00
L_1533:
	cp 0x0A                       ; 1533  FE 0A
	jr c,L_153C                   ; 1535  38 05
	sub 0x0A                      ; 1537  D6 0A
	inc c                         ; 1539  0C
	jr L_1533                     ; 153A  18 F7

L_153C:
	ld b,0x02                     ; 153C  06 02
	ld hl,TEXT_ES+0x15            ; 153E  21 F5 99
L_1541:
	and a                         ; 1541  A7
	jr z,L_1548                   ; 1542  28 04
	add a,0x3A                    ; 1544  C6 3A
	jr L_154A                     ; 1546  18 02

L_1548:
	ld a,0x44                     ; 1548  3E 44
L_154A:
	ld (hl),a                     ; 154A  77
	dec hl                        ; 154B  2B
	ld a,c                        ; 154C  79
	djnz L_1541                   ; 154D  10 F2
	ld hl,TEXT_ES                 ; 154F  21 E0 99
	ld de,0x0808                  ; 1552  11 08 08
	ld b,0x29                     ; 1555  06 29
	call L_16F9                   ; 1557  CD F9 16
	jp MUS_TRACK_1                ; 155A  C3 E7 28

L_155D:
	ld a,0xF3                     ; 155D  3E F3
	out (0xAA),a                  ; 155F  D3 AA
	in a,(0xA9)                   ; 1561  DB A9
	bit 5,a                       ; 1563  CB 6F
	jr z,L_155D                   ; 1565  28 F6
L_1567:
	ld b,0xF0                     ; 1567  06 F0
L_1569:
	ld a,b                        ; 1569  78
	out (0xAA),a                  ; 156A  D3 AA
	nop                           ; 156C  00
	in a,(0xA9)                   ; 156D  DB A9
	cp 0xFF                       ; 156F  FE FF
	ret nz                        ; 1571  C0

	ld a,b                        ; 1572  78
	inc a                         ; 1573  3C
	ld b,a                        ; 1574  47
	cp 0xF9                       ; 1575  FE F9
	jr z,L_1567                   ; 1577  28 EE
	jr L_1569                     ; 1579  18 EE

L_157B:
	call L_12E1                   ; 157B  CD E1 12
	push hl                       ; 157E  E5
	push de                       ; 157F  D5
	ld e,0x05                     ; 1580  1E 05
	ld hl,D_1595                  ; 1582  21 95 15
	ld b,0x00                     ; 1585  06 00
L_1587:
	ld c,(hl)                     ; 1587  4E
	nop                           ; 1588  00
	call KBD_SCAN                 ; 1589  CD DF 1C
	rl b                          ; 158C  CB 10
	inc hl                        ; 158E  23
	dec e                         ; 158F  1D
	jr nz,L_1587                  ; 1590  20 F5
	pop de                        ; 1592  D1
	pop hl                        ; 1593  E1
	ret                           ; 1594  C9

D_1595:			; данные 1595..1599 (5 байт)
	db	0x80,0x45,0x44,0x26,0x46	; 1595
L_159A:
	ld hl,0x6000                  ; 159A  21 00 60
	ld a,0xF1                     ; 159D  3E F1
	call L_15B3                   ; 159F  CD B3 15
	ld hl,0x4000                  ; 15A2  21 00 40
	jr L_15B2                     ; 15A5  18 0B

L_15A7:
	ld hl,0x6C00                  ; 15A7  21 00 6C
	ld a,0xF1                     ; 15AA  3E F1
	call L_15B3                   ; 15AC  CD B3 15
	ld hl,0x4C00                  ; 15AF  21 00 4C
L_15B2:
	xor a                         ; 15B2  AF
L_15B3:
	ld e,0x0C                     ; 15B3  1E 0C
L_15B5:
	ld bc,0xC0                    ; 15B5  01 C0 00
	push af                       ; 15B8  F5
	call VDP_FILL                 ; 15B9  CD 11 1C
	pop af                        ; 15BC  F1
	ld l,0x00                     ; 15BD  2E 00
	inc h                         ; 15BF  24
	dec e                         ; 15C0  1D
	jr nz,L_15B5                  ; 15C1  20 F2
	ret                           ; 15C3  C9

D_15C4:			; данные 15C4..15CE (11 байт)
	db	0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9	; 15C4
L_15CF:
	ret                           ; 15CF  C9

L_15D0:
	ld a,0xC9                     ; 15D0  3E C9
	ld (L_20A8),a                 ; 15D2  32 A8 20
	xor a                         ; 15D5  AF
	call L_2168                   ; 15D6  CD 68 21
	ld a,0xE5                     ; 15D9  3E E5
	ld (L_20A8),a                 ; 15DB  32 A8 20
	ret                           ; 15DE  C9

	ex de,hl                      ; 15DF  EB
L_15E0:
	ld (hl),0xD1                  ; 15E0  36 D1
	djnz L_15E0                   ; 15E2  10 FC
	ret                           ; 15E4  C9

D_15E5:			; данные 15E5..15F0 (12 байт)
	db	0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9	; 15E5
L_15F1:
	ld a,(iy+0x04)                ; 15F1  FD 7E 04
	and 0x7F                      ; 15F4  E6 7F
	ld a,(iy+0x03)                ; 15F6  FD 7E 03
L_15F9:
	ret nz                        ; 15F9  C0

L_15FA:
	ld b,0x01                     ; 15FA  06 01
	bit 6,a                       ; 15FC  CB 77
	jr z,L_1602                   ; 15FE  28 02
	ld b,0x02                     ; 1600  06 02
L_1602:
	bit 7,a                       ; 1602  CB 7F
	jr z,L_160B                   ; 1604  28 05
	sub b                         ; 1606  90
	xor 0x40                      ; 1607  EE 40
	jr L_160C                     ; 1609  18 01

L_160B:
	add a,b                       ; 160B  80
L_160C:
	xor 0x80                      ; 160C  EE 80
	ld (iy+0x03),a                ; 160E  FD 77 03
	ret                           ; 1611  C9

L_1612:
	call L_1643                   ; 1612  CD 43 16
	ld hl,0x70C8                  ; 1615  21 C8 70
	ld bc,0x0303                  ; 1618  01 03 03
	ld a,0xF1                     ; 161B  3E F1
	jr L_1634                     ; 161D  18 15

L_161F:
	call L_1643                   ; 161F  CD 43 16
	ld hl,0x6CC8                  ; 1622  21 C8 6C
	ld bc,0x0304                  ; 1625  01 04 03
	ld a,0xA0                     ; 1628  3E A0
	jr L_1634                     ; 162A  18 08

L_162C:
	ld hl,0x6CE8                  ; 162C  21 E8 6C
	ld bc,0x0302                  ; 162F  01 02 03
	ld a,0x50                     ; 1632  3E 50
L_1634:
	call L_1828                   ; 1634  CD 28 18
	ld a,(D_1642)                 ; 1637  3A 42 16
	add a,0x0F                    ; 163A  C6 0F
	ld (D_1642),a                 ; 163C  32 42 16
	jp RET_STUB                   ; 163F  C3 F8 1C

D_1642:			; данные 1642..1642 (1 байт)
	db	0x00	; 1642
L_1643:
	ld b,(iy+0x01)                ; 1643  FD 46 01
	ld c,0x38                     ; 1646  0E 38
	ld a,0x17                     ; 1648  3E 17
	jp L_15CF                     ; 164A  C3 CF 15

L_164D:
	ld a,(iy+0x06)                ; 164D  FD 7E 06
	and a                         ; 1650  A7
	ret nz                        ; 1651  C0

	ld a,0x19                     ; 1652  3E 19
	jr L_1672                     ; 1654  18 1C

L_1656:
	ld e,0x17                     ; 1656  1E 17
	jr L_165C                     ; 1658  18 02

L_165A:
	ld e,0x18                     ; 165A  1E 18
L_165C:
	ld a,(iy+0x06)                ; 165C  FD 7E 06
	and a                         ; 165F  A7
	jr nz,L_1670                  ; 1660  20 0E
	ld a,e                        ; 1662  7B
	ex af,af'                     ; 1663  08
	ld a,0x39                     ; 1664  3E 39
	add a,d                       ; 1666  82
	ld c,a                        ; 1667  4F
	ex af,af'                     ; 1668  08
	push bc                       ; 1669  C5
	push de                       ; 166A  D5
	call L_19A0                   ; 166B  CD A0 19
	pop de                        ; 166E  D1
	pop bc                        ; 166F  C1
L_1670:
	ld a,0x16                     ; 1670  3E 16
L_1672:
	ex af,af'                     ; 1672  08
	ld a,0x50                     ; 1673  3E 50
	add a,d                       ; 1675  82
	ld c,a                        ; 1676  4F
	ex af,af'                     ; 1677  08
	jp L_19A0                     ; 1678  C3 A0 19

LEVEL_VARS:			; данные 167B..1687 (13 байт)
; переменные уровня: CE7B, CE7C, CE7E, CE80, CE82, CE84, CE86 — 22
; обращения из живого кода
	db	0x35,0x35,0x90,0x1C,0x80,0x0F,0x50,0x00,0x00,0x00,0x00,0x00,0x00	; 167B
JUMP_TABLE_1688:			; данные 1688..1693 (12 байт)
; таблица переходов, 6 слов: CE5A, CE56, CE4D, CE12, CE1F, CE2C. Все шесть
; разобраны как код (точки входа в tools/entries.json)
	dw	L_165A	; 1688  5A 16
	dw	L_1656	; 168A  56 16
	dw	L_164D	; 168C  4D 16
	dw	L_1612	; 168E  12 16
	dw	L_161F	; 1690  1F 16
	dw	L_162C	; 1692  2C 16
L_1694:
	ld hl,SPR_BANK_294B           ; 1694  21 4B 29
	ld (SPR_BANK_VAR+0x1),hl      ; 1697  22 53 1B
	ld bc,L_115F+0x1              ; 169A  01 60 11
	ld a,0x17                     ; 169D  3E 17
	call L_1B02                   ; 169F  CD 02 1B
	ld bc,L_1180                  ; 16A2  01 80 11
	ld a,0x18                     ; 16A5  3E 18
	call L_1B02                   ; 16A7  CD 02 1B
	ld bc,SPR_BANK_294B+0x815     ; 16AA  01 60 31
	ld a,0x19                     ; 16AD  3E 19
	call L_1B02                   ; 16AF  CD 02 1B
	ld hl,SPR_DATA_8E76           ; 16B2  21 76 8E
	ld (SPR_BANK_VAR+0x1),hl      ; 16B5  22 53 1B
	ret                           ; 16B8  C9

	ld hl,0x3E                    ; 16B9  21 3E 00
	ld b,0x00                     ; 16BC  06 00
L_16BE:
	in a,(0x1F)                   ; 16BE  DB 1F
	bit 5,a                       ; 16C0  CB 6F
	jr nz,L_16C9                  ; 16C2  20 05
	djnz L_16BE                   ; 16C4  10 F8
	ld hl,0x1FDB                  ; 16C6  21 DB 1F
L_16C9:
	ld (L_157B),hl                ; 16C9  22 7B 15  ; в каноне +0x100 этот операнд стухший
	ret                           ; 16CC  C9

L_16CD:
	ld de,0x18                    ; 16CD  11 18 00
	ld b,0x7F                     ; 16D0  06 7F
	ld hl,HUD_TILES               ; 16D2  21 56 9B
	jp L_16F9                     ; 16D5  C3 F9 16

L_16D8:
	ld de,0x011D                  ; 16D8  11 1D 01
	ld hl,0x21E8                  ; 16DB  21 E8 21
L_16DE:
	and a                         ; 16DE  A7
	jr z,L_16EC                   ; 16DF  28 0B
	dec a                         ; 16E1  3D
	dec de                        ; 16E2  1B
	dec de                        ; 16E3  1B
	push af                       ; 16E4  F5
	ld a,l                        ; 16E5  7D
	sub 0x10                      ; 16E6  D6 10
	ld l,a                        ; 16E8  6F
	pop af                        ; 16E9  F1
	jr L_16DE                     ; 16EA  18 F2

L_16EC:
	ld a,0xA0                     ; 16EC  3E A0
	ld bc,0x0402                  ; 16EE  01 02 04
	call L_1828                   ; 16F1  CD 28 18
	ld b,0x0B                     ; 16F4  06 0B
	ld hl,HUD_TILES+0x98          ; 16F6  21 EE 9B
L_16F9:
	push bc                       ; 16F9  C5
	push de                       ; 16FA  D5
	push hl                       ; 16FB  E5
	ld a,(hl)                     ; 16FC  7E
	cp 0x20                       ; 16FD  FE 20
	jr c,L_170E                   ; 16FF  38 0D
	call L_1736                   ; 1701  CD 36 17
	pop hl                        ; 1704  E1
	pop de                        ; 1705  D1
	inc hl                        ; 1706  23
	call L_1719                   ; 1707  CD 19 17
L_170A:
	pop bc                        ; 170A  C1
	djnz L_16F9                   ; 170B  10 EC
	ret                           ; 170D  C9

L_170E:
	pop hl                        ; 170E  E1
	inc hl                        ; 170F  23
	pop de                        ; 1710  D1
	ld b,a                        ; 1711  47
L_1712:
	call L_1719                   ; 1712  CD 19 17
	djnz L_1712                   ; 1715  10 FB
	jr L_170A                     ; 1717  18 F1

L_1719:
	inc de                        ; 1719  13
	ld a,0x1F                     ; 171A  3E 1F
	cp e                          ; 171C  BB
	ret nc                        ; 171D  D0

	ld e,0x00                     ; 171E  1E 00
	inc d                         ; 1720  14
	ret                           ; 1721  C9

	jr nz,L_1729                  ; 1722  20 05
	ld a,l                        ; 1724  7D
	sub 0x08                      ; 1725  D6 08
	ld l,a                        ; 1727  6F
	inc h                         ; 1728  24
L_1729:
	inc l                         ; 1729  2C
	pop bc                        ; 172A  C1
	dec b                         ; 172B  05
	jp nz,L_1A49                  ; 172C  C2 49 1A  ; в каноне +0x100 этот операнд стухший
	ret                           ; 172F  C9

D_1730:			; данные 1730..1735 (6 байт)
	db	0xC8,0xC1,0xC5,0xAF,0xBB,0xC4	; 1730
L_1736:
	ld hl,HUD_TILES+0x8C          ; 1736  21 E2 9B
	ld bc,0x08                    ; 1739  01 08 00
L_173C:
	dec a                         ; 173C  3D
	jr z,L_1742                   ; 173D  28 03
	add hl,bc                     ; 173F  09
	jr L_173C                     ; 1740  18 FA

L_1742:
	ex de,hl                      ; 1742  EB
	call L_175F                   ; 1743  CD 5F 17
	ld b,0x08                     ; 1746  06 08
L_1748:
	call VDP_RD_BYTE              ; 1748  CD 20 1C
	ld c,a                        ; 174B  4F
	ld a,(de)                     ; 174C  1A
L_174D:
	nop                           ; 174D  00
	call VDP_WR_BYTE              ; 174E  CD 28 1C
	inc l                         ; 1751  2C
	inc de                        ; 1752  13
	djnz L_1748                   ; 1753  10 F3
	nop                           ; 1755  00
	nop                           ; 1756  00
	nop                           ; 1757  00
	nop                           ; 1758  00
	nop                           ; 1759  00
	nop                           ; 175A  00
	nop                           ; 175B  00
	nop                           ; 175C  00
	nop                           ; 175D  00
	nop                           ; 175E  00
L_175F:
	sla l                         ; 175F  CB 25
	sla l                         ; 1761  CB 25
	sla l                         ; 1763  CB 25
	ret                           ; 1765  C9

	rla                           ; 1766  17
	sub h                         ; 1767  94
	ld h,a                        ; 1768  67
	ret                           ; 1769  C9

L_176A:
	ld b,0x0B                     ; 176A  06 0B
	ld a,0x36                     ; 176C  3E 36
	ld hl,PARAM_TABLE_17AA+0x24   ; 176E  21 CE 17
L_1771:
	ld e,(hl)                     ; 1771  5E
	inc hl                        ; 1772  23
	ld d,(hl)                     ; 1773  56
	inc hl                        ; 1774  23
	ld (de),a                     ; 1775  12
	djnz L_1771                   ; 1776  10 F9
	ld b,0x09                     ; 1778  06 09
L_177A:
	ld e,(hl)                     ; 177A  5E
	inc hl                        ; 177B  23
	ld d,(hl)                     ; 177C  56
	inc hl                        ; 177D  23
	ld a,(hl)                     ; 177E  7E
	inc hl                        ; 177F  23
	ld (de),a                     ; 1780  12
	djnz L_177A                   ; 1781  10 F7
	ld de,0x7F9C                  ; 1783  11 9C 7F
	ld bc,0x08                    ; 1786  01 08 00
	ldir                          ; 1789  ED B0
	ld a,r                        ; 178B  ED 5F
	and 0x0F                      ; 178D  E6 0F
	inc a                         ; 178F  3C
	ld hl,PARAM_TABLE_17AA        ; 1790  21 AA 17
L_1793:
	dec a                         ; 1793  3D
	jr z,L_179A                   ; 1794  28 04
	inc hl                        ; 1796  23
	inc hl                        ; 1797  23
	jr L_1793                     ; 1798  18 F9

L_179A:
	ld de,LEVEL_VARS+0x1          ; 179A  11 7C 16
	ld bc,0x06                    ; 179D  01 06 00
	ldir                          ; 17A0  ED B0
	xor a                         ; 17A2  AF
	ld b,0x06                     ; 17A3  06 06
L_17A5:
	ld (de),a                     ; 17A5  12
	inc de                        ; 17A6  13
	djnz L_17A5                   ; 17A7  10 FC
	ret                           ; 17A9  C9

PARAM_TABLE_17AA:			; данные 17AA..1806 (93 байт)
; таблица параметров: живой код ни разу не переходит сюда и не читает
; отсюда по имени; начало повторяет структуру LEVEL_VARS (35 90 1C 80 0F
; 50)
	db	0x09,0x78,0x35,0x90,0x1C,0x80,0x0F,0x50,0x44,0x20,0x12,0x88,0x4D,0x24,0x23,0x3C	; 17AA
	db	0x43,0x60,0x3C,0x90,0x27,0x58,0x48,0x50,0x50,0x28,0x2E,0x50,0x1E,0x98,0x45,0x04	; 17BA
	db	0x1A,0x98,0x53,0x90	; 17CA
	dw	ROOM_MAPS+0x201	; 17CE  48 6A
	dw	ROOM_MAPS+0x597	; 17D0  DE 6D
	dw	ROOM_MAPS+0xA65	; 17D2  AC 72
	dw	ROOM_MAPS+0xD67	; 17D4  AE 75
	dw	ROOM_MAPS+0x2105	; 17D6  4C 89
	dw	ROOM_MAPS+0x1933	; 17D8  7A 81
	dw	ROOM_MAPS+0x1E35	; 17DA  7C 86
	dw	ROOM_MAPS+0x1E39	; 17DC  80 86
	dw	ROOM_MAPS+0x1E3D	; 17DE  84 86
	dw	ROOM_MAPS+0x1F19	; 17E0  60 87
	dw	ROOM_MAPS+0x1F1D	; 17E2  64 87
	dw	ROOM_MAPS+0x180	; 17E4  C7 69
	db	0x23	; 17E6
	dw	ROOM_MAPS+0x7B6	; 17E7  FD 6F
	db	0x2A	; 17E9
	dw	ROOM_MAPS+0x9F8	; 17EA  3F 72
	db	0x24	; 17EC
	dw	ROOM_MAPS+0xC7C	; 17ED  C3 74
	db	0x23	; 17EF
	dw	ROOM_MAPS+0x1992	; 17F0  D9 81
	db	0x18	; 17F2
	dw	ROOM_MAPS+0x19F8	; 17F3  3F 82
	db	0x1A	; 17F5
	dw	ROOM_MAPS+0x1E00	; 17F6  47 86
	db	0x15	; 17F8
	dw	ROOM_MAPS+0x1EBC	; 17F9  03 87
	db	0x23	; 17FB
	dw	ROOM_MAPS+0x2090	; 17FC  D7 88
	db	0x20,0x14,0x40,0x90,0xBD,0x14,0x30,0x90,0xBD	; 17FE
L_1807:
	ld hl,0x20C0                  ; 1807  21 C0 20
	ld de,VRAM_COLOR_ROWS         ; 180A  11 22 9C
	ld c,0x18                     ; 180D  0E 18
L_180F:
	push hl                       ; 180F  E5
	ld b,0x08                     ; 1810  06 08
L_1812:
	push bc                       ; 1812  C5
	ld bc,0x08                    ; 1813  01 08 00
	ld a,(de)                     ; 1816  1A
	call VDP_FILL                 ; 1817  CD 11 1C
	inc de                        ; 181A  13
	ld bc,0x08                    ; 181B  01 08 00
	add hl,bc                     ; 181E  09
	pop bc                        ; 181F  C1
	djnz L_1812                   ; 1820  10 F0
	pop hl                        ; 1822  E1
	inc h                         ; 1823  24
	dec c                         ; 1824  0D
	jr nz,L_180F                  ; 1825  20 E8
	ret                           ; 1827  C9

L_1828:
	rlc c                         ; 1828  CB 01
	rlc c                         ; 182A  CB 01
	rlc c                         ; 182C  CB 01
L_182E:
	push bc                       ; 182E  C5
	push hl                       ; 182F  E5
	ld b,0x00                     ; 1830  06 00
	call VDP_FILL                 ; 1832  CD 11 1C
	pop hl                        ; 1835  E1
	ld bc,0x0100                  ; 1836  01 00 01
	add hl,bc                     ; 1839  09
	pop bc                        ; 183A  C1
	djnz L_182E                   ; 183B  10 F1
	ret                           ; 183D  C9

L_183E:
	call L_18CA                   ; 183E  CD CA 18
	ld hl,0x2900                  ; 1841  21 00 29
	ld bc,0x0100                  ; 1844  01 00 01
	ld a,0xA1                     ; 1847  3E A1
	call VDP_FILL                 ; 1849  CD 11 1C
	inc h                         ; 184C  24
	ld bc,0x0100                  ; 184D  01 00 01
	ld a,0x71                     ; 1850  3E 71
	call VDP_FILL                 ; 1852  CD 11 1C
	inc h                         ; 1855  24
	ld bc,0x0100                  ; 1856  01 00 01
	ld a,0xC1                     ; 1859  3E C1
	call VDP_FILL                 ; 185B  CD 11 1C
	ld a,0xA9                     ; 185E  3E A9
	ld (L_174D),a                 ; 1860  32 4D 17
L_1863:
	ld b,0x06                     ; 1863  06 06
	ld hl,TEXT_ES+0x29            ; 1865  21 09 9A
	ld de,BUF_1890+0x14           ; 1868  11 A4 18
L_186B:
	push bc                       ; 186B  C5
	ld a,(de)                     ; 186C  1A
	ld b,a                        ; 186D  47
	push hl                       ; 186E  E5
	push de                       ; 186F  D5
	ld de,0x1108                  ; 1870  11 08 11
	call L_16F9                   ; 1873  CD F9 16
	call L_1921                   ; 1876  CD 21 19
	pop de                        ; 1879  D1
	pop hl                        ; 187A  E1
	ld a,(de)                     ; 187B  1A
	ld c,a                        ; 187C  4F
	ld b,0x00                     ; 187D  06 00
	add hl,bc                     ; 187F  09
	inc de                        ; 1880  13
	pop bc                        ; 1881  C1
	call L_18AA                   ; 1882  CD AA 18
	jr nz,L_188B                  ; 1885  20 04
	djnz L_186B                   ; 1887  10 E2
	jr L_1863                     ; 1889  18 D8

L_188B:
	xor a                         ; 188B  AF
	ld (L_174D),a                 ; 188C  32 4D 17
	ret                           ; 188F  C9

BUF_1890:			; данные 1890..18A9 (26 байт)
; 20 нулевых байт (буфер) + 6-байтная таблица D0A4..D0A9; процедура
; начинается только с D0AA
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 1890
	db	0x00,0x00,0x00,0x00,0x13,0x1D,0x1C,0x1E,0x18,0x17	; 18A0
L_18AA:
	call L_18AD                   ; 18AA  CD AD 18
L_18AD:
	push bc                       ; 18AD  C5
	push hl                       ; 18AE  E5
	ld h,0x46                     ; 18AF  26 46
L_18B1:
	ld b,0xF0                     ; 18B1  06 F0
L_18B3:
	ld a,b                        ; 18B3  78
	out (0xAA),a                  ; 18B4  D3 AA
	in a,(0xA9)                   ; 18B6  DB A9
	cp 0xFF                       ; 18B8  FE FF
	jr nz,L_18C7                  ; 18BA  20 0B
	inc b                         ; 18BC  04
	ld a,0xF9                     ; 18BD  3E F9
	cp b                          ; 18BF  B8
	jr z,L_18B1                   ; 18C0  28 EF
	dec hl                        ; 18C2  2B
	ld a,h                        ; 18C3  7C
	or l                          ; 18C4  B5
	jr nz,L_18B3                  ; 18C5  20 EC
L_18C7:
	pop hl                        ; 18C7  E1
	pop bc                        ; 18C8  C1
	ret                           ; 18C9  C9

L_18CA:
	ld hl,0x1B00                  ; 18CA  21 00 1B
	ld bc,0x80                    ; 18CD  01 80 00
	ld a,0xD1                     ; 18D0  3E D1
	call VDP_FILL                 ; 18D2  CD 11 1C
	ld bc,0x1800                  ; 18D5  01 00 18
	ld hl,0x00                    ; 18D8  21 00 00
	xor a                         ; 18DB  AF
	call VDP_FILL                 ; 18DC  CD 11 1C
	ld bc,0x1800                  ; 18DF  01 00 18
	ld hl,0x2000                  ; 18E2  21 00 20
	ld a,0x11                     ; 18E5  3E 11
	jp VDP_FILL                   ; 18E7  C3 11 1C

DEAD_18EA:			; данные 18EA..1900 (23 байт)
; мёртвый хвост: его jr/djnz ведут в середину живой процедуры D0CA, а
; команды дословно повторяют её
	db	0xF1,0xD3,0x98,0x78,0xB1,0x20,0xE9,0xDD,0xE1,0x11,0x64,0x00,0xDD,0x19,0xE1,0xC1	; 18EA
	db	0x10,0xD7,0x01,0x00,0x18,0x21,0x00	; 18FA
