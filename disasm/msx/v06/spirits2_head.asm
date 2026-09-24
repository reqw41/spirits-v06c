; Spirits (Topo Soft, 1987), MSX — STAGE2 [РАСКЛАДКА ВЕКТОРА-06Ц, кусок spirits2_head]
; Источник — ref/msx/SPIRITS.2.payload в раскладке ОРИГИНАЛА (канон сдвинут на +0x100).
; Оригинал 82A0..8446  ->  Вектор 02A0..0446 (423 байт)
; Достижимый код 219 байт, остальное — db (графика/таблицы).
;
; Абсолютных адресов 28: символом 28, числом 0. Относительных 6.
; Раскладка и проверки — docs/v06-memory.md, tools/verify_v06.py.
; Адреса в комментариях — уже ВЕКТОРНЫЕ; пояснения к областям данных
; цитируют адреса канона +0x100 (это разбор, а не операнды).
;
; Сгенерировано tools/disasm_msx.py --v06 — правки вносить туда или в tools/entries.json.
; Наложения (цель внутри предыдущей инструкции): 4B12

; Символы вне этого образа: резидентный слой (он копируется в верхнюю RAM
; из SPIRITS.1 — см. docs/msx-vdp-abi.md), копия в page 1, BIOS и цели,
; попавшие внутрь чужой инструкции. equ байтов не порождает — канон не
; трогается, а при смене org правится в одном месте.
BIOS_ENASLT:	equ	0x0024
BIOS_CHGCLR:	equ	0x0072
P1_RESIDENT:	equ	0x5000
P1_STACK_TOP:	equ	0x61A8
P1_HIMEM:	equ	0x6522
L_0489:	equ	0x0489
L_0F2E:	equ	0x0F2E
L_0F4A:	equ	0x0F4A
D_1900:	equ	0x1900
VDP_WR_STRIDE8:	equ	0x1B1D
VDP_RD_STRIDE8:	equ	0x1CB4
D_1D08:	equ	0x1D08
L_1F3F:	equ	0x1F3F
SFX_64D7:	equ	0x1FDA
SFX_64F5:	equ	0x209A
WORK_RAM:	equ	0x3AA8
RG1SAV:	equ	0xF3E0
BDRCLR:	equ	0xF3EB
H_KEYI:	equ	0xFD9F
SSLOT_REG:	equ	0xFFFF

	org	0x02A0

STAGE2:
	ld b,0x80                     ; 02A0  06 80
L_02A2:
	push bc                       ; 02A2  C5
	call H_KEYI                   ; 02A3  CD 9F FD
	pop bc                        ; 02A6  C1
	djnz L_02A2                   ; 02A7  10 F9
	ld a,0xC9                     ; 02A9  3E C9
	ld (H_KEYI),a                 ; 02AB  32 9F FD
	ld hl,RG1SAV                  ; 02AE  21 E0 F3
	set 1,(hl)                    ; 02B1  CB CE
	ld hl,BDRCLR                  ; 02B3  21 EB F3
	ld (hl),0x01                  ; 02B6  36 01
	call BIOS_CHGCLR              ; 02B8  CD 72 00
	in a,(0xA8)                   ; 02BB  DB A8
	and 0xC0                      ; 02BD  E6 C0
	rlca                          ; 02BF  07
	rlca                          ; 02C0  07
	ld b,a                        ; 02C1  47
	ld a,(SSLOT_REG)              ; 02C2  3A FF FF
	cpl                           ; 02C5  2F
	and 0x30                      ; 02C6  E6 30
	rrca                          ; 02C8  0F
	rrca                          ; 02C9  0F
	or b                          ; 02CA  B0
	or 0x80                       ; 02CB  F6 80
	ld h,0x40                     ; 02CD  26 40
	call BIOS_ENASLT              ; 02CF  CD 24 00
	ld sp,P1_STACK_TOP            ; 02D2  31 A8 61
	ld hl,P1_RESIDENT             ; 02D5  21 00 50
	ld de,D_1900                  ; 02D8  11 00 19
	ld bc,0x104B                  ; 02DB  01 4B 10
	ldir                          ; 02DE  ED B0
	ld hl,P1_HIMEM                ; 02E0  21 22 65
	ld bc,0x1ADE                  ; 02E3  01 DE 1A
	ldir                          ; 02E6  ED B0
	jp L_0489                     ; 02E8  C3 89 04

GFX_02EB:			; данные 02EB..0373 (137 байт)
; битовые шаблоны 8x8 (графика). Живой код сюда не обращается: это данные,
; которые резидентный слой гонит в VRAM по указателям из карт комнат
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x07,0x07,0x07,0x1F,0x1F,0x1F	; 02EB
	db	0x10,0x00,0xC0,0xC0,0xC0,0xEF,0xDF,0xDF,0x00,0x00,0x00,0x00,0x00,0x1E,0xBF,0xFF	; 02FB
	db	0x00,0x00,0x00,0x00,0x00,0x3C,0x7E,0xFF,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 030B
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 031B
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1F,0x07,0x07,0x03,0x03,0x01,0x00	; 032B
	db	0x00,0xDF,0xDF,0xEF,0xF0,0xFF,0xFF,0xFF,0x3F,0xBF,0xBF,0x3F,0xBE,0xB8,0xB8,0xB0	; 033B
	db	0xC0,0x7F,0xFF,0x7E,0x3C,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1E,0x20,0x3E,0x02	; 034B
	db	0x3C,0x00,0x00,0x00,0x78,0x85,0x85,0x85,0x79,0x00,0x00,0x00,0xF7,0x01,0xC1,0x01	; 035B
	db	0x01,0x00,0x00,0x00,0xC0,0x00,0x00,0x00,0x00	; 036B
L_0374:
	ld c,0x20                     ; 0374  0E 20
	ld iyh,0x00                   ; 0376  FD 26 00
	push bc                       ; 0379  C5
	call L_1F3F                   ; 037A  CD 3F 1F
	ld (D_1D08+0xC),a             ; 037D  32 14 1D
	push hl                       ; 0380  E5
	ld bc,0x0804                  ; 0381  01 04 08
	ld de,WORK_RAM+0x3E5          ; 0384  11 8D 3E  ; в каноне +0x100 этот операнд стухший
	call VDP_RD_STRIDE8           ; 0387  CD B4 1C
	pop hl                        ; 038A  E1
	ld (L_03B1+0x1),hl            ; 038B  22 B2 03
	ld a,(D_1D08+0xC)             ; 038E  3A 14 1D
	and a                         ; 0391  A7
	jr z,L_0398                   ; 0392  28 04
	ld de,0x0C00                  ; 0394  11 00 0C
	add hl,de                     ; 0397  19
L_0398:
	ld (L_03BD+0x1),hl            ; 0398  22 BE 03
	pop bc                        ; 039B  C1
L_039C:
	push bc                       ; 039C  C5
	ld hl,WORK_RAM+0x3E5          ; 039D  21 8D 3E  ; в каноне +0x100 этот операнд стухший
	ld b,0x08                     ; 03A0  06 08
L_03A2:
	and a                         ; 03A2  A7
	rr (hl)                       ; 03A3  CB 1E
	inc hl                        ; 03A5  23
	rr (hl)                       ; 03A6  CB 1E
	inc hl                        ; 03A8  23
	rr (hl)                       ; 03A9  CB 1E
	inc hl                        ; 03AB  23
	rr (hl)                       ; 03AC  CB 1E
	inc hl                        ; 03AE  23
	djnz L_03A2                   ; 03AF  10 F1
L_03B1:
	ld hl,0x00                    ; 03B1  21 00 00
	ld bc,0x0804                  ; 03B4  01 04 08
	ld de,WORK_RAM+0x3E5          ; 03B7  11 8D 3E  ; в каноне +0x100 этот операнд стухший
	call VDP_WR_STRIDE8           ; 03BA  CD 1D 1B
L_03BD:
	ld hl,0x00                    ; 03BD  21 00 00
	ld bc,0x0804                  ; 03C0  01 04 08
	ld de,WORK_RAM+0x3E5          ; 03C3  11 8D 3E  ; в каноне +0x100 этот операнд стухший
	call VDP_WR_STRIDE8           ; 03C6  CD 1D 1B
	call SFX_64D7                 ; 03C9  CD DA 1F
	pop bc                        ; 03CC  C1
	dec c                         ; 03CD  0D
	jr nz,L_039C                  ; 03CE  20 CC
	call SFX_64F5                 ; 03D0  CD 9A 20
	call L_0F4A                   ; 03D3  CD 4A 0F
	jp L_0F2E                     ; 03D6  C3 2E 0F

D_03D9:			; данные 03D9..03E9 (17 байт)
	db	0xED,0x52,0x19,0x28,0x13,0xCD,0x41,0x9C,0x2B,0x7E,0xFE,0x20,0xDC,0x41,0x9C,0x04	; 03D9
	db	0xC9	; 03E9
	ld (hl),a                     ; 03EA  77
	ld a,b                        ; 03EB  78
	or a                          ; 03EC  B7
	ret z                         ; 03ED  C8

	dec b                         ; 03EE  05
	ret z                         ; 03EF  C8

	inc hl                        ; 03F0  23
	or a                          ; 03F1  B7
	ret                           ; 03F2  C9

D_03F3:			; данные 03F3..03F4 (2 байт)
	db	0xCD,0x02	; 03F3
L_03F5:
	ld b,(hl)                     ; 03F5  46
	inc hl                        ; 03F6  23
L_03F7:
	push bc                       ; 03F7  C5
	ld a,(hl)                     ; 03F8  7E
	inc hl                        ; 03F9  23
	ld c,(hl)                     ; 03FA  4E
	inc hl                        ; 03FB  23
	out (0xA0),a                  ; 03FC  D3 A0
	ld a,c                        ; 03FE  79
	out (0xA1),a                  ; 03FF  D3 A1
	pop bc                        ; 0401  C1
	djnz L_03F7                   ; 0402  10 F3
	ret                           ; 0404  C9

	or a                          ; 0405  B7
	sbc hl,de                     ; 0406  ED 52
	add hl,de                     ; 0408  19
	jr nc,L_0413                  ; 0409  30 08
	add hl,bc                     ; 040B  09
	ex de,hl                      ; 040C  EB
	add hl,bc                     ; 040D  09
	ex de,hl                      ; 040E  EB
	inc bc                        ; 040F  03
	lddr                          ; 0410  ED B8
	ret                           ; 0412  C9

L_0413:
	inc bc                        ; 0413  03
	ldir                          ; 0414  ED B0
	ret                           ; 0416  C9

D_0417:			; данные 0417..0446 (48 байт)
	db	0xE5,0x21,0x00,0x17,0xE5,0xCD,0x26,0x9C,0xE1,0xC5,0xF5,0xCD,0x53,0x9C,0xF1,0xC1	; 0417
	db	0xCD,0x26,0x9C,0xE1,0xC9,0x3E,0x1B,0xCD,0x89,0x88,0x3E,0x59,0xCD,0x89,0x88,0x7C	; 0427
	db	0xC6,0x20,0xCD,0x89,0x88,0x7D,0xC6,0x20,0xC3,0x89,0x88,0xF5,0x3E,0x0C,0x18,0x00	; 0437
