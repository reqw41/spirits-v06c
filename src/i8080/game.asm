; СГЕНЕРИРОВАНО tools/recompile_i8080.py — правки вносить ТУДА.
; Код игры Spirits, перекомпилированный Z80 -> i8080 (Вектор-06Ц, ВМ80А).
; Эталон — disasm/msx/v06/*.asm (раскладка Вектора, гейт tools/verify_v06.py).
; Метод, врезки, гейты и такты — docs/recompilation.md.


BDRCLR:	equ	0xF3EB
BIOS_CHGCLR:	equ	0x0072
BIOS_ENASLT:	equ	0x0024
GFX_9940:	equ	0x9940
HUD_TILES:	equ	0x9B56
H_KEYI:	equ	0xFD9F
LOW_TILE_SRC:	equ	0x01F4
OBJ_TABLE_9AA2:	equ	0x9AA2
P1_HIMEM:	equ	0x6522
P1_RESIDENT:	equ	0x5000
P1_SFX_64AA:	equ	0x4EAA
P1_SFX_64B9:	equ	0x4EB9
P1_SFX_64C8:	equ	0x4EC8
P1_SFX_64D7:	equ	0x4ED7
P1_SFX_64E6:	equ	0x4EE6
P1_SFX_64F5:	equ	0x4EF5
P1_STACK_TOP:	equ	0x61A8
RG1SAV:	equ	0xF3E0
ROOM_MAPS:	equ	0x6847
SPR_BANK_294B:	equ	0x294B
SPR_DATA_8B9C:	equ	0x8B9C
SPR_DATA_8E76:	equ	0x8E76
SSLOT_REG:	equ	0xFFFF
TEXT_ES:	equ	0x99E0
TEXT_SHORT:	equ	0x9BF9
VRAM_COLOR_ROWS:	equ	0x9C22
WORK_RAM:	equ	0x3AA8
RT_VARS:	equ	0x4FD8	; ячейки рантайма (дырка 4FD8..4FFF)
z80_ix:	equ	RT_VARS+0
z80_iy:	equ	RT_VARS+2
il_tmp:	equ	RT_VARS+4
il_tmp2:	equ	RT_VARS+6
il_f:	equ	RT_VARS+8
z80_af_alt:	equ	RT_VARS+10
il_a:	equ	RT_VARS+12
il_d:	equ	RT_VARS+13
z80_r:	equ	RT_VARS+14
RT_VARS_END:	equ	RT_VARS+15

	org	0x0107
il_pro1:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl       ; AF вызывателя: h = a, l = флаги
	                pop     hl
	                ld      (il_tmp),hl     ; возврат в обёртку
	                pop     hl              ; возврат в тело хелпера
	                ex      (sp),hl         ; на стеке возврат в тело, hl -> inline-байт
	                ld      a,(hl)
	                inc     hl
	                ex      (sp),hl
	                push    hl
	                ld      hl,(il_tmp)
	                push    hl
	                ret
il_pro2:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl
	                pop     hl
	                ld      (il_tmp),hl
	                pop     hl
	                ex      (sp),hl
	                ld      a,(hl)
	                ld      (il_a),a        ; смещение
	                inc     hl
	                ld      a,(hl)
	                ld      (il_d),a        ; маска/значение
	                inc     hl
	                ex      (sp),hl
	                push    hl
	                ld      hl,(il_tmp)
	                push    hl
	                ld      a,(il_a)
	                ret
il_pro_ix:
	                call    il_pro1
	                ld      hl,(z80_ix)
	                jp      il_adr
il_pro2_ix:
	                call    il_pro2
	                ld      hl,(z80_ix)
	                jp      il_adr
il_pro_iy:
	                call    il_pro1
	                ld      hl,(z80_iy)
	                jp      il_adr
il_pro2_iy:
	                call    il_pro2
	                ld      hl,(z80_iy)
	                jp      il_adr
il_adr:
	                ld      (il_a),a
	                add     a,a             ; CY = знак смещения
	                ld      a,(il_a)
	                jp      c,il_adrn
	                add     a,l
	                ld      l,a
	                ret     nc
	                inc     h
	                ret
il_adrn:
	                add     a,l
	                ld      l,a
	                ret     c
	                dec     h
	                ret
il_ret_hl:
	                ld      hl,(il_tmp2)
	                ret
il_epi:
	                ld      hl,(il_f)
	                push    hl
	                pop     af
	                jp      il_ret_hl
il_epi_a:
	                ld      hl,(il_f)
	                push    hl
	                pop     af
	                ld      a,(il_a)
	                jp      il_ret_hl
il_ix_lda:
	                call    il_pro_ix
	                ld a,(hl)
	                ld (il_a),a
	                jp il_epi_a
il_ix_ldb:
	                call    il_pro_ix
	                ld b,(hl)
	                jp il_epi
il_ix_ldd:
	                call    il_pro_ix
	                ld d,(hl)
	                jp il_epi
il_ix_lde:
	                call    il_pro_ix
	                ld e,(hl)
	                jp il_epi
il_ix_or:
	                call    il_pro_ix
	                ld a,(il_f+1)
	                or (hl)
	                jp il_ret_hl
il_ix_sta:
	                call    il_pro_ix
	                ld a,(il_f+1)
	                ld (hl),a
	                jp il_epi
il_ix_std:
	                call    il_pro_ix
	                ld (hl),d
	                jp il_epi
il_ix_ste:
	                call    il_pro_ix
	                ld (hl),e
	                jp il_epi
il_ix_stn:
	                call    il_pro2_ix
	                ld a,(il_d)
	                ld (hl),a
	                jp il_epi
il_iy_cp:
	                call    il_pro_iy
	                ld a,(il_f+1)
	                cp (hl)
	                jp il_ret_hl
il_iy_dec:
	                call    il_pro_iy
	                dec (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_iy_inc:
	                call    il_pro_iy
	                inc (hl)
	                ld a,(il_f+1)
	                jp il_ret_hl
il_iy_lda:
	                call    il_pro_iy
	                ld a,(hl)
	                ld (il_a),a
	                jp il_epi_a
il_iy_ldb:
	                call    il_pro_iy
	                ld b,(hl)
	                jp il_epi
il_iy_ldc:
	                call    il_pro_iy
	                ld c,(hl)
	                jp il_epi
il_iy_ldd:
	                call    il_pro_iy
	                ld d,(hl)
	                jp il_epi
il_iy_lde:
	                call    il_pro_iy
	                ld e,(hl)
	                jp il_epi
il_iy_ldh:
	                call    il_pro_iy
	                ld a,(hl)
	                ld (il_tmp2+1),a
	                jp il_epi
il_iy_ldl:
	                call    il_pro_iy
	                ld a,(hl)
	                ld (il_tmp2),a
	                jp il_epi
il_iy_or:
	                call    il_pro_iy
	                ld a,(il_f+1)
	                or (hl)
	                jp il_ret_hl
il_iy_sta:
	                call    il_pro_iy
	                ld a,(il_f+1)
	                ld (hl),a
	                jp il_epi
il_iy_stb:
	                call    il_pro_iy
	                ld (hl),b
	                jp il_epi
il_iy_stc:
	                call    il_pro_iy
	                ld (hl),c
	                jp il_epi
il_iy_std:
	                call    il_pro_iy
	                ld (hl),d
	                jp il_epi
il_iy_sth:
	                call    il_pro_iy
	                ld a,(il_tmp2+1)
	                ld (hl),a
	                jp il_epi
il_iy_stl:
	                call    il_pro_iy
	                ld a,(il_tmp2)
	                ld (hl),a
	                jp il_epi
il_iy_stn:
	                call    il_pro2_iy
	                ld a,(il_d)
	                ld (hl),a
	                jp il_epi
il_rnd:
	                ld      a,(z80_r)       ; у i8080 регистра R нет; ряд ведёт
	                add     a,0x9D          ; эта ячейка: +0x9D на чтение,
	                ld      (z80_r),a       ; +1 на кадр (V_ISR связки)
	                ret
il_ldir:
	                push    af              ; Z80 ldir не трогает ни A, ни CY
il_ldir_l:
	                ld      a,(hl)
	                ld      (de),a
	                inc     hl
	                inc     de
	                dec     bc              ; DCX у i8080 ФЛАГОВ НЕ СТАВИТ
	                ld      a,b
	                or      c
	                jp      nz,il_ldir_l
	                pop     af
	                ret
il_lddr:
	                push    af
il_lddr_l:
	                ld      a,(hl)
	                ld      (de),a
	                dec     hl
	                dec     de
	                dec     bc
	                ld      a,b
	                or      c
	                jp      nz,il_lddr_l
	                pop     af
	                ret
	jp	il_exaf	; мост в следующий кусок
	org	0x02A0
	jp	il_exaf	; мост в следующий кусок
	org	0x02AC
Z_02AC:
	db	0x9F,0xFD,0x21,0xE0,0xF3,0xCB,0xCE,0x21	; ПРИКОЛОЧЕНО: глиф логотипа 02AC
	org	0x02B4
il_exaf:
	                ld      (il_tmp2),hl
	                push    af
	                pop     hl
	                ld      (il_f),hl
	                ld      hl,(z80_af_alt)
	                push    hl
	                pop     af
	                ld      hl,(il_f)
	                ld      (z80_af_alt),hl
	                ld      hl,(il_tmp2)
	                ret
L_0374:
Z_0374:
	ld c,0x20	; 0374  0E 20
Z_0376:
	push af	; 0376  FD 26 00
	ld a,0x00
	ld (z80_iy+1),a
	pop af
Z_0379:
	push bc	; 0379  C5
Z_037A:
	call L_1F3F	; 037A  CD 3F 1F
Z_037D:
	ld (D_1D08+0xC),a	; 037D  32 14 1D
Z_0380:
	push hl	; 0380  E5
Z_0381:
	ld bc,0x0804	; 0381  01 04 08
Z_0384:
	ld de,WORK_RAM+0x3E5	; 0384  11 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_0387:
	call VDP_RD_STRIDE8	; 0387  CD B4 1C
Z_038A:
	pop hl	; 038A  E1
	jp	Z_038B	; мост в следующий кусок
	org	0x02EB
Z_02EB:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x07,0x07,0x07,0x1F,0x1F,0x1F	; ПРИКОЛОЧЕНО: глиф логотипа 02EB
	db	0x10,0x00,0xC0,0xC0,0xC0,0xEF,0xDF,0xDF,0x00,0x00,0x00,0x00,0x00,0x1E,0xBF,0xFF
	db	0x00,0x00,0x00,0x00,0x00,0x3C,0x7E,0xFF,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1F,0x07,0x07,0x03,0x03,0x01,0x00
	db	0x00,0xDF,0xDF,0xEF,0xF0,0xFF,0xFF,0xFF,0x3F,0xBF,0xBF,0x3F,0xBE,0xB8,0xB8,0xB0
	db	0xC0,0x7F,0xFF,0x7E,0x3C,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1E,0x20,0x3E,0x02
	db	0x3C,0x00,0x00,0x00,0x78,0x85,0x85,0x85,0x79,0x00,0x00,0x00,0xF7,0x01,0xC1,0x01
	db	0x01,0x00,0x00,0x00,0xC0,0x00,0x00,0x00,0x00
	org	0x0374
Z_038B:
	ld (L_03B1+0x1),hl	; 038B  22 B2 03
Z_038E:
	ld a,(D_1D08+0xC)	; 038E  3A 14 1D
Z_0391:
	and a	; 0391  A7
Z_0392:
	jp z,L_0398	; 0392  28 04
Z_0394:
	ld de,0x0C00	; 0394  11 00 0C
Z_0397:
	add hl,de	; 0397  19
L_0398:
Z_0398:
	ld (L_03BD+0x1),hl	; 0398  22 BE 03
Z_039B:
	pop bc	; 039B  C1
L_039C:
Z_039C:
	push bc	; 039C  C5
Z_039D:
	ld hl,WORK_RAM+0x3E5	; 039D  21 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_03A0:
	ld b,0x08	; 03A0  06 08
L_03A2:
Z_03A2:
	and a	; 03A2  A7
Z_03A3:
	ld (il_a),a	; 03A3  CB 1E
	ld a,(hl)
	rra
	ld (hl),a
	ld a,(il_a)
Z_03A5:
	inc hl	; 03A5  23
Z_03A6:
	ld (il_a),a	; 03A6  CB 1E
	ld a,(hl)
	rra
	ld (hl),a
	ld a,(il_a)
Z_03A8:
	inc hl	; 03A8  23
Z_03A9:
	ld (il_a),a	; 03A9  CB 1E
	ld a,(hl)
	rra
	ld (hl),a
	ld a,(il_a)
Z_03AB:
	inc hl	; 03AB  23
Z_03AC:
	ld (il_a),a	; 03AC  CB 1E
	ld a,(hl)
	rra
	or a
	ld (hl),a
	ld a,(il_a)
Z_03AE:
	inc hl	; 03AE  23
Z_03AF:
	dec b	; 03AF  10 F1
	jp nz,L_03A2
L_03B1:
Z_03B1:
	ld hl,0x00	; 03B1  21 00 00
Z_03B4:
	ld bc,0x0804	; 03B4  01 04 08
	jp	Z_03B7	; мост в следующий кусок
	org	0x03C4
Z_03C4:
	db	0x8D,0x3E,0xCD,0x1D,0x1B,0xCD,0xDA,0x1F	; ПРИКОЛОЧЕНО: глиф логотипа 03C4
	org	0x03CC
Z_03B7:
	ld de,WORK_RAM+0x3E5	; 03B7  11 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_03BA:
	call VDP_WR_STRIDE8	; 03BA  CD 1D 1B
L_03BD:
Z_03BD:
	ld hl,0x00	; 03BD  21 00 00
Z_03C0:
	ld bc,0x0804	; 03C0  01 04 08
Z_03C3:
	ld de,WORK_RAM+0x3E5	; 03C3  11 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_03C6:
	call VDP_WR_STRIDE8	; 03C6  CD 1D 1B
Z_03C9:
	call SFX_64D7	; 03C9  CD DA 1F
Z_03CC:
	pop bc	; 03CC  C1
Z_03CD:
	dec c	; 03CD  0D
Z_03CE:
	jp nz,L_039C	; 03CE  20 CC
Z_03D0:
	call SFX_64F5	; 03D0  CD 9A 20
Z_03D3:
	call L_0F4A	; 03D3  CD 4A 0F
Z_03D6:
	jp L_0F2E	; 03D6  C3 2E 0F
	org	0x03F4
Z_03F4:
	db	0x02,0x46,0x23,0xC5,0x7E,0x23,0x4E,0x23,0xD3,0xA0,0x79,0xD3,0xA1,0xC1,0x10,0xF3	; ПРИКОЛОЧЕНО: глиф логотипа 03F4
	db	0xC9,0xB7,0xED,0x52,0x19,0x30,0x08,0x09
	org	0x040C
D_03D9:
Z_03D9:
	db	0xED,0x52,0x19,0x28,0x13,0xCD,0x41,0x9C,0x2B,0x7E,0xFE,0x20,0xDC,0x41,0x9C,0x04	; 03D9
Z_03E9:
	db	0xC9	; 03E9
Z_03EA:
	ld (hl),a	; 03EA  77
Z_03EB:
	ld a,b	; 03EB  78
Z_03EC:
	or a	; 03EC  B7
Z_03ED:
	ret z	; 03ED  C8
Z_03EE:
	dec b	; 03EE  05
Z_03EF:
	ret z	; 03EF  C8
Z_03F0:
	inc hl	; 03F0  23
Z_03F1:
	or a	; 03F1  B7
Z_03F2:
	ret	; 03F2  C9
D_03F3:
Z_03F3:
	db	0xCD,0x02	; 03F3
L_03F5:
Z_03F5:
	ld b,(hl)	; 03F5  46
Z_03F6:
	inc hl	; 03F6  23
L_03F7:
Z_03F7:
	push bc	; 03F7  C5
Z_03F8:
	ld a,(hl)	; 03F8  7E
Z_03F9:
	inc hl	; 03F9  23
Z_03FA:
	ld c,(hl)	; 03FA  4E
Z_03FB:
	inc hl	; 03FB  23
Z_03FC:
	out (0xA0),a	; 03FC  D3 A0
Z_03FE:
	ld a,c	; 03FE  79
Z_03FF:
	out (0xA1),a	; 03FF  D3 A1
Z_0401:
	pop bc	; 0401  C1
Z_0402:
	dec b	; 0402  10 F3
	jp nz,L_03F7
Z_0404:
	ret	; 0404  C9
Z_0405:
	or a	; 0405  B7
Z_0406:
	ld a,l	; 0406  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
Z_0408:
	add hl,de	; 0408  19
Z_0409:
	jp nc,L_0413	; 0409  30 08
Z_040B:
	add hl,bc	; 040B  09
Z_040C:
	ex de,hl	; 040C  EB
Z_040D:
	add hl,bc	; 040D  09
Z_040E:
	ex de,hl	; 040E  EB
Z_040F:
	inc bc	; 040F  03
Z_0410:
	call il_lddr	; 0410  ED B8
Z_0412:
	ret	; 0412  C9
L_0413:
Z_0413:
	inc bc	; 0413  03
Z_0414:
	call il_ldir	; 0414  ED B0
Z_0416:
	ret	; 0416  C9
D_0417:
Z_0417:
	db	0xE5,0x21,0x00,0x17,0xE5,0xCD,0x26,0x9C,0xE1,0xC5,0xF5,0xCD,0x53,0x9C,0xF1,0xC1	; 0417
Z_0427:
	db	0xCD,0x26,0x9C,0xE1,0xC9,0x3E,0x1B,0xCD,0x89,0x88,0x3E,0x59,0xCD,0x89,0x88,0x7C	; 0427
Z_0437:
	db	0xC6,0x20,0xCD,0x89,0x88,0x7D,0xC6,0x20,0xC3,0x89,0x88,0xF5,0x3E,0x0C,0x18,0x00	; 0437
L_0489:
Z_0489:
	call L_183E	; 0489  CD 3E 18
	jp	Z_048C	; мост в следующий кусок
	org	0x0489
Z_048C:
	call L_133D	; 048C  CD 3D 13
L_048F:
Z_048F:
	call L_0834	; 048F  CD 34 08
Z_0492:
	ld a,(D_04D4)	; 0492  3A D4 04
Z_0495:
	or a	; 0495  B7
Z_0496:
	jp nz,L_05F6	; 0496  C2 F6 05
Z_0499:
	ld a,(L_0837+0x1)	; 0499  3A 38 08
Z_049C:
	cp 0x01	; 049C  FE 01
Z_049E:
	jp z,L_04A5	; 049E  28 05
Z_04A0:
	call KBD_CHK_F3B5	; 04A0  CD 84 1F
Z_04A3:
	jp L_048F	; 04A3  18 EA
L_04A5:
Z_04A5:
	call L_137B	; 04A5  CD 7B 13
Z_04A8:
	ld a,(GAME_VARS+0x8)	; 04A8  3A F2 0A
Z_04AB:
	or a	; 04AB  B7
Z_04AC:
	jp z,L_04CC	; 04AC  28 1E
Z_04AE:
	call L_130C	; 04AE  CD 0C 13
Z_04B1:
	ld hl,GAME_VARS+0x10	; 04B1  21 FA 0A
Z_04B4:
	ld de,GAME_VARS+0xA	; 04B4  11 F4 0A
Z_04B7:
	ld bc,0x05	; 04B7  01 05 00
Z_04BA:
	call il_ldir	; 04BA  ED B0
Z_04BC:
	call L_0C8C	; 04BC  CD 8C 0C
Z_04BF:
	ld a,0x01	; 04BF  3E 01
Z_04C1:
	call L_0D64	; 04C1  CD 64 0D
Z_04C4:
	ld (L_0837+0x1),a	; 04C4  32 38 08
Z_04C7:
	call L_0ADC	; 04C7  CD DC 0A
Z_04CA:
	jp L_048F	; 04CA  18 C3
L_04CC:
Z_04CC:
	call L_150D	; 04CC  CD 0D 15
Z_04CF:
	call L_18AA	; 04CF  CD AA 18
Z_04D2:
	jp L_0489	; 04D2  18 B5
D_04D4:
Z_04D4:
	db	0x00	; 04D4
L_04D5:
Z_04D5:
	ld (il_tmp),hl	; 04D5  FD 21 C3 05
	ld hl,D_05BA+0x9
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_04D9:
	ld b,0x06	; 04D9  06 06
L_04DB:
Z_04DB:
	push bc	; 04DB  C5
Z_04DC:
	ld a,(GAME_VARS+0xC)	; 04DC  3A F6 0A
Z_04DF:
	ld (il_tmp2),hl	; 04DF  FD BE 00
	ld hl,(z80_iy)
	cp (hl)
	ld hl,(il_tmp2)
Z_04E2:
	jp nz,L_04F0	; 04E2  20 0C
Z_04E4:
	call il_iy_dec	; 04E4  FD 35 03
	db 0x03
Z_04E7:
	call z,L_0525	; 04E7  CC 25 05
Z_04EA:
	xor a	; 04EA  AF
Z_04EB:
	call L_0518	; 04EB  CD 18 05
Z_04EE:
	jp L_050F	; 04EE  18 1F
L_04F0:
Z_04F0:
	ld a,(LEVEL_VARS)	; 04F0  3A 7B 16
Z_04F3:
	ld (il_tmp2),hl	; 04F3  FD BE 00
	ld hl,(z80_iy)
	cp (hl)
	ld hl,(il_tmp2)
Z_04F6:
	jp nz,L_04FF	; 04F6  20 07
Z_04F8:
	ld a,0x60	; 04F8  3E 60
Z_04FA:
	call L_0518	; 04FA  CD 18 05
Z_04FD:
	jp L_050F	; 04FD  18 10
L_04FF:
Z_04FF:
	ld (il_tmp2),hl	; 04FF  FD 7E 04
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
Z_0502:
	ld (il_tmp2),hl	; 0502  FD BE 02
	ld hl,(z80_iy)
	inc hl
	inc hl
	cp (hl)
	ld hl,(il_tmp2)
Z_0505:
	jp z,L_050F	; 0505  28 08
Z_0507:
	call il_iy_sta	; 0507  FD 77 02
	db 0x02
Z_050A:
	call il_rnd	; 050A  ED 5F
Z_050C:
	call il_iy_sta	; 050C  FD 77 03
	db 0x03
L_050F:
Z_050F:
	ld bc,0x05	; 050F  01 05 00
Z_0512:
	ld (il_tmp),hl	; 0512  FD 09
	ld hl,(z80_iy)
	add hl,bc
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_0514:
	pop bc	; 0514  C1
Z_0515:
	dec b	; 0515  10 C4
	jp nz,L_04DB
Z_0517:
	ret	; 0517  C9
L_0518:
Z_0518:
	call il_iy_ldb	; 0518  FD 46 01
	db 0x01
Z_051B:
	call il_iy_ldc	; 051B  FD 4E 02
	db 0x02
Z_051E:
	add a,c	; 051E  81
Z_051F:
	ld c,a	; 051F  4F
Z_0520:
	ld a,0x1E	; 0520  3E 1E
Z_0522:
	jp L_19A0	; 0522  C3 A0 19
L_0525:
Z_0525:
	call il_iy_lda	; 0525  FD 7E 02
	db 0x02
Z_0528:
	ld c,a	; 0528  4F
Z_0529:
	call il_exaf	; 0529  08
Z_052A:
	call il_iy_ldb	; 052A  FD 46 01
	db 0x01
Z_052D:
	ld d,0x40	; 052D  16 40
Z_052F:
	push bc	; 052F  C5
Z_0530:
	call L_0BD6	; 0530  CD D6 0B
Z_0533:
	pop bc	; 0533  C1
Z_0534:
	jp nc,L_0549	; 0534  30 13
Z_0536:
	call il_iy_inc	; 0536  FD 34 03
	db 0x03
Z_0539:
	call il_exaf	; 0539  08
Z_053A:
	add a,0x04	; 053A  C6 04
Z_053C:
	call il_iy_sta	; 053C  FD 77 02
	db 0x02
Z_053F:
	ld c,a	; 053F  4F
Z_0540:
	call L_11F2	; 0540  CD F2 11
Z_0543:
	xor a	; 0543  AF
Z_0544:
	cp e	; 0544  BB
Z_0545:
	ret z	; 0545  C8
Z_0546:
	jp L_0F25	; 0546  C3 25 0F
L_0549:
Z_0549:
	call il_exaf	; 0549  08
Z_054A:
	sub 0x24	; 054A  D6 24
Z_054C:
	ld c,a	; 054C  4F
Z_054D:
	call il_iy_ldb	; 054D  FD 46 01
	db 0x01
Z_0550:
	call SCR_ADDR_BIT13	; 0550  CD 92 19
Z_0553:
	ld a,0xED	; 0553  3E ED
Z_0555:
	jp L_1AC2	; 0555  C3 C2 1A
L_0558:
Z_0558:
	ld (il_tmp),hl	; 0558  FD 21 BA 05
	ld hl,D_05BA
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_055C:
	ld b,0x03	; 055C  06 03
L_055E:
Z_055E:
	push bc	; 055E  C5
Z_055F:
	ld a,(GAME_VARS+0xC)	; 055F  3A F6 0A
Z_0562:
	ld (il_tmp2),hl	; 0562  FD BE 00
	ld hl,(z80_iy)
	cp (hl)
	ld hl,(il_tmp2)
Z_0565:
	jp nz,L_0570	; 0565  20 09
Z_0567:
	xor a	; 0567  AF
Z_0568:
	call L_0586	; 0568  CD 86 05
Z_056B:
	call L_05E1	; 056B  CD E1 05
Z_056E:
	jp L_057D	; 056E  18 0D
L_0570:
Z_0570:
	ld a,(LEVEL_VARS)	; 0570  3A 7B 16
Z_0573:
	ld (il_tmp2),hl	; 0573  FD BE 00
	ld hl,(z80_iy)
	cp (hl)
	ld hl,(il_tmp2)
Z_0576:
	jp nz,L_057D	; 0576  20 05
Z_0578:
	ld a,0x60	; 0578  3E 60
Z_057A:
	call L_0586	; 057A  CD 86 05
L_057D:
Z_057D:
	ld bc,0x03	; 057D  01 03 00
Z_0580:
	ld (il_tmp),hl	; 0580  FD 09
	ld hl,(z80_iy)
	add hl,bc
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_0582:
	pop bc	; 0582  C1
Z_0583:
	dec b	; 0583  10 D9
	jp nz,L_055E
Z_0585:
	ret	; 0585  C9
L_0586:
Z_0586:
	call il_iy_ldb	; 0586  FD 46 01
	db 0x01
Z_0589:
	ld c,0x58	; 0589  0E 58
Z_058B:
	add a,c	; 058B  81
Z_058C:
	ld c,a	; 058C  4F
Z_058D:
	push bc	; 058D  C5
Z_058E:
	call il_iy_lda	; 058E  FD 7E 02
	db 0x02
Z_0591:
	xor 0x01	; 0591  EE 01
Z_0593:
	call il_iy_sta	; 0593  FD 77 02
	db 0x02
Z_0596:
	add a,0x24	; 0596  C6 24
Z_0598:
	call L_19A0	; 0598  CD A0 19
Z_059B:
	pop bc	; 059B  C1
Z_059C:
	call SCR_ADDR_BIT13	; 059C  CD 92 19
Z_059F:
	ld bc,0xFFD0	; 059F  01 D0 FF
Z_05A2:
	add hl,bc	; 05A2  09
Z_05A3:
	ld b,0x04	; 05A3  06 04
L_05A5:
Z_05A5:
	ld (hl),0x02	; 05A5  36 02
Z_05A7:
	inc hl	; 05A7  23
Z_05A8:
	dec b	; 05A8  10 FB
	jp nz,L_05A5
Z_05AA:
	ld bc,0x14	; 05AA  01 14 00
Z_05AD:
	add hl,bc	; 05AD  09
Z_05AE:
	ld (hl),0x02	; 05AE  36 02
Z_05B0:
	inc hl	; 05B0  23
Z_05B1:
	ld (hl),0x16	; 05B1  36 16
Z_05B3:
	inc hl	; 05B3  23
Z_05B4:
	ld (hl),0x16	; 05B4  36 16
Z_05B6:
	inc hl	; 05B6  23
Z_05B7:
	ld (hl),0x02	; 05B7  36 02
Z_05B9:
	ret	; 05B9  C9
D_05BA:
Z_05BA:
	db	0x27,0x98,0x00,0x51,0x18,0x01,0x53,0x50,0x00,0x0C,0x40,0x28,0x36,0x28,0x19,0x60	; 05BA
Z_05CA:
	db	0x20,0x1C,0x20,0x2D,0x50,0x20,0x35,0x20,0x30,0x40,0x28,0x4E,0x28,0x3F,0x38,0x20	; 05CA
Z_05DA:
	db	0x67,0x20,0x17,0x38,0x28,0x1B,0x28	; 05DA
L_05E1:
Z_05E1:
	call il_iy_lda	; 05E1  FD 7E 01
	db 0x01
Z_05E4:
	ld hl,(GAME_VARS+0xA)	; 05E4  2A F4 0A
Z_05E7:
	add a,0x1C	; 05E7  C6 1C
Z_05E9:
	cp h	; 05E9  BC
Z_05EA:
	ret c	; 05EA  D8
Z_05EB:
	sub 0x28	; 05EB  D6 28
Z_05ED:
	cp h	; 05ED  BC
Z_05EE:
	ret nc	; 05EE  D0
Z_05EF:
	ld a,0x28	; 05EF  3E 28
Z_05F1:
	cp l	; 05F1  BD
Z_05F2:
	ret nc	; 05F2  D0
L_05F3:
Z_05F3:
	jp L_122C	; 05F3  C3 2C 12
L_05F6:
Z_05F6:
	call L_18AA	; 05F6  CD AA 18
Z_05F9:
	call L_19F2	; 05F9  CD F2 19
Z_05FC:
	ld a,0xC9	; 05FC  3E C9
Z_05FE:
	ld (L_228E),a	; 05FE  32 8E 22
Z_0601:
	call L_0F47	; 0601  CD 47 0F
Z_0604:
	call L_0F2B	; 0604  CD 2B 0F
Z_0607:
	push hl	; 0607  ED 4B F4 0A
	ld hl,(GAME_VARS+0xA)
	ld b,h
	ld c,l
	pop hl
Z_060B:
	ld a,0x0C	; 060B  3E 0C
Z_060D:
	push bc	; 060D  C5
Z_060E:
	call L_19A0	; 060E  CD A0 19
Z_0611:
	pop bc	; 0611  C1
Z_0612:
	ld a,c	; 0612  79
Z_0613:
	add a,0x60	; 0613  C6 60
Z_0615:
	ld c,a	; 0615  4F
Z_0616:
	ld a,0x0B	; 0616  3E 0B
Z_0618:
	call L_19A0	; 0618  CD A0 19
Z_061B:
	call L_1A24	; 061B  CD 24 1A
Z_061E:
	ld hl,0x2A	; 061E  21 2A 00
Z_0621:
	ld (L_228E),a	; 0621  32 8E 22
Z_0624:
	call MUS_TRACK_2	; 0624  CD 19 29
Z_0627:
	call L_18AA	; 0627  CD AA 18
Z_062A:
	jp L_0489	; 062A  C3 89 04
DEAD_062D:
Z_062D:
	db	0xCD,0xA0,0xD0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xCD,0xF8,0xD3,0xCD	; 062D
Z_063D:
	db	0xAA,0xCF,0xC3,0x89,0xBB	; 063D
L_0642:
Z_0642:
	ld a,(OBJ_BLOCK_0809)	; 0642  3A 09 08
Z_0645:
	cp 0x01	; 0645  FE 01
Z_0647:
	ret nz	; 0647  C0
Z_0648:
	ld a,(OBJ_BLOCK_0809+0x5)	; 0648  3A 0E 08
Z_064B:
	sub 0x18	; 064B  D6 18
Z_064D:
	call il_iy_cp	; 064D  FD BE 01
	db 0x01
Z_0650:
	ret nc	; 0650  D0
Z_0651:
	add a,0x20	; 0651  C6 20
Z_0653:
	call il_iy_cp	; 0653  FD BE 01
	db 0x01
Z_0656:
	ret c	; 0656  D8
Z_0657:
	ld a,(OBJ_BLOCK_0809+0x4)	; 0657  3A 0D 08
Z_065A:
	sub 0x08	; 065A  D6 08
Z_065C:
	call il_iy_cp	; 065C  FD BE 00
	db 0x00
Z_065F:
	ret nc	; 065F  D0
Z_0660:
	add a,0x30	; 0660  C6 30
Z_0662:
	call il_iy_cp	; 0662  FD BE 00
	db 0x00
Z_0665:
	ret c	; 0665  D8
Z_0666:
	call il_iy_lda	; 0666  FD 7E 04
	db 0x04
Z_0669:
	add a,0x32	; 0669  C6 32
Z_066B:
	call il_iy_sta	; 066B  FD 77 04
	db 0x04
Z_066E:
	ld (il_tmp),hl	; 066E  FD E5
	ld hl,(z80_iy)
	push hl
	ld hl,(il_tmp)
Z_0670:
	ld (il_tmp),hl	; 0670  FD 21 09 08
	ld hl,OBJ_BLOCK_0809
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_0674:
	call L_06DD	; 0674  CD DD 06
Z_0677:
	ld (il_tmp),hl	; 0677  FD E1
	pop hl
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_0679:
	ret	; 0679  C9
L_067A:
Z_067A:
	ld a,(OBJ_BLOCK_0809)	; 067A  3A 09 08
Z_067D:
	or a	; 067D  B7
Z_067E:
	ret z	; 067E  C8
Z_067F:
	ld (il_tmp),hl	; 067F  FD 21 09 08
	ld hl,OBJ_BLOCK_0809
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_0683:
	jp L_06A6	; 0683  18 21
L_0685:
Z_0685:
	ld a,(OBJ_BLOCK_0809+0xB)	; 0685  3A 14 08
Z_0688:
	or a	; 0688  B7
Z_0689:
	ret z	; 0689  C8
Z_068A:
	ld (il_tmp),hl	; 068A  FD 21 14 08
	ld hl,OBJ_BLOCK_0809+0xB
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_068E:
	jp L_06A6	; 068E  18 16
L_0690:
Z_0690:
	ld a,(OBJ_BLOCK_0809+0x16)	; 0690  3A 1F 08
Z_0693:
	or a	; 0693  B7
Z_0694:
	ret z	; 0694  C8
Z_0695:
	ld (il_tmp),hl	; 0695  FD 21 1F 08
	ld hl,OBJ_BLOCK_0809+0x16
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_0699:
	jp L_06A6	; 0699  18 0B
L_069B:
Z_069B:
	ld a,(OBJ_BLOCK_0809+0x21)	; 069B  3A 2A 08
Z_069E:
	or a	; 069E  B7
Z_069F:
	jp z,L_07B7	; 069F  CA B7 07
Z_06A2:
	ld (il_tmp),hl	; 06A2  FD 21 2A 08
	ld hl,OBJ_BLOCK_0809+0x21
	ld (z80_iy),hl
	ld hl,(il_tmp)
L_06A6:
Z_06A6:
	call il_iy_lda	; 06A6  FD 7E 01
	db 0x01
Z_06A9:
	ld b,a	; 06A9  47
Z_06AA:
	ld a,(GAME_VARS+0xC)	; 06AA  3A F6 0A
Z_06AD:
	cp b	; 06AD  B8
Z_06AE:
	jp z,L_06BA	; 06AE  28 0A
Z_06B0:
	ld d,0x60	; 06B0  16 60
Z_06B2:
	ld a,(LEVEL_VARS)	; 06B2  3A 7B 16
Z_06B5:
	cp b	; 06B5  B8
Z_06B6:
	jp nz,L_06ED	; 06B6  20 35
Z_06B8:
	jp L_06DF	; 06B8  18 25
L_06BA:
Z_06BA:
	call il_iy_ldl	; 06BA  FD 6E 02
	db 0x02
Z_06BD:
	call il_iy_ldh	; 06BD  FD 66 03
	db 0x03
Z_06C0:
	call L_06F2	; 06C0  CD F2 06
Z_06C3:
	jp nc,L_06DD	; 06C3  30 18
Z_06C5:
	call il_iy_ldl	; 06C5  FD 6E 08
	db 0x08
Z_06C8:
	call il_iy_ldh	; 06C8  FD 66 09
	db 0x09
Z_06CB:
	call L_06F2	; 06CB  CD F2 06
Z_06CE:
	call il_iy_ldb	; 06CE  FD 46 05
	db 0x05
Z_06D1:
	call il_iy_ldc	; 06D1  FD 4E 04
	db 0x04
Z_06D4:
	call il_iy_lda	; 06D4  FD 7E 06
	db 0x06
Z_06D7:
	call il_iy_or	; 06D7  FD B6 07
	db 0x07
Z_06DA:
	jp L_19A0	; 06DA  C3 A0 19
L_06DD:
Z_06DD:
	ld d,0x00	; 06DD  16 00
L_06DF:
Z_06DF:
	call il_iy_ldb	; 06DF  FD 46 05
	db 0x05
Z_06E2:
	call il_iy_lda	; 06E2  FD 7E 04
	db 0x04
Z_06E5:
	add a,d	; 06E5  82
Z_06E6:
	ld c,a	; 06E6  4F
Z_06E7:
	call il_iy_lda	; 06E7  FD 7E 06
	db 0x06
Z_06EA:
	call L_15CF	; 06EA  CD CF 15
L_06ED:
Z_06ED:
	xor a	; 06ED  AF
Z_06EE:
	call il_iy_sta	; 06EE  FD 77 00
	db 0x00
Z_06F1:
	ret	; 06F1  C9
L_06F2:
Z_06F2:
	jp (hl)	; 06F2  E9
L_06F3:
Z_06F3:
	call il_iy_ldb	; 06F3  FD 46 05
	db 0x05
Z_06F6:
	call il_iy_ldc	; 06F6  FD 4E 04
	db 0x04
Z_06F9:
	call il_iy_lda	; 06F9  FD 7E 07
	db 0x07
Z_06FC:
	call il_iy_lde	; 06FC  FD 5E 0A
	db 0x0A
Z_06FF:
	call L_0D6C	; 06FF  CD 6C 0D  ; в каноне +0x100 этот операнд стухший
Z_0702:
	call il_iy_stc	; 0702  FD 71 04
	db 0x04
Z_0705:
	call il_iy_stb	; 0705  FD 70 05
	db 0x05
Z_0708:
	ret	; 0708  C9
L_0709:
Z_0709:
	ld a,(OBJ_BLOCK_0809+0x21)	; 0709  3A 2A 08  ; в каноне +0x100 этот операнд стухший
Z_070C:
	cp 0x07	; 070C  FE 07
Z_070E:
	scf	; 070E  37
Z_070F:
	ret nz	; 070F  C0
Z_0710:
	ccf	; 0710  3F
Z_0711:
	ret	; 0711  C9
L_0712:
Z_0712:
	call L_06F3	; 0712  CD F3 06  ; в каноне +0x100 этот операнд стухший
Z_0715:
	ret nc	; 0715  D0
Z_0716:
	ld a,c	; 0716  79
Z_0717:
	cp 0x61	; 0717  FE 61
Z_0719:
	ret	; 0719  C9
L_071A:
Z_071A:
	ld d,0x1A	; 071A  16 1A
L_071C:
Z_071C:
	call il_iy_lda	; 071C  FD 7E 06
	db 0x06
Z_071F:
	dec a	; 071F  3D
Z_0720:
	sub d	; 0720  92
Z_0721:
	jp nz,L_0725	; 0721  20 02
Z_0723:
	ld a,0x03	; 0723  3E 03
L_0725:
Z_0725:
	add a,d	; 0725  82
Z_0726:
	call il_iy_sta	; 0726  FD 77 06
	db 0x06
Z_0729:
	call il_iy_lda	; 0729  FD 7E 00
	db 0x00
Z_072C:
	cp 0x01	; 072C  FE 01
Z_072E:
	ret z	; 072E  C8
Z_072F:
	call il_iy_stn	; 072F  FD 36 00 01
	db 0x00, 0x01
Z_0733:
	jp L_122C	; 0733  C3 2C 12  ; в каноне +0x100 этот операнд стухший
L_0736:
Z_0736:
	ld a,0x03	; 0736  3E 03
Z_0738:
	jp L_1226	; 0738  C3 26 12  ; в каноне +0x100 этот операнд стухший
L_073B:
Z_073B:
	ld a,(OBJ_BLOCK_0809+0x21)	; 073B  3A 2A 08  ; в каноне +0x100 этот операнд стухший
Z_073E:
	inc a	; 073E  3C
Z_073F:
	ld (OBJ_BLOCK_0809+0x21),a	; 073F  32 2A 08  ; в каноне +0x100 этот операнд стухший
Z_0742:
	cp 0x04	; 0742  FE 04
Z_0744:
	call z,L_0768	; 0744  CC 68 07  ; в каноне +0x100 этот операнд стухший
Z_0747:
	cpl	; 0747  2F
Z_0748:
	rrca	; 0748  0F
Z_0749:
	and 0x01	; 0749  E6 01
Z_074B:
	add a,0x22	; 074B  C6 22
Z_074D:
	call il_iy_sta	; 074D  FD 77 06
	db 0x06
Z_0750:
	ret	; 0750  C9
L_0751:
Z_0751:
	ld d,0x1E	; 0751  16 1E
Z_0753:
	call L_071C	; 0753  CD 1C 07  ; в каноне +0x100 этот операнд стухший
Z_0756:
	call L_0BBF	; 0756  CD BF 0B  ; в каноне +0x100 этот операнд стухший
Z_0759:
	jp nc,L_0763	; 0759  30 08
Z_075B:
	ld a,(OBJ_BLOCK_0809+0x1A)	; 075B  3A 23 08  ; в каноне +0x100 этот операнд стухший
Z_075E:
	add a,0x04	; 075E  C6 04
Z_0760:
	ld (OBJ_BLOCK_0809+0x1A),a	; 0760  32 23 08  ; в каноне +0x100 этот операнд стухший
L_0763:
Z_0763:
	ld a,0x0E	; 0763  3E 0E
Z_0765:
	jp L_1226	; 0765  C3 26 12  ; в каноне +0x100 этот операнд стухший
L_0768:
Z_0768:
	ld (OBJ_BLOCK_0809+0xB),a	; 0768  32 14 08  ; в каноне +0x100 этот операнд стухший
Z_076B:
	ld a,(OBJ_BLOCK_0809+0x22)	; 076B  3A 2B 08  ; в каноне +0x100 этот операнд стухший
Z_076E:
	ld (OBJ_BLOCK_0809+0xC),a	; 076E  32 15 08  ; в каноне +0x100 этот операнд стухший
Z_0771:
	ld hl,(OBJ_BLOCK_0809+0x25)	; 0771  2A 2E 08  ; в каноне +0x100 этот операнд стухший
Z_0774:
	ld a,l	; 0774  7D
Z_0775:
	sub 0x09	; 0775  D6 09
Z_0777:
	ld l,a	; 0777  6F
Z_0778:
	ld a,(OBJ_BLOCK_0809+0x28)	; 0778  3A 31 08  ; в каноне +0x100 этот операнд стухший
Z_077B:
	ld (OBJ_BLOCK_0809+0x12),a	; 077B  32 1B 08  ; в каноне +0x100 этот операнд стухший
Z_077E:
	or a	; 077E  B7
Z_077F:
	jp z,L_0783	; 077F  28 02
Z_0781:
	ld a,0x18	; 0781  3E 18
L_0783:
Z_0783:
	add a,h	; 0783  84
Z_0784:
	sub 0x04	; 0784  D6 04
Z_0786:
	ld h,a	; 0786  67
Z_0787:
	ld (OBJ_BLOCK_0809+0xF),hl	; 0787  22 18 08  ; в каноне +0x100 этот операнд стухший
Z_078A:
	ld a,0x04	; 078A  3E 04
Z_078C:
	ret	; 078C  C9
L_078D:
Z_078D:
	ld a,(z80_ix)	; 078D  DD 7D
Z_078F:
	cp 0x81	; 078F  FE 81
Z_0791:
	ret nc	; 0791  D0
Z_0792:
	ld a,(GAME_VARS+0xB)	; 0792  3A F5 0A
Z_0795:
	ld h,0x18	; 0795  26 18
Z_0797:
	cp 0x54	; 0797  FE 54
Z_0799:
	jp nc,L_079C	; 0799  30 01
Z_079B:
	ld h,d	; 079B  62
L_079C:
Z_079C:
	ld a,h	; 079C  7C
Z_079D:
	cpl	; 079D  2F
Z_079E:
	and 0x80	; 079E  E6 80
Z_07A0:
	ld e,a	; 07A0  5F
Z_07A1:
	call il_rnd	; 07A1  ED 5F
Z_07A3:
	ld d,a	; 07A3  57
Z_07A4:
	and 0x3F	; 07A4  E6 3F
Z_07A6:
	cp 0x03	; 07A6  FE 03
Z_07A8:
	ccf	; 07A8  3F
Z_07A9:
	ret nc	; 07A9  D0
Z_07AA:
	ld b,a	; 07AA  47
Z_07AB:
	ld a,(D_07B6)	; 07AB  3A B6 07
Z_07AE:
	dec a	; 07AE  3D
Z_07AF:
	ld (D_07B6),a	; 07AF  32 B6 07
Z_07B2:
	cp 0x01	; 07B2  FE 01
Z_07B4:
	ld a,b	; 07B4  78
Z_07B5:
	ret	; 07B5  C9
D_07B6:
Z_07B6:
	db	0xE3	; 07B6
L_07B7:
Z_07B7:
	ld a,(OBJ_BLOCK_0809+0xB)	; 07B7  3A 14 08
Z_07BA:
	or a	; 07BA  B7
Z_07BB:
	ret nz	; 07BB  C0
Z_07BC:
	ld a,(OBJ_BLOCK_0809+0x16)	; 07BC  3A 1F 08
Z_07BF:
	or a	; 07BF  B7
Z_07C0:
	ret nz	; 07C0  C0
Z_07C1:
	ld d,0x98	; 07C1  16 98
Z_07C3:
	call L_078D	; 07C3  CD 8D 07
Z_07C6:
	ret nc	; 07C6  D0
Z_07C7:
	and 0x01	; 07C7  E6 01
Z_07C9:
	jp z,L_07EF	; 07C9  CA EF 07
Z_07CC:
	ld a,(GAME_VARS+0xC)	; 07CC  3A F6 0A
Z_07CF:
	ld (OBJ_BLOCK_0809+0x22),a	; 07CF  32 2B 08
Z_07D2:
	ld a,e	; 07D2  7B
Z_07D3:
	ld (OBJ_BLOCK_0809+0x28),a	; 07D3  32 31 08
Z_07D6:
	ld a,d	; 07D6  7A
Z_07D7:
	and 0x40	; 07D7  E6 40
Z_07D9:
	rrca	; 07D9  0F
Z_07DA:
	rrca	; 07DA  0F
Z_07DB:
	ld d,a	; 07DB  57
Z_07DC:
	ld a,(GAME_VARS+0xA)	; 07DC  3A F4 0A
Z_07DF:
	cp 0x30	; 07DF  FE 30
Z_07E1:
	jp c,L_07E5	; 07E1  38 02
Z_07E3:
	sub d	; 07E3  92
Z_07E4:
	inc a	; 07E4  3C
L_07E5:
Z_07E5:
	ld l,a	; 07E5  6F
Z_07E6:
	ld (OBJ_BLOCK_0809+0x25),hl	; 07E6  22 2E 08
Z_07E9:
	ld a,0x01	; 07E9  3E 01
Z_07EB:
	ld (OBJ_BLOCK_0809+0x21),a	; 07EB  32 2A 08
Z_07EE:
	ret	; 07EE  C9
L_07EF:
Z_07EF:
	ld a,0x01	; 07EF  3E 01
Z_07F1:
	ld (OBJ_BLOCK_0809+0x16),a	; 07F1  32 1F 08
Z_07F4:
	ld a,0x21	; 07F4  3E 21
Z_07F6:
	ld (OBJ_BLOCK_0809+0x1C),a	; 07F6  32 25 08
Z_07F9:
	ld a,(GAME_VARS+0xC)	; 07F9  3A F6 0A
Z_07FC:
	ld (OBJ_BLOCK_0809+0x17),a	; 07FC  32 20 08
Z_07FF:
	ld l,0x50	; 07FF  2E 50
Z_0801:
	ld (OBJ_BLOCK_0809+0x1A),hl	; 0801  22 23 08
Z_0804:
	ld a,e	; 0804  7B
Z_0805:
	ld (OBJ_BLOCK_0809+0x1D),a	; 0805  32 26 08
Z_0808:
	ret	; 0808  C9
OBJ_BLOCK_0809:
Z_0809:
	db	0x00,0x16	; 0809
Z_080B:
	dw	L_06F3	; 080B  F3 06
Z_080D:
	db	0x46,0xFF,0x1B,0x00	; 080D
Z_0811:
	dw	L_071A	; 0811  1A 07
Z_0813:
	db	0x00,0x00,0x0C	; 0813
Z_0816:
	dw	L_06F3	; 0816  F3 06
Z_0818:
	db	0x48,0xAA,0x26,0x80	; 0818
Z_081C:
	dw	L_0736	; 081C  36 07
Z_081E:
	db	0x08,0x00,0x16	; 081E
Z_0821:
	dw	L_0712	; 0821  12 07
Z_0823:
	db	0x50,0xFC,0x20,0x00	; 0823
Z_0827:
	dw	L_0751	; 0827  51 07
Z_0829:
	db	0x08,0x00,0x0C	; 0829
Z_082C:
	dw	L_0709	; 082C  09 07
Z_082E:
	db	0x51,0x18,0x22,0x80	; 082E
Z_0832:
	dw	L_073B	; 0832  3B 07
L_0834:
Z_0834:
	call L_19F2	; 0834  CD F2 19
L_0837:
Z_0837:
	ld a,0x00	; 0837  3E 00
Z_0839:
	or a	; 0839  B7
Z_083A:
	jp nz,L_0841	; 083A  20 05
Z_083C:
	call L_0A60	; 083C  CD 60 0A
Z_083F:
	jp L_084C	; 083F  18 0B
L_0841:
Z_0841:
	dec a	; 0841  3D
Z_0842:
	ld (L_0837+0x1),a	; 0842  32 38 08
Z_0845:
	push hl	; 0845  ED 4B F4 0A
	ld hl,(GAME_VARS+0xA)
	ld b,h
	ld c,l
	pop hl
Z_0849:
	call L_15D0	; 0849  CD D0 15
L_084C:
Z_084C:
	call L_0883	; 084C  CD 83 08
Z_084F:
	call L_10DB	; 084F  CD DB 10
Z_0852:
	call L_067A	; 0852  CD 7A 06
Z_0855:
	call L_1275	; 0855  CD 75 12
Z_0858:
	call L_04D5	; 0858  CD D5 04
Z_085B:
	call L_0558	; 085B  CD 58 05
Z_085E:
	call L_12E0	; 085E  CD E0 12
Z_0861:
	call L_0690	; 0861  CD 90 06
Z_0864:
	call L_069B	; 0864  CD 9B 06
Z_0867:
	call L_0685	; 0867  CD 85 06
Z_086A:
	ld a,(GAME_VARS+0xC)	; 086A  3A F6 0A
Z_086D:
	ld b,a	; 086D  47
Z_086E:
	ld a,(LEVEL_VARS)	; 086E  3A 7B 16
Z_0871:
	cp b	; 0871  B8
Z_0872:
	jp nz,L_0879	; 0872  20 05
Z_0874:
	ld a,0x01	; 0874  3E 01
Z_0876:
	ld (D_1A23),a	; 0876  32 23 1A
L_0879:
Z_0879:
	call L_1A24	; 0879  CD 24 1A
Z_087C:
	xor a	; 087C  AF
Z_087D:
	ld (D_1A23),a	; 087D  32 23 1A
Z_0880:
	jp L_0DE3	; 0880  C3 E3 0D
L_0883:
Z_0883:
	ld a,(LEVEL_VARS+0x7)	; 0883  3A 82 16
Z_0886:
	or a	; 0886  B7
Z_0887:
	ret z	; 0887  C8
Z_0888:
	ld hl,L_08FB	; 0888  21 FB 08
Z_088B:
	push hl	; 088B  E5
Z_088C:
	ld a,0xF0	; 088C  3E F0
Z_088E:
	out (0xAA),a	; 088E  D3 AA
Z_0890:
	nop	; 0890  00
Z_0891:
	in a,(0xA9)	; 0891  DB A9
Z_0893:
	and 0x3E	; 0893  E6 3E
Z_0895:
	cp 0x3E	; 0895  FE 3E
Z_0897:
	jp nz,L_089F	; 0897  20 06
L_0899:
Z_0899:
	ld a,0x00	; 0899  3E 00
Z_089B:
	ld c,0x00	; 089B  0E 00
Z_089D:
	jp L_08A1	; 089D  18 02
L_089F:
Z_089F:
	ld c,0x01	; 089F  0E 01
L_08A1:
Z_08A1:
	ld (L_08EE+0x1),a	; 08A1  32 EF 08
Z_08A4:
	cp 0x3C	; 08A4  FE 3C
Z_08A6:
	jp z,L_08D0	; 08A6  28 28
Z_08A8:
	cp 0x3A	; 08A8  FE 3A
Z_08AA:
	jp z,L_08DA	; 08AA  28 2E
Z_08AC:
	cp 0x36	; 08AC  FE 36
Z_08AE:
	jp z,L_08C6	; 08AE  28 16
Z_08B0:
	cp 0x2E	; 08B0  FE 2E
Z_08B2:
	jp z,L_08BC	; 08B2  28 08
Z_08B4:
	cp 0x1E	; 08B4  FE 1E
Z_08B6:
	ret nz	; 08B6  C0
Z_08B7:
	ld a,(OBJ_ARRAY_14BF+0x20)	; 08B7  3A DF 14
Z_08BA:
	jp L_08E4	; 08BA  18 28
L_08BC:
Z_08BC:
	ld a,(OBJ_ARRAY_14BF+0x9)	; 08BC  3A C8 14
Z_08BF:
	dec a	; 08BF  3D
Z_08C0:
	ret z	; 08C0  C8
Z_08C1:
	ld a,(OBJ_ARRAY_14BF+0x6)	; 08C1  3A C5 14
Z_08C4:
	jp L_08E4	; 08C4  18 1E
L_08C6:
Z_08C6:
	ld a,(OBJ_ARRAY_14BF+0x16)	; 08C6  3A D5 14
Z_08C9:
	dec a	; 08C9  3D
Z_08CA:
	ret z	; 08CA  C8
Z_08CB:
	ld a,(OBJ_ARRAY_14BF+0x13)	; 08CB  3A D2 14
Z_08CE:
	jp L_08E4	; 08CE  18 14
L_08D0:
Z_08D0:
	ld a,(LEVEL_VARS+0x9)	; 08D0  3A 84 16
Z_08D3:
	or a	; 08D3  B7
Z_08D4:
	ret nz	; 08D4  C0
Z_08D5:
	ld a,(LEVEL_VARS+0x3)	; 08D5  3A 7E 16
Z_08D8:
	jp L_08E4	; 08D8  18 0A
L_08DA:
Z_08DA:
	ld a,(LEVEL_VARS+0xB)	; 08DA  3A 86 16
Z_08DD:
	or a	; 08DD  B7
Z_08DE:
	ret nz	; 08DE  C0
Z_08DF:
	ld a,(LEVEL_VARS+0x5)	; 08DF  3A 80 16
Z_08E2:
	jp L_08E4	; 08E2  18 00
L_08E4:
Z_08E4:
	ld b,a	; 08E4  47
Z_08E5:
	ld a,(LEVEL_VARS)	; 08E5  3A 7B 16
L_08E8:
Z_08E8:
	cp b	; 08E8  B8
Z_08E9:
	ret z	; 08E9  C8
Z_08EA:
	ld a,b	; 08EA  78
Z_08EB:
	ld (LEVEL_VARS),a	; 08EB  32 7B 16
L_08EE:
Z_08EE:
	ld a,0x00	; 08EE  3E 00
Z_08F0:
	ld (L_0899+0x1),a	; 08F0  32 9A 08
Z_08F3:
	xor a	; 08F3  AF
Z_08F4:
	cp c	; 08F4  B9
Z_08F5:
	call nz,RET_STUB	; 08F5  C4 F8 1C
Z_08F8:
	jp L_1372	; 08F8  C3 72 13
L_08FB:
Z_08FB:
	ld (il_tmp),hl	; 08FB  FD 21 BF 14  ; в каноне +0x100 этот операнд стухший
	ld hl,OBJ_ARRAY_14BF
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_08FF:
	ld b,0x03	; 08FF  06 03
L_0901:
Z_0901:
	push bc	; 0901  C5
Z_0902:
	call il_iy_lda	; 0902  FD 7E 09
	db 0x09
Z_0905:
	cp 0x01	; 0905  FE 01
Z_0907:
	jp z,L_0948	; 0907  28 3F
Z_0909:
	call L_0962	; 0909  CD 62 09  ; в каноне +0x100 этот операнд стухший
Z_090C:
	ld a,(GAME_VARS+0xC)	; 090C  3A F6 0A  ; в каноне +0x100 этот операнд стухший
Z_090F:
	call il_iy_cp	; 090F  FD BE 06
	db 0x06
Z_0912:
	jp nz,L_092F	; 0912  20 1B
Z_0914:
	ld d,0x00	; 0914  16 00
Z_0916:
	call L_0951	; 0916  CD 51 09  ; в каноне +0x100 этот операнд стухший
Z_0919:
	call L_11F2	; 0919  CD F2 11  ; в каноне +0x100 этот операнд стухший
Z_091C:
	pop bc	; 091C  C1
Z_091D:
	push bc	; 091D  C5
Z_091E:
	xor a	; 091E  AF
Z_091F:
	cp e	; 091F  BB
Z_0920:
	call nz,L_0979	; 0920  C4 79 09  ; в каноне +0x100 этот операнд стухший
Z_0923:
	pop af	; 0923  F1
Z_0924:
	push af	; 0924  F5
Z_0925:
	call L_09AF	; 0925  CD AF 09  ; в каноне +0x100 этот операнд стухший
Z_0928:
	jp L_0948	; 0928  18 1E
L_092A:
Z_092A:
	call L_0951	; 092A  CD 51 09  ; в каноне +0x100 этот операнд стухший
Z_092D:
	jp L_0948	; 092D  18 19
L_092F:
Z_092F:
	ld a,(LEVEL_VARS)	; 092F  3A 7B 16  ; в каноне +0x100 этот операнд стухший
Z_0932:
	ld d,0x60	; 0932  16 60
Z_0934:
	call il_iy_cp	; 0934  FD BE 06
	db 0x06
Z_0937:
	jp z,L_092A	; 0937  28 F1
Z_0939:
	call il_iy_lda	; 0939  FD 7E 09
	db 0x09
Z_093C:
	cp 0x04	; 093C  FE 04
Z_093E:
	jp nc,L_0948	; 093E  30 08
Z_0940:
	cp 0x02	; 0940  FE 02
Z_0942:
	jp c,L_0948	; 0942  38 04
Z_0944:
	call il_iy_stn	; 0944  FD 36 09 01
	db 0x09, 0x01
L_0948:
Z_0948:
	ld bc,0x0D	; 0948  01 0D 00
Z_094B:
	ld (il_tmp),hl	; 094B  FD 09
	ld hl,(z80_iy)
	add hl,bc
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_094D:
	pop bc	; 094D  C1
Z_094E:
	dec b	; 094E  10 B1
	jp nz,L_0901
Z_0950:
	ret	; 0950  C9
L_0951:
Z_0951:
	call il_iy_lda	; 0951  FD 7E 07
	db 0x07
Z_0954:
	add a,d	; 0954  82
Z_0955:
	ld c,a	; 0955  4F
Z_0956:
	call il_iy_ldb	; 0956  FD 46 08
	db 0x08
Z_0959:
	call il_iy_lda	; 0959  FD 7E 0B
	db 0x0B
Z_095C:
	push bc	; 095C  C5
Z_095D:
	call L_19A0	; 095D  CD A0 19  ; в каноне +0x100 этот операнд стухший
Z_0960:
	pop bc	; 0960  C1
Z_0961:
	ret	; 0961  C9
L_0962:
Z_0962:
	or a	; 0962  B7
Z_0963:
	jp z,L_09E8	; 0963  CA E8 09  ; в каноне +0x100 этот операнд стухший
Z_0966:
	cp 0x04	; 0966  FE 04
Z_0968:
	jp c,L_096D	; 0968  38 03
Z_096A:
	call il_iy_dec	; 096A  FD 35 09
	db 0x09
L_096D:
Z_096D:
	ld b,0x00	; 096D  06 00
Z_096F:
	ld c,a	; 096F  4F
Z_0970:
	ld hl,L_09E0+0x2	; 0970  21 E2 09  ; в каноне +0x100 этот операнд стухший
Z_0973:
	add hl,bc	; 0973  09
Z_0974:
	ld a,(hl)	; 0974  7E
Z_0975:
	call il_iy_sta	; 0975  FD 77 0B
	db 0x0B
Z_0978:
	ret	; 0978  C9
L_0979:
Z_0979:
	call il_iy_lda	; 0979  FD 7E 09
	db 0x09
Z_097C:
	or a	; 097C  B7
Z_097D:
	ret nz	; 097D  C0
Z_097E:
	ld a,b	; 097E  78
Z_097F:
	cp 0x03	; 097F  FE 03
Z_0981:
	jp z,L_099B	; 0981  28 18
Z_0983:
	cp 0x02	; 0983  FE 02
Z_0985:
	jp nz,L_0F25	; 0985  C2 25 0F  ; в каноне +0x100 этот операнд стухший
Z_0988:
	ld a,(LEVEL_VARS+0xB)	; 0988  3A 86 16  ; в каноне +0x100 этот операнд стухший
Z_098B:
	or a	; 098B  B7
Z_098C:
	ret z	; 098C  C8
Z_098D:
	ld a,0x05	; 098D  3E 05
Z_098F:
	ld (OBJ_ARRAY_14BF+0x16),a	; 098F  32 D5 14  ; в каноне +0x100 этот операнд стухший
Z_0992:
	ld a,(OBJ_ARRAY_14BF+0x9)	; 0992  3A C8 14  ; в каноне +0x100 этот операнд стухший
Z_0995:
	or a	; 0995  B7
Z_0996:
	jp z,L_13AF	; 0996  CA AF 13  ; в каноне +0x100 этот операнд стухший
Z_0999:
	jp L_09AC	; 0999  18 11
L_099B:
Z_099B:
	ld a,(LEVEL_VARS+0x9)	; 099B  3A 84 16  ; в каноне +0x100 этот операнд стухший
Z_099E:
	or a	; 099E  B7
Z_099F:
	ret z	; 099F  C8
Z_09A0:
	ld a,0x02	; 09A0  3E 02
Z_09A2:
	ld (OBJ_ARRAY_14BF+0x9),a	; 09A2  32 C8 14  ; в каноне +0x100 этот операнд стухший
Z_09A5:
	ld a,(OBJ_ARRAY_14BF+0x16)	; 09A5  3A D5 14  ; в каноне +0x100 этот операнд стухший
Z_09A8:
	or a	; 09A8  B7
Z_09A9:
	jp z,L_13B7	; 09A9  CA B7 13  ; в каноне +0x100 этот операнд стухший
L_09AC:
Z_09AC:
	jp L_13A0	; 09AC  C3 A0 13  ; в каноне +0x100 этот операнд стухший
L_09AF:
Z_09AF:
	cp 0x01	; 09AF  FE 01
Z_09B1:
	ret nz	; 09B1  C0
Z_09B2:
	ld a,(OBJ_BLOCK_0809)	; 09B2  3A 09 08  ; в каноне +0x100 этот операнд стухший
Z_09B5:
	cp 0x01	; 09B5  FE 01
Z_09B7:
	ret nz	; 09B7  C0
Z_09B8:
	ld a,(OBJ_ARRAY_14BF+0x16)	; 09B8  3A D5 14  ; в каноне +0x100 этот операнд стухший
Z_09BB:
	or a	; 09BB  B7
Z_09BC:
	ret z	; 09BC  C8
Z_09BD:
	ld a,(OBJ_ARRAY_14BF+0x9)	; 09BD  3A C8 14  ; в каноне +0x100 этот операнд стухший
Z_09C0:
	or a	; 09C0  B7
Z_09C1:
	ret z	; 09C1  C8
Z_09C2:
	call il_iy_ldb	; 09C2  FD 46 08
	db 0x08
Z_09C5:
	call il_iy_ldc	; 09C5  FD 4E 07
	db 0x07
Z_09C8:
	ld a,(OBJ_BLOCK_0809+0x5)	; 09C8  3A 0E 08  ; в каноне +0x100 этот операнд стухший
Z_09CB:
	sub 0x18	; 09CB  D6 18
Z_09CD:
	cp b	; 09CD  B8
Z_09CE:
	ret nc	; 09CE  D0
Z_09CF:
	add a,0x20	; 09CF  C6 20
Z_09D1:
	cp b	; 09D1  B8
Z_09D2:
	ret c	; 09D2  D8
Z_09D3:
	ld a,(OBJ_BLOCK_0809+0x4)	; 09D3  3A 0D 08  ; в каноне +0x100 этот операнд стухший
Z_09D6:
	sub 0x08	; 09D6  D6 08
Z_09D8:
	cp c	; 09D8  B9
Z_09D9:
	ret nc	; 09D9  D0
Z_09DA:
	add a,0x30	; 09DA  C6 30
Z_09DC:
	cp c	; 09DC  B9
Z_09DD:
	ret c	; 09DD  D8
Z_09DE:
	ld a,0x01	; 09DE  3E 01
L_09E0:
Z_09E0:
	ld (D_04D4),a	; 09E0  32 D4 04  ; в каноне +0x100 этот операнд стухший
Z_09E3:
	ret	; 09E3  C9
D_09E4:
Z_09E4:
	db	0x27,0x34,0x32,0x33	; 09E4
L_09E8:
Z_09E8:
	call Z_1412	; 09E8  CD 12 14  ; в каноне +0x100 этот операнд стухший  ; ВХОД ПОСРЕДИ КОМАНДЫ -> Z_1412
Z_09EB:
	xor a	; 09EB  AF
Z_09EC:
	cp d	; 09EC  BA
Z_09ED:
	jp z,L_09F7	; 09ED  28 08
Z_09EF:
	call il_iy_lda	; 09EF  FD 7E 0A
	db 0x0A
Z_09F2:
	or e	; 09F2  B3
Z_09F3:
	xor 0x80	; 09F3  EE 80
Z_09F5:
	jp L_0A02	; 09F5  18 0B
L_09F7:
Z_09F7:
	call il_iy_lda	; 09F7  FD 7E 03
	db 0x03
Z_09FA:
	push bc	; 09FA  C5
Z_09FB:
	call L_15FA	; 09FB  CD FA 15  ; в каноне +0x100 этот операнд стухший
Z_09FE:
	pop bc	; 09FE  C1
Z_09FF:
	and 0x3F	; 09FF  E6 3F
Z_0A01:
	or e	; 0A01  B3
L_0A02:
Z_0A02:
	call il_iy_sta	; 0A02  FD 77 0B
	db 0x0B
Z_0A05:
	ld e,0x00	; 0A05  1E 00
Z_0A07:
	ld h,b	; 0A07  60
Z_0A08:
	ld l,0x60	; 0A08  2E 60
Z_0A0A:
	ld a,0x1F	; 0A0A  3E 1F
Z_0A0C:
	cp c	; 0A0C  B9
Z_0A0D:
	jp nc,L_0A28	; 0A0D  30 19
Z_0A0F:
	ld l,0x20	; 0A0F  2E 20
Z_0A11:
	inc e	; 0A11  1C
Z_0A12:
	ld a,0x60	; 0A12  3E 60
Z_0A14:
	cp c	; 0A14  B9
Z_0A15:
	jp c,L_0A28	; 0A15  38 11
Z_0A17:
	ld l,c	; 0A17  69
Z_0A18:
	ld h,0xA8	; 0A18  26 A8
Z_0A1A:
	inc e	; 0A1A  1C
Z_0A1B:
	ld a,0xE6	; 0A1B  3E E6
Z_0A1D:
	cp b	; 0A1D  B8
Z_0A1E:
	jp c,L_0A28	; 0A1E  38 08
Z_0A20:
	ld h,0x00	; 0A20  26 00
Z_0A22:
	inc e	; 0A22  1C
Z_0A23:
	ld a,0xA8	; 0A23  3E A8
Z_0A25:
	cp b	; 0A25  B8
Z_0A26:
	jp nc,L_0A59	; 0A26  30 31
L_0A28:
Z_0A28:
	push hl	; 0A28  E5
Z_0A29:
	ld d,0x00	; 0A29  16 00
Z_0A2B:
	push de	; 0A2B  D5
Z_0A2C:
	call il_iy_ldb	; 0A2C  FD 46 08
	db 0x08
Z_0A2F:
	call il_iy_ldc	; 0A2F  FD 4E 07
	db 0x07
Z_0A32:
	ld a,(GAME_VARS+0xC)	; 0A32  3A F6 0A  ; в каноне +0x100 этот операнд стухший
Z_0A35:
	call il_iy_cp	; 0A35  FD BE 06
	db 0x06
Z_0A38:
	jp z,L_0A46	; 0A38  28 0C
Z_0A3A:
	ld a,(LEVEL_VARS)	; 0A3A  3A 7B 16  ; в каноне +0x100 этот операнд стухший
Z_0A3D:
	call il_iy_cp	; 0A3D  FD BE 06
	db 0x06
Z_0A40:
	jp nz,L_0A4A	; 0A40  20 08
Z_0A42:
	ld a,c	; 0A42  79
Z_0A43:
	add a,0x60	; 0A43  C6 60
Z_0A45:
	ld c,a	; 0A45  4F
L_0A46:
Z_0A46:
	xor a	; 0A46  AF
Z_0A47:
	call L_15CF	; 0A47  CD CF 15  ; в каноне +0x100 этот операнд стухший
L_0A4A:
Z_0A4A:
	call il_iy_lda	; 0A4A  FD 7E 06
	db 0x06
Z_0A4D:
	call L_1A6C	; 0A4D  CD 6C 1A  ; в каноне +0x100 этот операнд стухший
Z_0A50:
	pop de	; 0A50  D1
Z_0A51:
	add hl,de	; 0A51  19
Z_0A52:
	ld a,(hl)	; 0A52  7E
Z_0A53:
	call il_iy_sta	; 0A53  FD 77 06
	db 0x06
Z_0A56:
	pop hl	; 0A56  E1
Z_0A57:
	ld b,h	; 0A57  44
Z_0A58:
	ld c,l	; 0A58  4D
L_0A59:
Z_0A59:
	call il_iy_stc	; 0A59  FD 71 07
	db 0x07
Z_0A5C:
	call il_iy_stb	; 0A5C  FD 70 08
	db 0x08
Z_0A5F:
	ret	; 0A5F  C9
L_0A60:
Z_0A60:
	ld hl,L_0B45	; 0A60  21 45 0B
Z_0A63:
	push hl	; 0A63  E5
Z_0A64:
	ld a,(GAME_VARS+0x9)	; 0A64  3A F3 0A
Z_0A67:
	or a	; 0A67  B7
Z_0A68:
	jp z,L_0A81	; 0A68  28 17
Z_0A6A:
	call L_0B40	; 0A6A  CD 40 0B
Z_0A6D:
	jp nz,L_0A81	; 0A6D  20 12
Z_0A6F:
	call L_0BBA	; 0A6F  CD BA 0B
Z_0A72:
	jp c,L_0CEF	; 0A72  DA EF 0C
Z_0A75:
	ld a,(GAME_VARS+0x7)	; 0A75  3A F1 0A
Z_0A78:
	cp 0x08	; 0A78  FE 08
Z_0A7A:
	jp nc,L_0A81	; 0A7A  30 05
Z_0A7C:
	cp 0x06	; 0A7C  FE 06
Z_0A7E:
	call nc,L_0ABE	; 0A7E  D4 BE 0A
L_0A81:
Z_0A81:
	xor a	; 0A81  AF
Z_0A82:
	ld (GAME_VARS+0x2),a	; 0A82  32 EC 0A
Z_0A85:
	ld a,(GAME_VARS+0x5)	; 0A85  3A EF 0A
Z_0A88:
	or a	; 0A88  B7
Z_0A89:
	jp nz,L_0CA8	; 0A89  C2 A8 0C
Z_0A8C:
	ld a,(GAME_VARS+0x6)	; 0A8C  3A F0 0A
Z_0A8F:
	or a	; 0A8F  B7
Z_0A90:
	jp nz,L_0D25	; 0A90  C2 25 0D
Z_0A93:
	call L_0B1F	; 0A93  CD 1F 0B
Z_0A96:
	call L_157B	; 0A96  CD 7B 15
Z_0A99:
	ld (il_a),a	; 0A99  CB 60
	ld a,b
	and 0x10
	ld a,(il_a)
Z_0A9B:
	jp nz,L_0C9F	; 0A9B  C2 9F 0C
Z_0A9E:
	ld (il_a),a	; 0A9E  CB 40
	ld a,b
	and 0x01
	ld a,(il_a)
Z_0AA0:
	jp nz,L_0B90	; 0AA0  C2 90 0B
Z_0AA3:
	ld (il_a),a	; 0AA3  CB 48
	ld a,b
	and 0x02
	ld a,(il_a)
Z_0AA5:
	jp nz,L_0B7C	; 0AA5  C2 7C 0B
Z_0AA8:
	ld a,0x01	; 0AA8  3E 01
Z_0AAA:
	ld (GAME_VARS+0x4),a	; 0AAA  32 EE 0A
Z_0AAD:
	ld (il_a),a	; 0AAD  CB 50
	ld a,b
	and 0x04
	ld a,(il_a)
Z_0AAF:
	jp nz,L_0B74	; 0AAF  C2 74 0B
Z_0AB2:
	ld (il_a),a	; 0AB2  CB 58
	ld a,b
	and 0x08
	ld a,(il_a)
Z_0AB4:
	jp nz,L_0B5D	; 0AB4  C2 5D 0B
Z_0AB7:
	xor a	; 0AB7  AF
Z_0AB8:
	ld (GAME_VARS+0x4),a	; 0AB8  32 EE 0A
Z_0ABB:
	jp L_0BB1	; 0ABB  C3 B1 0B
L_0ABE:
Z_0ABE:
	call SFX_64B9	; 0ABE  CD 88 20
Z_0AC1:
	ld a,(GAME_VARS+0x3)	; 0AC1  3A ED 0A
Z_0AC4:
	cp 0x10	; 0AC4  FE 10
Z_0AC6:
	jp c,L_0ADC	; 0AC6  38 14
Z_0AC8:
	ld a,(L_122C+0x1)	; 0AC8  3A 2D 12
Z_0ACB:
	ld b,a	; 0ACB  47
Z_0ACC:
	ld a,(GAME_VARS+0x3)	; 0ACC  3A ED 0A
Z_0ACF:
	sub 0x0F	; 0ACF  D6 0F
Z_0AD1:
	cp b	; 0AD1  B8
Z_0AD2:
	jp nc,L_0AD5	; 0AD2  30 01
Z_0AD4:
	ld b,a	; 0AD4  47
L_0AD5:
Z_0AD5:
	push bc	; 0AD5  C5
Z_0AD6:
	call L_122C	; 0AD6  CD 2C 12
Z_0AD9:
	pop bc	; 0AD9  C1
Z_0ADA:
	dec b	; 0ADA  10 F9
	jp nz,L_0AD5
L_0ADC:
Z_0ADC:
	xor a	; 0ADC  AF
Z_0ADD:
	ld (GAME_VARS+0x3),a	; 0ADD  32 ED 0A
Z_0AE0:
	ret	; 0AE0  C9
L_0AE1:
Z_0AE1:
	ld a,(GAME_VARS+0xE)	; 0AE1  3A F8 0A
Z_0AE4:
	xor 0x80	; 0AE4  EE 80
Z_0AE6:
	ld (GAME_VARS+0xE),a	; 0AE6  32 F8 0A
Z_0AE9:
	ret	; 0AE9  C9
GAME_VARS:
Z_0AEA:
	db	0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x07,0x50,0x77,0x16,0x00,0x80,0x01	; 0AEA
Z_0AFA:
	db	0x20,0x4B,0x16,0x00,0x80	; 0AFA
L_0AFF:
Z_0AFF:
	ld hl,GAME_VARS	; 0AFF  21 EA 0A
Z_0B02:
	ld de,GAME_VARS+0x1	; 0B02  11 EB 0A
Z_0B05:
	ld bc,0x14	; 0B05  01 14 00
Z_0B08:
	ld (hl),0x00	; 0B08  36 00
Z_0B0A:
	call il_ldir	; 0B0A  ED B0
Z_0B0C:
	ld hl,0x4050	; 0B0C  21 50 40
Z_0B0F:
	ld (GAME_VARS+0xA),hl	; 0B0F  22 F4 0A
Z_0B12:
	ld hl,0x0103	; 0B12  21 03 01
Z_0B15:
	ld (GAME_VARS+0x8),hl	; 0B15  22 F2 0A
Z_0B18:
	ld hl,0x0180	; 0B18  21 80 01
Z_0B1B:
	ld (GAME_VARS+0xE),hl	; 0B1B  22 F8 0A
Z_0B1E:
	ret	; 0B1E  C9
L_0B1F:
Z_0B1F:
	ld a,(GAME_VARS)	; 0B1F  3A EA 0A
Z_0B22:
	or a	; 0B22  B7
Z_0B23:
	ret nz	; 0B23  C0
Z_0B24:
	ld a,(L_0837+0x1)	; 0B24  3A 38 08
Z_0B27:
	or a	; 0B27  B7
Z_0B28:
	ret nz	; 0B28  C0
Z_0B29:
	inc a	; 0B29  3C
Z_0B2A:
	ld (GAME_VARS),a	; 0B2A  32 EA 0A
Z_0B2D:
	ld hl,(GAME_VARS+0xA)	; 0B2D  2A F4 0A
Z_0B30:
	ld (GAME_VARS+0x10),hl	; 0B30  22 FA 0A
Z_0B33:
	ld hl,(GAME_VARS+0xC)	; 0B33  2A F6 0A
Z_0B36:
	ld (GAME_VARS+0x12),hl	; 0B36  22 FC 0A
Z_0B39:
	ld a,(GAME_VARS+0xE)	; 0B39  3A F8 0A
Z_0B3C:
	ld (GAME_VARS+0x14),a	; 0B3C  32 FE 0A
Z_0B3F:
	ret	; 0B3F  C9
L_0B40:
Z_0B40:
	ld a,(GAME_VARS+0xD)	; 0B40  3A F7 0A
Z_0B43:
	or a	; 0B43  B7
Z_0B44:
	ret	; 0B44  C9
L_0B45:
Z_0B45:
	call L_0C2C	; 0B45  CD 2C 0C
Z_0B48:
	call L_0DBB	; 0B48  CD BB 0D
Z_0B4B:
	call L_207E	; 0B4B  CD 7E 20
Z_0B4E:
	ld a,(GAME_VARS+0xE)	; 0B4E  3A F8 0A
Z_0B51:
	ld b,a	; 0B51  47
Z_0B52:
	ld a,(GAME_VARS+0x7)	; 0B52  3A F1 0A
Z_0B55:
	or b	; 0B55  B0
Z_0B56:
	push hl	; 0B56  ED 4B F4 0A
	ld hl,(GAME_VARS+0xA)
	ld b,h
	ld c,l
	pop hl
Z_0B5A:
	jp L_2168	; 0B5A  C3 68 21
L_0B5D:
Z_0B5D:
	ld a,(GAME_VARS+0xE)	; 0B5D  3A F8 0A
Z_0B60:
	or a	; 0B60  B7
Z_0B61:
	jp nz,L_0B69	; 0B61  20 06
L_0B63:
Z_0B63:
	call L_0AE1	; 0B63  CD E1 0A
L_0B66:
Z_0B66:
	jp L_0BB1	; 0B66  C3 B1 0B
L_0B69:
Z_0B69:
	ld d,0x80	; 0B69  16 80
Z_0B6B:
	call L_0D95	; 0B6B  CD 95 0D
Z_0B6E:
	jp nc,L_0B66	; 0B6E  30 F6
Z_0B70:
	call L_0BE9	; 0B70  CD E9 0B
Z_0B73:
	ret	; 0B73  C9
L_0B74:
Z_0B74:
	ld a,(GAME_VARS+0xE)	; 0B74  3A F8 0A
Z_0B77:
	or a	; 0B77  B7
Z_0B78:
	jp z,L_0B69	; 0B78  28 EF
Z_0B7A:
	jp L_0B63	; 0B7A  18 E7
L_0B7C:
Z_0B7C:
	call L_0B40	; 0B7C  CD 40 0B
Z_0B7F:
	jp nz,L_0B87	; 0B7F  20 06
Z_0B81:
	ld a,0x05	; 0B81  3E 05
Z_0B83:
	ld (GAME_VARS+0x7),a	; 0B83  32 F1 0A
Z_0B86:
	ret	; 0B86  C9
L_0B87:
Z_0B87:
	call L_0BBA	; 0B87  CD BA 0B
Z_0B8A:
	ret nc	; 0B8A  D0
Z_0B8B:
	call L_0AE1	; 0B8B  CD E1 0A
Z_0B8E:
	jp L_0BA3	; 0B8E  18 13
L_0B90:
Z_0B90:
	call L_0B40	; 0B90  CD 40 0B
Z_0B93:
	jp z,L_0D41	; 0B93  CA 41 0D
Z_0B96:
	call L_0BA7	; 0B96  CD A7 0B
Z_0B99:
	call L_0AE1	; 0B99  CD E1 0A
Z_0B9C:
	call L_0DBB	; 0B9C  CD BB 0D
Z_0B9F:
	ret z	; 0B9F  C8
Z_0BA0:
	call L_0AE1	; 0BA0  CD E1 0A
L_0BA3:
Z_0BA3:
	ld b,0x04	; 0BA3  06 04
Z_0BA5:
	jp L_0BA9	; 0BA5  18 02
L_0BA7:
Z_0BA7:
	ld b,0xFC	; 0BA7  06 FC
L_0BA9:
Z_0BA9:
	ld a,(GAME_VARS+0xA)	; 0BA9  3A F4 0A
Z_0BAC:
	add a,b	; 0BAC  80
Z_0BAD:
	ld (GAME_VARS+0xA),a	; 0BAD  32 F4 0A
Z_0BB0:
	ret	; 0BB0  C9
L_0BB1:
Z_0BB1:
	xor a	; 0BB1  AF
Z_0BB2:
	ld (GAME_VARS+0x7),a	; 0BB2  32 F1 0A
Z_0BB5:
	inc a	; 0BB5  3C
Z_0BB6:
	ld (GAME_VARS+0xF),a	; 0BB6  32 F9 0A
Z_0BB9:
	ret	; 0BB9  C9
L_0BBA:
Z_0BBA:
	xor a	; 0BBA  AF
Z_0BBB:
	ld d,0x40	; 0BBB  16 40
Z_0BBD:
	jp L_0BCC	; 0BBD  18 0D
L_0BBF:
Z_0BBF:
	push hl	; 0BBF  ED 4B 23 08  ; в каноне +0x100 этот операнд стухший
	ld hl,(OBJ_BLOCK_0809+0x1A)
	ld b,h
	ld c,l
	pop hl
Z_0BC3:
	ld de,0x2002	; 0BC3  11 02 20
Z_0BC6:
	jp L_0BD8	; 0BC6  18 10
L_0BC8:
Z_0BC8:
	ld a,0xDF	; 0BC8  3E DF
Z_0BCA:
	ld d,0x80	; 0BCA  16 80
L_0BCC:
Z_0BCC:
	push hl	; 0BCC  ED 4B F4 0A
	ld hl,(GAME_VARS+0xA)
	ld b,h
	ld c,l
	pop hl
Z_0BD0:
	add a,c	; 0BD0  81
Z_0BD1:
	cp 0x60	; 0BD1  FE 60
Z_0BD3:
	ccf	; 0BD3  3F
Z_0BD4:
	ret c	; 0BD4  D8
Z_0BD5:
	ld c,a	; 0BD5  4F
L_0BD6:
Z_0BD6:
	ld e,0x03	; 0BD6  1E 03
L_0BD8:
Z_0BD8:
	ld a,0x06	; 0BD8  3E 06
Z_0BDA:
	add a,b	; 0BDA  80
Z_0BDB:
	ld b,a	; 0BDB  47
Z_0BDC:
	push bc	; 0BDC  C5
Z_0BDD:
	call ATTR_ADDR	; 0BDD  CD 00 1F
Z_0BE0:
	pop bc	; 0BE0  C1
Z_0BE1:
	ld a,(hl)	; 0BE1  7E
Z_0BE2:
	cp d	; 0BE2  BA
Z_0BE3:
	ret nc	; 0BE3  D0
Z_0BE4:
	dec e	; 0BE4  1D
Z_0BE5:
	jp nz,L_0BD8	; 0BE5  20 F1
Z_0BE7:
	scf	; 0BE7  37
Z_0BE8:
	ret	; 0BE8  C9
L_0BE9:
Z_0BE9:
	ld a,(GAME_VARS+0x7)	; 0BE9  3A F1 0A
Z_0BEC:
	cp 0x05	; 0BEC  FE 05
Z_0BEE:
	jp c,L_0BF2	; 0BEE  38 02
Z_0BF0:
	ld a,0x01	; 0BF0  3E 01
L_0BF2:
Z_0BF2:
	ld b,a	; 0BF2  47
Z_0BF3:
	cp 0x04	; 0BF3  FE 04
Z_0BF5:
	jp nz,L_0BFE	; 0BF5  20 07
Z_0BF7:
	ld a,0xFF	; 0BF7  3E FF
Z_0BF9:
	ld (GAME_VARS+0xF),a	; 0BF9  32 F9 0A
Z_0BFC:
	jp L_0C0A	; 0BFC  18 0C
L_0BFE:
Z_0BFE:
	cp 0x01	; 0BFE  FE 01
Z_0C00:
	jp nz,L_0C07	; 0C00  20 05
Z_0C02:
	ld a,0x01	; 0C02  3E 01
Z_0C04:
	ld (GAME_VARS+0xF),a	; 0C04  32 F9 0A
L_0C07:
Z_0C07:
	ld a,(GAME_VARS+0xF)	; 0C07  3A F9 0A
L_0C0A:
Z_0C0A:
	add a,b	; 0C0A  80
Z_0C0B:
	ld (GAME_VARS+0x7),a	; 0C0B  32 F1 0A
Z_0C0E:
	ld a,(GAME_VARS+0xE)	; 0C0E  3A F8 0A
Z_0C11:
	ld b,0xFD	; 0C11  06 FD
Z_0C13:
	or a	; 0C13  B7
Z_0C14:
	jp z,L_0C18	; 0C14  28 02
Z_0C16:
	ld b,0x03	; 0C16  06 03
L_0C18:
Z_0C18:
	ld a,(GAME_VARS+0xB)	; 0C18  3A F5 0A
Z_0C1B:
	add a,b	; 0C1B  80
Z_0C1C:
	ld (GAME_VARS+0xB),a	; 0C1C  32 F5 0A
Z_0C1F:
	ret	; 0C1F  C9
L_0C20:
Z_0C20:
	ld a,(GAME_VARS+0xE)	; 0C20  3A F8 0A
Z_0C23:
	ld b,0xFE	; 0C23  06 FE
Z_0C25:
	or a	; 0C25  B7
Z_0C26:
	jp z,L_0C18	; 0C26  28 F0
Z_0C28:
	ld b,0x02	; 0C28  06 02
Z_0C2A:
	jp L_0C18	; 0C2A  18 EC
L_0C2C:
Z_0C2C:
	ld hl,D_1D08	; 0C2C  21 08 1D
Z_0C2F:
	ld b,(hl)	; 0C2F  46
Z_0C30:
	inc hl	; 0C30  23
Z_0C31:
	ld c,(hl)	; 0C31  4E
Z_0C32:
	inc hl	; 0C32  23
Z_0C33:
	ld d,(hl)	; 0C33  56
Z_0C34:
	inc hl	; 0C34  23
Z_0C35:
	ld e,(hl)	; 0C35  5E
Z_0C36:
	ld hl,GAME_VARS+0xB	; 0C36  21 F5 0A
Z_0C39:
	ld a,(hl)	; 0C39  7E
Z_0C3A:
	cp 0xA9	; 0C3A  FE A9
Z_0C3C:
	jp c,L_0C54	; 0C3C  38 16
Z_0C3E:
	call L_0C6F	; 0C3E  CD 6F 0C
Z_0C41:
	ld a,(hl)	; 0C41  7E
Z_0C42:
	cp 0xE6	; 0C42  FE E6
Z_0C44:
	jp c,L_0C4F	; 0C44  38 09
Z_0C46:
	ld (hl),0xA8	; 0C46  36 A8
Z_0C48:
	ld a,d	; 0C48  7A
L_0C49:
Z_0C49:
	ld (GAME_VARS+0xC),a	; 0C49  32 F6 0A
Z_0C4C:
	jp L_1F19	; 0C4C  C3 19 1F
L_0C4F:
Z_0C4F:
	ld (hl),0x00	; 0C4F  36 00
Z_0C51:
	ld a,e	; 0C51  7B
Z_0C52:
	jp L_0C49	; 0C52  18 F5
L_0C54:
Z_0C54:
	dec hl	; 0C54  2B
Z_0C55:
	ld a,(hl)	; 0C55  7E
Z_0C56:
	cp 0x20	; 0C56  FE 20
Z_0C58:
	jp c,L_0C65	; 0C58  38 0B
Z_0C5A:
	cp 0x61	; 0C5A  FE 61
Z_0C5C:
	ret c	; 0C5C  D8
Z_0C5D:
	call L_0C6F	; 0C5D  CD 6F 0C
Z_0C60:
	ld (hl),0x20	; 0C60  36 20
Z_0C62:
	ld a,c	; 0C62  79
Z_0C63:
	jp L_0C49	; 0C63  18 E4
L_0C65:
Z_0C65:
	ld (hl),0x20	; 0C65  36 20
Z_0C67:
	call L_0C6F	; 0C67  CD 6F 0C
Z_0C6A:
	ld (hl),0x60	; 0C6A  36 60
L_0C6C:
Z_0C6C:
	ld a,b	; 0C6C  78
Z_0C6D:
	jp L_0C49	; 0C6D  18 DA
L_0C6F:
Z_0C6F:
	push bc	; 0C6F  C5
Z_0C70:
	ld a,(GAME_VARS+0xC)	; 0C70  3A F6 0A
Z_0C73:
	ld b,a	; 0C73  47
Z_0C74:
	ld a,(LEVEL_VARS)	; 0C74  3A 7B 16
Z_0C77:
	cp b	; 0C77  B8
Z_0C78:
	jp nz,L_0C8A	; 0C78  20 10
Z_0C7A:
	push de	; 0C7A  D5
Z_0C7B:
	push hl	; 0C7B  E5
Z_0C7C:
	call L_0F2B	; 0C7C  CD 2B 0F
Z_0C7F:
	xor a	; 0C7F  AF
Z_0C80:
	ld (D_1A23),a	; 0C80  32 23 1A
Z_0C83:
	nop	; 0C83  00
Z_0C84:
	nop	; 0C84  00
Z_0C85:
	nop	; 0C85  00
Z_0C86:
	nop	; 0C86  00
Z_0C87:
	nop	; 0C87  00
Z_0C88:
	pop hl	; 0C88  E1
Z_0C89:
	pop de	; 0C89  D1
L_0C8A:
Z_0C8A:
	pop bc	; 0C8A  C1
Z_0C8B:
	ret	; 0C8B  C9
L_0C8C:
Z_0C8C:
	call L_0F47	; 0C8C  CD 47 0F
Z_0C8F:
	xor a	; 0C8F  AF
Z_0C90:
	ld (GAME_VARS),a	; 0C90  32 EA 0A
Z_0C93:
	ret	; 0C93  C9
D_0C94:
Z_0C94:
	db	0x00,0x00,0x00	; 0C94
Z_0C97:
	call L_0F47	; 0C97  CD 47 0F  ; в каноне +0x100 этот операнд стухший
Z_0C9A:
	xor a	; 0C9A  AF
Z_0C9B:
	ld (GAME_VARS),a	; 0C9B  32 EA 0A  ; в каноне +0x100 этот операнд стухший
Z_0C9E:
	ret	; 0C9E  C9
L_0C9F:
Z_0C9F:
	ld a,(OBJ_BLOCK_0809)	; 0C9F  3A 09 08
Z_0CA2:
	or a	; 0CA2  B7
Z_0CA3:
	ret nz	; 0CA3  C0
Z_0CA4:
	call L_0B40	; 0CA4  CD 40 0B
Z_0CA7:
	ret nz	; 0CA7  C0
L_0CA8:
Z_0CA8:
	inc a	; 0CA8  3C
Z_0CA9:
	ld (GAME_VARS+0x5),a	; 0CA9  32 EF 0A
Z_0CAC:
	cp 0x05	; 0CAC  FE 05
Z_0CAE:
	jp z,L_0CE8	; 0CAE  28 38
Z_0CB0:
	ld b,0x08	; 0CB0  06 08
Z_0CB2:
	cp 0x02	; 0CB2  FE 02
Z_0CB4:
	jp c,L_0CE3	; 0CB4  38 2D
Z_0CB6:
	cp 0x03	; 0CB6  FE 03
Z_0CB8:
	jp nc,L_0CE3	; 0CB8  30 29
Z_0CBA:
	inc b	; 0CBA  04
Z_0CBB:
	cp 0x03	; 0CBB  FE 03
Z_0CBD:
	jp z,L_0CE3	; 0CBD  28 24
Z_0CBF:
	ld (OBJ_BLOCK_0809),a	; 0CBF  32 09 08
Z_0CC2:
	ld a,0x1C	; 0CC2  3E 1C
Z_0CC4:
	ld (OBJ_BLOCK_0809+0x6),a	; 0CC4  32 0F 08
Z_0CC7:
	ld a,(GAME_VARS+0xC)	; 0CC7  3A F6 0A
Z_0CCA:
	ld (OBJ_BLOCK_0809+0x1),a	; 0CCA  32 0A 08
Z_0CCD:
	ld a,(GAME_VARS+0xE)	; 0CCD  3A F8 0A
Z_0CD0:
	ld (OBJ_BLOCK_0809+0x7),a	; 0CD0  32 10 08
Z_0CD3:
	ld d,0xF8	; 0CD3  16 F8
Z_0CD5:
	or a	; 0CD5  B7
Z_0CD6:
	jp z,L_0CDA	; 0CD6  28 02
Z_0CD8:
	ld d,0x10	; 0CD8  16 10
L_0CDA:
Z_0CDA:
	ld hl,(GAME_VARS+0xA)	; 0CDA  2A F4 0A
Z_0CDD:
	ld e,0xF6	; 0CDD  1E F6
Z_0CDF:
	add hl,de	; 0CDF  19
Z_0CE0:
	ld (OBJ_BLOCK_0809+0x4),hl	; 0CE0  22 0D 08
L_0CE3:
Z_0CE3:
	ld a,b	; 0CE3  78
Z_0CE4:
	ld (GAME_VARS+0x7),a	; 0CE4  32 F1 0A
Z_0CE7:
	ret	; 0CE7  C9
L_0CE8:
Z_0CE8:
	xor a	; 0CE8  AF
Z_0CE9:
	ld (GAME_VARS+0x5),a	; 0CE9  32 EF 0A
Z_0CEC:
	jp L_0BB1	; 0CEC  C3 B1 0B
L_0CEF:
Z_0CEF:
	call L_0BA3	; 0CEF  CD A3 0B
Z_0CF2:
	ld a,(GAME_VARS+0x3)	; 0CF2  3A ED 0A
Z_0CF5:
	inc a	; 0CF5  3C
Z_0CF6:
	ld (GAME_VARS+0x3),a	; 0CF6  32 ED 0A
Z_0CF9:
	ld a,(GAME_VARS+0x2)	; 0CF9  3A EC 0A
Z_0CFC:
	or a	; 0CFC  B7
Z_0CFD:
	jp z,L_0D18	; 0CFD  28 19
Z_0CFF:
	dec a	; 0CFF  3D
Z_0D00:
	ld (GAME_VARS+0x2),a	; 0D00  32 EC 0A
Z_0D03:
	or a	; 0D03  B7
Z_0D04:
	jp z,L_0D14	; 0D04  28 0E
Z_0D06:
	ld a,(GAME_VARS+0x1)	; 0D06  3A EB 0A
Z_0D09:
	or a	; 0D09  B7
Z_0D0A:
	jp z,L_0D14	; 0D0A  28 08
Z_0D0C:
	ld d,0x40	; 0D0C  16 40
Z_0D0E:
	call L_0D95	; 0D0E  CD 95 0D
Z_0D11:
	call c,L_0C20	; 0D11  DC 20 0C
L_0D14:
Z_0D14:
	ld a,0x07	; 0D14  3E 07
Z_0D16:
	jp L_0D21	; 0D16  18 09
L_0D18:
Z_0D18:
	ld (GAME_VARS+0x1),a	; 0D18  32 EB 0A
Z_0D1B:
	inc a	; 0D1B  3C
Z_0D1C:
	ld (GAME_VARS+0x2),a	; 0D1C  32 EC 0A
Z_0D1F:
	ld a,0x06	; 0D1F  3E 06
L_0D21:
Z_0D21:
	ld (GAME_VARS+0x7),a	; 0D21  32 F1 0A
Z_0D24:
	ret	; 0D24  C9
L_0D25:
Z_0D25:
	cp 0x07	; 0D25  FE 07
Z_0D27:
	jp z,L_0D61	; 0D27  28 38
Z_0D29:
	inc a	; 0D29  3C
Z_0D2A:
	ld (GAME_VARS+0x6),a	; 0D2A  32 F0 0A
Z_0D2D:
	call L_0BC8	; 0D2D  CD C8 0B
Z_0D30:
	call c,L_0BA7	; 0D30  DC A7 0B
Z_0D33:
	ld a,(GAME_VARS+0x1)	; 0D33  3A EB 0A
Z_0D36:
	or a	; 0D36  B7
Z_0D37:
	ret z	; 0D37  C8
Z_0D38:
	ld d,0x40	; 0D38  16 40
Z_0D3A:
	call L_0D95	; 0D3A  CD 95 0D
Z_0D3D:
	call c,L_0C20	; 0D3D  DC 20 0C
Z_0D40:
	ret	; 0D40  C9
L_0D41:
Z_0D41:
	xor a	; 0D41  AF
Z_0D42:
	ld (GAME_VARS+0x9),a	; 0D42  32 F3 0A
Z_0D45:
	inc a	; 0D45  3C
Z_0D46:
	ld (GAME_VARS+0x6),a	; 0D46  32 F0 0A
Z_0D49:
	ld a,(GAME_VARS+0x4)	; 0D49  3A EE 0A
Z_0D4C:
	ld b,0x00	; 0D4C  06 00
Z_0D4E:
	or a	; 0D4E  B7
Z_0D4F:
	jp z,L_0D57	; 0D4F  28 06
Z_0D51:
	cp 0x05	; 0D51  FE 05
Z_0D53:
	jp nc,L_0D57	; 0D53  30 02
Z_0D55:
	ld b,0x01	; 0D55  06 01
L_0D57:
Z_0D57:
	ld a,b	; 0D57  78
Z_0D58:
	ld (GAME_VARS+0x1),a	; 0D58  32 EB 0A
Z_0D5B:
	ld a,0x06	; 0D5B  3E 06
Z_0D5D:
	ld (GAME_VARS+0x7),a	; 0D5D  32 F1 0A
Z_0D60:
	ret	; 0D60  C9
L_0D61:
Z_0D61:
	ld (GAME_VARS+0x2),a	; 0D61  32 EC 0A
L_0D64:
Z_0D64:
	ld (GAME_VARS+0x9),a	; 0D64  32 F3 0A
Z_0D67:
	xor a	; 0D67  AF
Z_0D68:
	ld (GAME_VARS+0x6),a	; 0D68  32 F0 0A
Z_0D6B:
	ret	; 0D6B  C9
L_0D6C:
Z_0D6C:
	or a	; 0D6C  B7
Z_0D6D:
	jp nz,L_0D74	; 0D6D  20 05
Z_0D6F:
	ld a,0xFA	; 0D6F  3E FA
Z_0D71:
	ld d,a	; 0D71  57
Z_0D72:
	jp L_0D79	; 0D72  18 05
L_0D74:
Z_0D74:
	ld a,0x10	; 0D74  3E 10
Z_0D76:
	add a,e	; 0D76  83
Z_0D77:
	ld d,0x06	; 0D77  16 06
L_0D79:
Z_0D79:
	push bc	; 0D79  C5
Z_0D7A:
	add a,b	; 0D7A  80
Z_0D7B:
	cp 0xBC	; 0D7B  FE BC
Z_0D7D:
	jp nc,L_0D8E	; 0D7D  30 0F
Z_0D7F:
	ld b,a	; 0D7F  47
Z_0D80:
	ld a,c	; 0D80  79
Z_0D81:
	sub 0x04	; 0D81  D6 04
Z_0D83:
	ld c,a	; 0D83  4F
Z_0D84:
	call ATTR_ADDR	; 0D84  CD 00 1F  ; в каноне +0x100 этот операнд стухший
Z_0D87:
	nop	; 0D87  00
Z_0D88:
	nop	; 0D88  00
Z_0D89:
	nop	; 0D89  00
Z_0D8A:
	nop	; 0D8A  00
Z_0D8B:
	ld a,(hl)	; 0D8B  7E
Z_0D8C:
	cp 0x80	; 0D8C  FE 80
L_0D8E:
Z_0D8E:
	call il_exaf	; 0D8E  08
Z_0D8F:
	pop bc	; 0D8F  C1
Z_0D90:
	ld a,b	; 0D90  78
Z_0D91:
	add a,d	; 0D91  82
Z_0D92:
	ld b,a	; 0D92  47
Z_0D93:
	call il_exaf	; 0D93  08
Z_0D94:
	ret	; 0D94  C9
L_0D95:
Z_0D95:
	push hl	; 0D95  ED 4B F4 0A
	ld hl,(GAME_VARS+0xA)
	ld b,h
	ld c,l
	pop hl
Z_0D99:
	ld a,(GAME_VARS+0xE)	; 0D99  3A F8 0A
Z_0D9C:
	or a	; 0D9C  B7
Z_0D9D:
	jp z,L_0DA3	; 0D9D  28 04
Z_0D9F:
	ld a,0x16	; 0D9F  3E 16
Z_0DA1:
	jp L_0DA5	; 0DA1  18 02
L_0DA3:
Z_0DA3:
	ld a,0x02	; 0DA3  3E 02
L_0DA5:
Z_0DA5:
	add a,b	; 0DA5  80
Z_0DA6:
	ld b,a	; 0DA6  47
Z_0DA7:
	dec c	; 0DA7  0D
Z_0DA8:
	ld e,0x04	; 0DA8  1E 04
L_0DAA:
Z_0DAA:
	push bc	; 0DAA  C5
Z_0DAB:
	call ATTR_ADDR	; 0DAB  CD 00 1F
Z_0DAE:
	pop bc	; 0DAE  C1
Z_0DAF:
	ld a,(hl)	; 0DAF  7E
Z_0DB0:
	cp d	; 0DB0  BA
Z_0DB1:
	ret nc	; 0DB1  D0
Z_0DB2:
	ld a,c	; 0DB2  79
Z_0DB3:
	sub 0x08	; 0DB3  D6 08
Z_0DB5:
	ld c,a	; 0DB5  4F
Z_0DB6:
	dec e	; 0DB6  1D
Z_0DB7:
	jp nz,L_0DAA	; 0DB7  20 F1
Z_0DB9:
	scf	; 0DB9  37
Z_0DBA:
	ret	; 0DBA  C9
L_0DBB:
Z_0DBB:
	push hl	; 0DBB  ED 4B F4 0A
	ld hl,(GAME_VARS+0xA)
	ld b,h
	ld c,l
	pop hl
Z_0DBF:
	xor a	; 0DBF  AF
Z_0DC0:
	ld (GAME_VARS+0xD),a	; 0DC0  32 F7 0A
Z_0DC3:
	ld a,c	; 0DC3  79
Z_0DC4:
	sub 0x1C	; 0DC4  D6 1C
Z_0DC6:
	ld c,a	; 0DC6  4F
Z_0DC7:
	ld e,0x03	; 0DC7  1E 03
L_0DC9:
Z_0DC9:
	ld a,b	; 0DC9  78
Z_0DCA:
	add a,0x06	; 0DCA  C6 06
Z_0DCC:
	ld b,a	; 0DCC  47
Z_0DCD:
	push bc	; 0DCD  C5
Z_0DCE:
	call ATTR_ADDR	; 0DCE  CD 00 1F
Z_0DD1:
	pop bc	; 0DD1  C1
Z_0DD2:
	ld a,(hl)	; 0DD2  7E
Z_0DD3:
	cpl	; 0DD3  2F
Z_0DD4:
	and 0x20	; 0DD4  E6 20
Z_0DD6:
	ret nz	; 0DD6  C0
Z_0DD7:
	dec e	; 0DD7  1D
Z_0DD8:
	jp nz,L_0DC9	; 0DD8  20 EF
Z_0DDA:
	ld a,0x0A	; 0DDA  3E 0A
Z_0DDC:
	ld (GAME_VARS+0x7),a	; 0DDC  32 F1 0A
Z_0DDF:
	ld (GAME_VARS+0xD),a	; 0DDF  32 F7 0A
Z_0DE2:
	ret	; 0DE2  C9
L_0DE3:
Z_0DE3:
	ld a,(GAME_VARS+0xC)	; 0DE3  3A F6 0A
Z_0DE6:
	cp 0x04	; 0DE6  FE 04
Z_0DE8:
	jp z,L_0E24	; 0DE8  28 3A
Z_0DEA:
	cp 0x0D	; 0DEA  FE 0D
Z_0DEC:
	jp z,L_0E3B	; 0DEC  28 4D
Z_0DEE:
	cp 0x18	; 0DEE  FE 18
Z_0DF0:
	jp z,L_0E4D	; 0DF0  28 5B
Z_0DF2:
	cp 0x1F	; 0DF2  FE 1F
Z_0DF4:
	jp z,L_0E64	; 0DF4  28 6E
Z_0DF6:
	cp 0x3D	; 0DF6  FE 3D
Z_0DF8:
	jp z,L_0E83	; 0DF8  CA 83 0E
Z_0DFB:
	cp 0x4A	; 0DFB  FE 4A
Z_0DFD:
	jp z,L_0EAB	; 0DFD  CA AB 0E
Z_0E00:
	cp 0x4C	; 0E00  FE 4C
Z_0E02:
	jp z,L_0EE0	; 0E02  CA E0 0E
Z_0E05:
	cp 0x56	; 0E05  FE 56
Z_0E07:
	jp z,L_0F0D	; 0E07  CA 0D 0F
Z_0E0A:
	cp 0x50	; 0E0A  FE 50
Z_0E0C:
	ret nz	; 0E0C  C0
Z_0E0D:
	ld hl,ROOM_MAPS+0x2105	; 0E0D  21 4C 89
Z_0E10:
	call L_0F5D	; 0E10  CD 5D 0F
Z_0E13:
	ret c	; 0E13  D8
Z_0E14:
	ld a,0x1E	; 0E14  3E 1E
Z_0E16:
	ld (ROOM_MAPS+0x2090),a	; 0E16  32 D7 88
Z_0E19:
	ld hl,0x2F80	; 0E19  21 80 2F
Z_0E1C:
	ld b,0x20	; 0E1C  06 20
Z_0E1E:
	call L_0FA7	; 0E1E  CD A7 0F
Z_0E21:
	jp L_1907	; 0E21  C3 07 19
L_0E24:
Z_0E24:
	ld hl,ROOM_MAPS+0x201	; 0E24  21 48 6A
Z_0E27:
	call L_0F5D	; 0E27  CD 5D 0F
Z_0E2A:
	ret c	; 0E2A  D8
Z_0E2B:
	ld a,0x21	; 0E2B  3E 21
Z_0E2D:
	ld (ROOM_MAPS+0x180),a	; 0E2D  32 C7 69
Z_0E30:
	ld hl,0x2F28	; 0E30  21 28 2F
Z_0E33:
	ld b,0x20	; 0E33  06 20
Z_0E35:
	call L_0FA7	; 0E35  CD A7 0F
Z_0E38:
	jp L_1907	; 0E38  C3 07 19
L_0E3B:
Z_0E3B:
	ld hl,ROOM_MAPS+0x597	; 0E3B  21 DE 6D
Z_0E3E:
	call L_0F5D	; 0E3E  CD 5D 0F
Z_0E41:
	ret c	; 0E41  D8
Z_0E42:
	ld a,0x28	; 0E42  3E 28
Z_0E44:
	ld (ROOM_MAPS+0x7B6),a	; 0E44  32 FD 6F
L_0E47:
Z_0E47:
	call SFX_64D7_x25	; 0E47  CD F2 1F
Z_0E4A:
	jp SFX_64D7_x25	; 0E4A  C3 F2 1F
L_0E4D:
Z_0E4D:
	ld hl,ROOM_MAPS+0xA65	; 0E4D  21 AC 72
Z_0E50:
	call L_0F5D	; 0E50  CD 5D 0F
Z_0E53:
	ret c	; 0E53  D8
Z_0E54:
	ld a,0x1E	; 0E54  3E 1E
Z_0E56:
	ld (ROOM_MAPS+0x9F8),a	; 0E56  32 3F 72
Z_0E59:
	ld hl,0x1778	; 0E59  21 78 17
Z_0E5C:
	ld b,0x38	; 0E5C  06 38
Z_0E5E:
	call L_0FA7	; 0E5E  CD A7 0F
Z_0E61:
	jp L_1907	; 0E61  C3 07 19
L_0E64:
Z_0E64:
	ld hl,ROOM_MAPS+0xD67	; 0E64  21 AE 75
Z_0E67:
	call L_0F5D	; 0E67  CD 5D 0F
Z_0E6A:
	ret c	; 0E6A  D8
Z_0E6B:
	ld a,0x1D	; 0E6B  3E 1D
Z_0E6D:
	ld (ROOM_MAPS+0xC7C),a	; 0E6D  32 C3 74
Z_0E70:
	ld a,(LEVEL_VARS)	; 0E70  3A 7B 16
Z_0E73:
	cp 0x1E	; 0E73  FE 1E
Z_0E75:
	jp nz,SFX_64D7_x25	; 0E75  C2 F2 1F
Z_0E78:
	ld hl,0x6880	; 0E78  21 80 68
Z_0E7B:
	ld b,0x47	; 0E7B  06 47
Z_0E7D:
	call L_0FA7	; 0E7D  CD A7 0F
Z_0E80:
	jp L_1907	; 0E80  C3 07 19
L_0E83:
Z_0E83:
	ld hl,ROOM_MAPS+0x1933	; 0E83  21 7A 81
Z_0E86:
	call L_0F5D	; 0E86  CD 5D 0F
Z_0E89:
	ret c	; 0E89  D8
L_0E8A:
Z_0E8A:
	ld a,0x12	; 0E8A  3E 12
Z_0E8C:
	ld (ROOM_MAPS+0x1992),a	; 0E8C  32 D9 81
Z_0E8F:
	ld a,0x14	; 0E8F  3E 14
Z_0E91:
	ld (ROOM_MAPS+0x19F8),a	; 0E91  32 3F 82
Z_0E94:
	call SFX_64D7_x25	; 0E94  CD F2 1F
Z_0E97:
	jp L_1907	; 0E97  C3 07 19
L_0E9A:
Z_0E9A:
	ld de,ROOM_MAPS+0x1DF3	; 0E9A  11 3A 86
Z_0E9D:
	ld hl,D_1D08+0x4	; 0E9D  21 0C 1D
Z_0EA0:
	ld bc,0x08	; 0EA0  01 08 00
Z_0EA3:
	call il_ldir	; 0EA3  ED B0
Z_0EA5:
	call SFX_64D7	; 0EA5  CD DA 1F
Z_0EA8:
	jp L_1907	; 0EA8  C3 07 19
L_0EAB:
Z_0EAB:
	ld hl,ROOM_MAPS+0x1E3D	; 0EAB  21 84 86
Z_0EAE:
	call L_0F5D	; 0EAE  CD 5D 0F
Z_0EB1:
	jp nc,L_0E9A	; 0EB1  30 E7
Z_0EB3:
	ld hl,ROOM_MAPS+0x1E39	; 0EB3  21 80 86
Z_0EB6:
	call L_0F5D	; 0EB6  CD 5D 0F
Z_0EB9:
	jp nc,L_0ED0	; 0EB9  30 15
Z_0EBB:
	ld hl,ROOM_MAPS+0x1E35	; 0EBB  21 7C 86
Z_0EBE:
	call L_0F5D	; 0EBE  CD 5D 0F
Z_0EC1:
	ret c	; 0EC1  D8
Z_0EC2:
	ld a,0x14	; 0EC2  3E 14
Z_0EC4:
	ld (ROOM_MAPS+0x1E00),a	; 0EC4  32 47 86
Z_0EC7:
	ld hl,0x4950	; 0EC7  21 50 49
Z_0ECA:
	call L_0374	; 0ECA  CD 74 03
Z_0ECD:
	jp L_1907	; 0ECD  C3 07 19
L_0ED0:
Z_0ED0:
	ld hl,0x0120	; 0ED0  21 20 01
Z_0ED3:
	ld a,0x06	; 0ED3  3E 06
Z_0ED5:
	call L_1019	; 0ED5  CD 19 10
Z_0ED8:
	ld a,0x36	; 0ED8  3E 36
Z_0EDA:
	ld (ROOM_MAPS+0x1E39),a	; 0EDA  32 80 86
Z_0EDD:
	jp L_0F25	; 0EDD  C3 25 0F
L_0EE0:
Z_0EE0:
	ld hl,ROOM_MAPS+0x1F1D	; 0EE0  21 64 87
Z_0EE3:
	call L_0F5D	; 0EE3  CD 5D 0F
Z_0EE6:
	jp nc,L_0EFD	; 0EE6  30 15
Z_0EE8:
	ld hl,ROOM_MAPS+0x1F19	; 0EE8  21 60 87
Z_0EEB:
	call L_0F5D	; 0EEB  CD 5D 0F
Z_0EEE:
	ret c	; 0EEE  D8
Z_0EEF:
	ld a,0x22	; 0EEF  3E 22
Z_0EF1:
	ld (ROOM_MAPS+0x1EBC),a	; 0EF1  32 03 87
Z_0EF4:
	ld hl,0x4A18	; 0EF4  21 18 4A
Z_0EF7:
	call L_0374	; 0EF7  CD 74 03
Z_0EFA:
	jp L_1907	; 0EFA  C3 07 19
L_0EFD:
Z_0EFD:
	ld hl,0x0910	; 0EFD  21 10 09
Z_0F00:
	ld a,0x07	; 0F00  3E 07
Z_0F02:
	call L_1019	; 0F02  CD 19 10
Z_0F05:
	ld a,0x36	; 0F05  3E 36
Z_0F07:
	ld (ROOM_MAPS+0x1F1D),a	; 0F07  32 64 87
Z_0F0A:
	jp L_0F25	; 0F0A  C3 25 0F
L_0F0D:
Z_0F0D:
	ld hl,0x6360	; 0F0D  21 60 63
Z_0F10:
	ld bc,0x0205	; 0F10  01 05 02
Z_0F13:
	ld a,0xF1	; 0F13  3E F1
Z_0F15:
	call L_1828	; 0F15  CD 28 18
Z_0F18:
	call L_13D5	; 0F18  CD D5 13
Z_0F1B:
	nop	; 0F1B  00
Z_0F1C:
	nop	; 0F1C  00
Z_0F1D:
	nop	; 0F1D  00
Z_0F1E:
	ld a,(L_122C+0x1)	; 0F1E  3A 2D 12
Z_0F21:
	ld b,a	; 0F21  47
Z_0F22:
	call L_0AD5	; 0F22  CD D5 0A
L_0F25:
Z_0F25:
	ld a,0x01	; 0F25  3E 01
L_0F27:
Z_0F27:
	ld (L_0837+0x1),a	; 0F27  32 38 08
Z_0F2A:
	ret	; 0F2A  C9
L_0F2B:
Z_0F2B:
	call L_1DF7	; 0F2B  CD F7 1D
L_0F2E:
Z_0F2E:
	ld a,(LEVEL_VARS)	; 0F2E  3A 7B 16
Z_0F31:
	add a,0x80	; 0F31  C6 80
Z_0F33:
	ld b,a	; 0F33  47
Z_0F34:
	call L_1A84	; 0F34  CD 84 1A
Z_0F37:
	ld a,(GAME_VARS+0xC)	; 0F37  3A F6 0A
Z_0F3A:
	call L_1A6C	; 0F3A  CD 6C 1A
Z_0F3D:
	ld de,D_1D08	; 0F3D  11 08 1D
Z_0F40:
	ld c,0x04	; 0F40  0E 04
Z_0F42:
	call il_ldir	; 0F42  ED B0
Z_0F44:
	jp L_1F9F	; 0F44  C3 9F 1F
L_0F47:
Z_0F47:
	call L_1DF1	; 0F47  CD F1 1D
L_0F4A:
Z_0F4A:
	ld a,(GAME_VARS+0xC)	; 0F4A  3A F6 0A
Z_0F4D:
	ld hl,WORK_RAM+0x111	; 0F4D  21 B9 3B  ; в каноне +0x100 этот операнд стухший
Z_0F50:
	ld c,a	; 0F50  4F
Z_0F51:
	ld b,0x00	; 0F51  06 00
Z_0F53:
	add hl,bc	; 0F53  09
Z_0F54:
	ld (hl),0x80	; 0F54  36 80
Z_0F56:
	ld b,a	; 0F56  47
Z_0F57:
	call L_1A84	; 0F57  CD 84 1A
Z_0F5A:
	jp L_1F92	; 0F5A  C3 92 1F
L_0F5D:
Z_0F5D:
	ld a,(hl)	; 0F5D  7E
Z_0F5E:
	and 0x80	; 0F5E  E6 80
Z_0F60:
	jp z,L_0F64	; 0F60  28 02
Z_0F62:
	scf	; 0F62  37
Z_0F63:
	ret	; 0F63  C9
L_0F64:
Z_0F64:
	ld a,(GAME_VARS+0xB)	; 0F64  3A F5 0A
Z_0F67:
	inc hl	; 0F67  23
Z_0F68:
	inc hl	; 0F68  23
Z_0F69:
	sub 0x08	; 0F69  D6 08
Z_0F6B:
	cp (hl)	; 0F6B  BE
Z_0F6C:
	ccf	; 0F6C  3F
Z_0F6D:
	ret c	; 0F6D  D8
Z_0F6E:
	add a,0x0E	; 0F6E  C6 0E
Z_0F70:
	cp (hl)	; 0F70  BE
Z_0F71:
	ret c	; 0F71  D8
Z_0F72:
	dec hl	; 0F72  2B
Z_0F73:
	ld a,(GAME_VARS+0xA)	; 0F73  3A F4 0A
Z_0F76:
	sub 0x22	; 0F76  D6 22
Z_0F78:
	cp (hl)	; 0F78  BE
Z_0F79:
	ccf	; 0F79  3F
Z_0F7A:
	ret c	; 0F7A  D8
Z_0F7B:
	add a,0x06	; 0F7B  C6 06
Z_0F7D:
	cp (hl)	; 0F7D  BE
Z_0F7E:
	ret c	; 0F7E  D8
Z_0F7F:
	dec hl	; 0F7F  2B
Z_0F80:
	ld (hl),0xB6	; 0F80  36 B6
Z_0F82:
	call L_23CF	; 0F82  CD CF 23
Z_0F85:
	jp L_2424	; 0F85  C3 24 24
Z_0F88:
	ret z	; 0F88  C8
Z_0F89:
	nop	; 0F89  00
L_0F8A:
Z_0F8A:
	push bc	; 0F8A  C5
Z_0F8B:
	push hl	; 0F8B  E5
Z_0F8C:
	ld de,0x01	; 0F8C  11 01 00
Z_0F8F:
	call RET_STUB	; 0F8F  CD F8 1C  ; в каноне +0x100 этот операнд стухший
Z_0F92:
	pop hl	; 0F92  E1
Z_0F93:
	inc hl	; 0F93  23
Z_0F94:
	pop bc	; 0F94  C1
Z_0F95:
	dec b	; 0F95  10 F3
	jp nz,L_0F8A
Z_0F97:
	ret	; 0F97  C9
L_0F98:
Z_0F98:
	ld a,(GAME_VARS+0xC)	; 0F98  3A F6 0A
Z_0F9B:
	ld d,a	; 0F9B  57
Z_0F9C:
	ld a,(LEVEL_VARS)	; 0F9C  3A 7B 16
Z_0F9F:
	cp d	; 0F9F  BA
Z_0FA0:
	jp z,L_0FA4	; 0FA0  28 02
Z_0FA2:
	xor a	; 0FA2  AF
Z_0FA3:
	ret	; 0FA3  C9
L_0FA4:
Z_0FA4:
	ld a,0x0C	; 0FA4  3E 0C
Z_0FA6:
	ret	; 0FA6  C9
L_0FA7:
Z_0FA7:
	ld c,0x20	; 0FA7  0E 20
Z_0FA9:
	push bc	; 0FA9  C5
Z_0FAA:
	call L_1F3F	; 0FAA  CD 3F 1F
Z_0FAD:
	ld (D_1D08+0xC),a	; 0FAD  32 14 1D
Z_0FB0:
	ld a,b	; 0FB0  78
Z_0FB1:
	ld (L_0FEB+0x1),a	; 0FB1  32 EC 0F
Z_0FB4:
	rlca	; 0FB4  07
Z_0FB5:
	ld (L_0FD6+0x1),a	; 0FB5  32 D7 0F
Z_0FB8:
	ld b,l	; 0FB8  45
Z_0FB9:
	ld c,h	; 0FB9  4C
Z_0FBA:
	call SCR_ADDR_BIT14	; 0FBA  CD 70 1B
Z_0FBD:
	ld (L_0FE3+0x1),hl	; 0FBD  22 E4 0F
Z_0FC0:
	ld a,(D_1D08+0xC)	; 0FC0  3A 14 1D
Z_0FC3:
	add a,h	; 0FC3  84
Z_0FC4:
	ld h,a	; 0FC4  67
Z_0FC5:
	ld (L_0FF4+0x1),hl	; 0FC5  22 F5 0F
Z_0FC8:
	pop bc	; 0FC8  C1
Z_0FC9:
	push bc	; 0FC9  C5
Z_0FCA:
	ld c,0x02	; 0FCA  0E 02
Z_0FCC:
	ld de,WORK_RAM+0x3E5	; 0FCC  11 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_0FCF:
	call VDP_RD_STRIDE8	; 0FCF  CD B4 1C
Z_0FD2:
	pop bc	; 0FD2  C1
L_0FD3:
Z_0FD3:
	push bc	; 0FD3  C5
Z_0FD4:
	ld b,0x00	; 0FD4  06 00
L_0FD6:
Z_0FD6:
	ld c,0x00	; 0FD6  0E 00
Z_0FD8:
	ld hl,WORK_RAM+0x3E7	; 0FD8  21 8F 3E  ; в каноне +0x100 этот операнд стухший
Z_0FDB:
	ld de,WORK_RAM+0x3E5	; 0FDB  11 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_0FDE:
	call il_ldir	; 0FDE  ED B0
Z_0FE0:
	call L_1F36	; 0FE0  CD 36 1F
L_0FE3:
Z_0FE3:
	ld hl,0x00	; 0FE3  21 00 00
Z_0FE6:
	ld de,WORK_RAM+0x3E5	; 0FE6  11 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_0FE9:
	ld c,0x02	; 0FE9  0E 02
L_0FEB:
Z_0FEB:
	ld b,0x00	; 0FEB  06 00
Z_0FED:
	push bc	; 0FED  C5
Z_0FEE:
	call VDP_WR_STRIDE8	; 0FEE  CD 1D 1B
Z_0FF1:
	ld de,WORK_RAM+0x3E5	; 0FF1  11 8D 3E  ; в каноне +0x100 этот операнд стухший
L_0FF4:
Z_0FF4:
	ld hl,0x00	; 0FF4  21 00 00
Z_0FF7:
	pop bc	; 0FF7  C1
Z_0FF8:
	call VDP_WR_STRIDE8	; 0FF8  CD 1D 1B
Z_0FFB:
	call SFX_64D7	; 0FFB  CD DA 1F
Z_0FFE:
	pop bc	; 0FFE  C1
Z_0FFF:
	dec c	; 0FFF  0D
Z_1000:
	jp nz,L_0FD3	; 1000  20 D1
Z_1002:
	call SFX_64F5	; 1002  CD 9A 20
Z_1005:
	call L_0F4A	; 1005  CD 4A 0F
Z_1008:
	jp L_0F2E	; 1008  C3 2E 0F
D_100B:
Z_100B:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 100B
L_1019:
Z_1019:
	ld (L_1084+0x1),a	; 1019  32 85 10
Z_101C:
	ld (L_104B+0x1),a	; 101C  32 4C 10
Z_101F:
	ld (L_103B+0x1),a	; 101F  32 3C 10
Z_1022:
	ld (L_1077+0x1),a	; 1022  32 78 10
Z_1025:
	call L_1F3F	; 1025  CD 3F 1F
Z_1028:
	ld (D_1D08+0xC),a	; 1028  32 14 1D
Z_102B:
	ld b,l	; 102B  45
Z_102C:
	ld c,h	; 102C  4C
Z_102D:
	call SCR_ADDR_BIT14	; 102D  CD 70 1B
Z_1030:
	ld (L_1071+0x1),hl	; 1030  22 72 10
Z_1033:
	ld a,(D_1D08+0xC)	; 1033  3A 14 1D
Z_1036:
	add a,h	; 1036  84
Z_1037:
	ld h,a	; 1037  67
Z_1038:
	ld (L_107E+0x1),hl	; 1038  22 7F 10
L_103B:
Z_103B:
	ld c,0x00	; 103B  0E 00
Z_103D:
	ld b,0x45	; 103D  06 45
Z_103F:
	ld de,WORK_RAM+0x3EC	; 103F  11 94 3E  ; в каноне +0x100 этот операнд стухший
Z_1042:
	call VDP_RD_STRIDE8	; 1042  CD B4 1C
Z_1045:
	ex de,hl	; 1045  EB
Z_1046:
	dec hl	; 1046  2B
Z_1047:
	ld (L_1068+0x1),hl	; 1047  22 69 10
Z_104A:
	push hl	; 104A  E5
L_104B:
Z_104B:
	ld de,0x00	; 104B  11 00 00
Z_104E:
	and a	; 104E  A7
Z_104F:
	ld a,l	; 104F  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
Z_1051:
	ld (L_1065+0x1),hl	; 1051  22 66 10
Z_1054:
	pop hl	; 1054  E1
Z_1055:
	ld de,WORK_RAM+0x3EC	; 1055  11 94 3E  ; в каноне +0x100 этот операнд стухший
Z_1058:
	and a	; 1058  A7
Z_1059:
	ld a,l	; 1059  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
	jp nz,il_AS1
	jp c,il_ASC2
	ld a,l
	or a
	jp il_AS1
il_ASC2:
	ld a,l
	or a
	scf
il_AS1:
Z_105B:
	ld (L_1062+0x1),hl	; 105B  22 63 10
Z_105E:
	ld bc,0x4530	; 105E  01 30 45
L_1061:
Z_1061:
	push bc	; 1061  C5
L_1062:
Z_1062:
	ld bc,0x00	; 1062  01 00 00
L_1065:
Z_1065:
	ld hl,0x00	; 1065  21 00 00
L_1068:
Z_1068:
	ld de,0x00	; 1068  11 00 00
Z_106B:
	call il_lddr	; 106B  ED B8
Z_106D:
	ex de,hl	; 106D  EB
Z_106E:
	call L_1F36	; 106E  CD 36 1F
L_1071:
Z_1071:
	ld hl,0x00	; 1071  21 00 00
Z_1074:
	ld de,WORK_RAM+0x3EC	; 1074  11 94 3E  ; в каноне +0x100 этот операнд стухший
L_1077:
Z_1077:
	ld c,0x00	; 1077  0E 00
Z_1079:
	ld b,0x45	; 1079  06 45
Z_107B:
	call VDP_WR_STRIDE8	; 107B  CD 1D 1B
L_107E:
Z_107E:
	ld hl,0x00	; 107E  21 00 00
Z_1081:
	ld de,WORK_RAM+0x3EC	; 1081  11 94 3E  ; в каноне +0x100 этот операнд стухший
L_1084:
Z_1084:
	ld c,0x00	; 1084  0E 00
Z_1086:
	ld b,0x45	; 1086  06 45
Z_1088:
	call VDP_WR_STRIDE8	; 1088  CD 1D 1B
Z_108B:
	call SFX_64D7	; 108B  CD DA 1F
Z_108E:
	pop bc	; 108E  C1
Z_108F:
	dec c	; 108F  0D
Z_1090:
	jp nz,L_1061	; 1090  20 CF
Z_1092:
	ret	; 1092  C9
Z_1093:
	ret nz	; 1093  C0
Z_1094:
	jp c,SPR_BANK_294B+0x17C	; 1094  DA C7 2A  ; в каноне +0x100 этот операнд стухший
Z_1097:
	ld de,WORK_RAM+0x3EC	; 1097  11 94 3E  ; в каноне +0x100 этот операнд стухший
Z_109A:
	and a	; 109A  A7
Z_109B:
	ld a,l	; 109B  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
	jp nz,il_AS3
	jp c,il_ASC4
	ld a,l
	or a
	jp il_AS3
il_ASC4:
	ld a,l
	or a
	scf
il_AS3:
Z_109D:
	ld (L_10A4+0x1),hl	; 109D  22 A5 10  ; в каноне +0x100 этот операнд стухший
Z_10A0:
	ld bc,0x4517	; 10A0  01 17 45
L_10A3:
Z_10A3:
	push bc	; 10A3  C5
L_10A4:
Z_10A4:
	ld bc,0x00	; 10A4  01 00 00
Z_10A7:
	ld hl,0x00	; 10A7  21 00 00
Z_10AA:
	ld de,0x00	; 10AA  11 00 00
Z_10AD:
	call il_lddr	; 10AD  ED B8
Z_10AF:
	ex de,hl	; 10AF  EB
Z_10B0:
	call L_1F36	; 10B0  CD 36 1F  ; в каноне +0x100 этот операнд стухший
Z_10B3:
	ld hl,0x00	; 10B3  21 00 00
Z_10B6:
	ld de,WORK_RAM+0x3EC	; 10B6  11 94 3E  ; в каноне +0x100 этот операнд стухший
Z_10B9:
	ld c,0x00	; 10B9  0E 00
Z_10BB:
	ld b,0x45	; 10BB  06 45
Z_10BD:
	call VDP_WR_STRIDE8	; 10BD  CD 1D 1B  ; в каноне +0x100 этот операнд стухший
Z_10C0:
	ld hl,0x00	; 10C0  21 00 00
Z_10C3:
	ld de,WORK_RAM+0x3EC	; 10C3  11 94 3E  ; в каноне +0x100 этот операнд стухший
Z_10C6:
	ld c,0x00	; 10C6  0E 00
Z_10C8:
	ld b,0x45	; 10C8  06 45
Z_10CA:
	call VDP_WR_STRIDE8	; 10CA  CD 1D 1B  ; в каноне +0x100 этот операнд стухший
Z_10CD:
	pop bc	; 10CD  C1
Z_10CE:
	dec c	; 10CE  0D
Z_10CF:
	jp nz,L_10A3	; 10CF  20 D2
Z_10D1:
	ret	; 10D1  C9
D_10D2:
Z_10D2:
	db	0x45,0xCD,0x1D,0xD2,0xC1,0x0D,0x20,0xD2,0xC9	; 10D2
L_10DB:
Z_10DB:
	ld (il_tmp),hl	; 10DB  FD 21 A2 9A
	ld hl,OBJ_TABLE_9AA2
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_10DF:
	ld b,0x14	; 10DF  06 14
L_10E1:
Z_10E1:
	push bc	; 10E1  C5
Z_10E2:
	call L_116A	; 10E2  CD 6A 11
Z_10E5:
	ld a,(GAME_VARS+0xC)	; 10E5  3A F6 0A
Z_10E8:
	ld (il_tmp2),hl	; 10E8  FD BE 02
	ld hl,(z80_iy)
	inc hl
	inc hl
	cp (hl)
	ld hl,(il_tmp2)
Z_10EB:
	jp nz,L_1122	; 10EB  20 35
Z_10ED:
	call il_iy_lda	; 10ED  FD 7E 04
	db 0x04
Z_10F0:
	and 0x7F	; 10F0  E6 7F
L_10F2:
Z_10F2:
	jp nz,L_110B	; 10F2  20 17
Z_10F4:
	ld a,(L_0837+0x1)	; 10F4  3A 38 08
Z_10F7:
	or a	; 10F7  B7
Z_10F8:
	jp nz,L_110B	; 10F8  20 11
Z_10FA:
	call L_114B	; 10FA  CD 4B 11
Z_10FD:
	call il_iy_ldb	; 10FD  FD 46 01
	db 0x01
Z_1100:
	call il_iy_ldc	; 1100  FD 4E 00
	db 0x00
Z_1103:
	ld a,0x1E	; 1103  3E 1E
Z_1105:
	call L_1226	; 1105  CD 26 12
Z_1108:
	call L_0642	; 1108  CD 42 06
L_110B:
Z_110B:
	call il_iy_lda	; 110B  FD 7E 03
	db 0x03
Z_110E:
	and 0x3F	; 110E  E6 3F
Z_1110:
	ld b,a	; 1110  47
Z_1111:
	call il_iy_lda	; 1111  FD 7E 04
	db 0x04
Z_1114:
	and 0x80	; 1114  E6 80
Z_1116:
	or b	; 1116  B0
Z_1117:
	call il_iy_ldb	; 1117  FD 46 01
	db 0x01
Z_111A:
	call il_iy_ldc	; 111A  FD 4E 00
	db 0x00
Z_111D:
	call L_19A0	; 111D  CD A0 19
Z_1120:
	jp L_1142	; 1120  18 20
L_1122:
Z_1122:
	ld a,(LEVEL_VARS)	; 1122  3A 7B 16
Z_1125:
	ld (il_tmp2),hl	; 1125  FD BE 02
	ld hl,(z80_iy)
	inc hl
	inc hl
	cp (hl)
	ld hl,(il_tmp2)
Z_1128:
	jp nz,L_1142	; 1128  20 18
Z_112A:
	call il_iy_ldb	; 112A  FD 46 01
	db 0x01
Z_112D:
	call il_iy_lda	; 112D  FD 7E 00
	db 0x00
Z_1130:
	add a,0x60	; 1130  C6 60
Z_1132:
	ld c,a	; 1132  4F
Z_1133:
	call il_iy_lda	; 1133  FD 7E 03
	db 0x03
Z_1136:
	and 0x3F	; 1136  E6 3F
Z_1138:
	ld d,a	; 1138  57
Z_1139:
	call il_iy_lda	; 1139  FD 7E 04
	db 0x04
Z_113C:
	and 0x80	; 113C  E6 80
Z_113E:
	or d	; 113E  B2
Z_113F:
	call L_19A0	; 113F  CD A0 19
L_1142:
Z_1142:
	ld bc,0x09	; 1142  01 09 00
Z_1145:
	ld (il_tmp),hl	; 1145  FD 09
	ld hl,(z80_iy)
	add hl,bc
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_1147:
	pop bc	; 1147  C1
Z_1148:
	dec b	; 1148  10 97
	jp nz,L_10E1
Z_114A:
	ret	; 114A  C9
L_114B:
Z_114B:
	call il_rnd	; 114B  ED 5F
Z_114D:
	and 0x7F	; 114D  E6 7F
Z_114F:
	cp 0x6E	; 114F  FE 6E
Z_1151:
	ret c	; 1151  D8
Z_1152:
	ld hl,(GAME_VARS+0xA)	; 1152  2A F4 0A
Z_1155:
	call il_iy_lda	; 1155  FD 7E 01
	db 0x01
Z_1158:
	call il_iy_ldb	; 1158  FD 46 04
	db 0x04
Z_115B:
	cp h	; 115B  BC
Z_115C:
	jp nc,L_1163	; 115C  30 05
Z_115E:
	ld a,b	; 115E  78
L_115F:
Z_115F:
	and 0x7F	; 115F  E6 7F
Z_1161:
	jp L_1166	; 1161  18 03
L_1163:
Z_1163:
	ld a,b	; 1163  78
Z_1164:
	or 0x80	; 1164  F6 80
L_1166:
Z_1166:
	call il_iy_sta	; 1166  FD 77 04
	db 0x04
Z_1169:
	ret	; 1169  C9
L_116A:
Z_116A:
	ld (il_tmp2),hl	; 116A  FD 7E 04
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
Z_116D:
	and 0x7F	; 116D  E6 7F
Z_116F:
	jp z,L_1175	; 116F  28 04
Z_1171:
	call il_iy_dec	; 1171  FD 35 04
	db 0x04
Z_1174:
	ret	; 1174  C9
L_1175:
Z_1175:
	call L_15F1	; 1175  CD F1 15
Z_1178:
	ld (il_tmp2),hl	; 1178  FD 7E 04
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
Z_117B:
	and 0x80	; 117B  E6 80
Z_117D:
	ld (il_tmp2),hl	; 117D  FD 7E 01
	ld hl,(z80_iy)
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
L_1180:
Z_1180:
	jp nz,L_118C	; 1180  20 0A
Z_1182:
	add a,0x03	; 1182  C6 03
Z_1184:
	ld (il_tmp2),hl	; 1184  FD 46 05
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	ld b,(hl)
	ld hl,(il_tmp2)
Z_1187:
	ld (il_tmp2),hl	; 1187  FD 4E 06
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	ld c,(hl)
	ld hl,(il_tmp2)
Z_118A:
	jp L_1194	; 118A  18 08
L_118C:
Z_118C:
	sub 0x03	; 118C  D6 03
Z_118E:
	push af	; 118E  FD 46 07
	ld (il_tmp2),hl
	ld hl,(z80_iy)
	ld a,l
	add a,7
	ld l,a
	ld a,h
	adc a,0
	ld h,a
	ld b,(hl)
	ld hl,(il_tmp2)
	pop af
Z_1191:
	push af	; 1191  FD 4E 08
	ld (il_tmp2),hl
	ld hl,(z80_iy)
	ld a,l
	add a,8
	ld l,a
	ld a,h
	adc a,0
	ld h,a
	ld c,(hl)
	ld hl,(il_tmp2)
	pop af
L_1194:
Z_1194:
	ld (il_tmp2),hl	; 1194  FD 77 01
	ld hl,(z80_iy)
	inc hl
	ld (hl),a
	ld hl,(il_tmp2)
Z_1197:
	ld (il_tmp2),hl	; 1197  FD 7E 02
	ld hl,(z80_iy)
	inc hl
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
Z_119A:
	cp b	; 119A  B8
Z_119B:
	jp nz,L_11AE	; 119B  20 11
Z_119D:
	ld (il_tmp2),hl	; 119D  FD 7E 01
	ld hl,(z80_iy)
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
Z_11A0:
	cp c	; 11A0  B9
Z_11A1:
	jp nz,L_11AE	; 11A1  20 0B
Z_11A3:
	call il_iy_lda	; 11A3  FD 7E 04
	db 0x04
Z_11A6:
	xor 0x80	; 11A6  EE 80
Z_11A8:
	call il_iy_sta	; 11A8  FD 77 04
	db 0x04
Z_11AB:
	call L_116A	; 11AB  CD 6A 11
L_11AE:
Z_11AE:
	ld (il_tmp2),hl	; 11AE  FD 7E 01
	ld hl,(z80_iy)
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
Z_11B1:
	cp 0xE6	; 11B1  FE E6
Z_11B3:
	jp nc,L_11D5	; 11B3  30 20
Z_11B5:
	cp 0xA3	; 11B5  FE A3
Z_11B7:
	ret c	; 11B7  D8
Z_11B8:
	call il_iy_ldb	; 11B8  FD 46 02
	db 0x02
Z_11BB:
	call il_iy_inc	; 11BB  FD 34 02
	db 0x02
Z_11BE:
	ld a,(GAME_VARS+0xC)	; 11BE  3A F6 0A
Z_11C1:
	cp b	; 11C1  B8
Z_11C2:
	jp nz,L_11C9	; 11C2  20 05
Z_11C4:
	call THUNK_CDC5_D00	; 11C4  CD FE 1C
Z_11C7:
	jp L_11D0	; 11C7  18 07
L_11C9:
Z_11C9:
	ld a,(LEVEL_VARS)	; 11C9  3A 7B 16
Z_11CC:
	cp b	; 11CC  B8
Z_11CD:
	call z,THUNK_CDC5_D60	; 11CD  CC 03 1D
L_11D0:
Z_11D0:
	call il_iy_stn	; 11D0  FD 36 01 00
	db 0x01, 0x00
Z_11D4:
	ret	; 11D4  C9
L_11D5:
Z_11D5:
	call il_iy_ldb	; 11D5  FD 46 02
	db 0x02
Z_11D8:
	call il_iy_dec	; 11D8  FD 35 02
	db 0x02
Z_11DB:
	ld a,(GAME_VARS+0xC)	; 11DB  3A F6 0A
Z_11DE:
	cp b	; 11DE  B8
Z_11DF:
	jp nz,L_11E6	; 11DF  20 05
Z_11E1:
	call THUNK_CDC5_D00	; 11E1  CD FE 1C
Z_11E4:
	jp L_11ED	; 11E4  18 07
L_11E6:
Z_11E6:
	ld a,(LEVEL_VARS)	; 11E6  3A 7B 16
Z_11E9:
	cp b	; 11E9  B8
Z_11EA:
	call z,THUNK_CDC5_D60	; 11EA  CC 03 1D
L_11ED:
Z_11ED:
	call il_iy_stn	; 11ED  FD 36 01 A2
	db 0x01, 0xA2
Z_11F1:
	ret	; 11F1  C9
L_11F2:
Z_11F2:
	ld de,0x1C00	; 11F2  11 00 1C
Z_11F5:
	ld (L_1208+0x1),a	; 11F5  32 09 12
Z_11F8:
	ld (L_120C+0x1),a	; 11F8  32 0D 12
Z_11FB:
	ld a,(GAME_VARS+0x7)	; 11FB  3A F1 0A
Z_11FE:
	cp 0x05	; 11FE  FE 05
Z_1200:
	jp nz,L_1204	; 1200  20 02
Z_1202:
	ld d,0x14	; 1202  16 14
L_1204:
Z_1204:
	ld hl,(GAME_VARS+0xA)	; 1204  2A F4 0A
Z_1207:
	ld a,l	; 1207  7D
L_1208:
Z_1208:
	add a,0x1E	; 1208  C6 1E
Z_120A:
	cp c	; 120A  B9
Z_120B:
	ret c	; 120B  D8
L_120C:
Z_120C:
	sub 0x1E	; 120C  D6 1E
Z_120E:
	sub d	; 120E  92
Z_120F:
	cp 0xE6	; 120F  FE E6
Z_1211:
	jp c,L_1214	; 1211  38 01
Z_1213:
	xor a	; 1213  AF
L_1214:
Z_1214:
	cp c	; 1214  B9
Z_1215:
	ret nc	; 1215  D0
Z_1216:
	ld a,h	; 1216  7C
Z_1217:
	add a,0x0C	; 1217  C6 0C
Z_1219:
	cp b	; 1219  B8
Z_121A:
	ret c	; 121A  D8
Z_121B:
	sub 0x20	; 121B  D6 20
Z_121D:
	cp 0xE6	; 121D  FE E6
Z_121F:
	jp c,L_1222	; 121F  38 01
Z_1221:
	xor a	; 1221  AF
L_1222:
Z_1222:
	cp b	; 1222  B8
Z_1223:
	ret nc	; 1223  D0
Z_1224:
	inc e	; 1224  1C
Z_1225:
	ret	; 1225  C9
L_1226:
Z_1226:
	call L_11F2	; 1226  CD F2 11
Z_1229:
	xor a	; 1229  AF
Z_122A:
	cp e	; 122A  BB
Z_122B:
	ret z	; 122B  C8
L_122C:
Z_122C:
	ld a,0x13	; 122C  3E 13
Z_122E:
	dec a	; 122E  3D
Z_122F:
	push af	; 122F  F5
Z_1230:
	ld (L_122C+0x1),a	; 1230  32 2D 12
Z_1233:
	push af	; 1233  F5
Z_1234:
	and 0x38	; 1234  E6 38
Z_1236:
	ld c,a	; 1236  4F
Z_1237:
	pop af	; 1237  F1
Z_1238:
	and 0x07	; 1238  E6 07
Z_123A:
	ld b,0x00	; 123A  06 00
Z_123C:
	ld hl,0x48C9	; 123C  21 C9 48
Z_123F:
	add hl,bc	; 123F  09
Z_1240:
	sub 0x08	; 1240  D6 08
Z_1242:
	cpl	; 1242  ED 44
	inc a
Z_1244:
	ld b,a	; 1244  47
Z_1245:
	ld a,0xFF	; 1245  3E FF
L_1247:
Z_1247:
	add a,a	; 1247  CB 27
Z_1249:
	dec b	; 1249  10 FC
	jp nz,L_1247
Z_124B:
	and 0x7F	; 124B  E6 7F
Z_124D:
	ld bc,0x07	; 124D  01 07 00
Z_1250:
	call VDP_FILL	; 1250  CD 11 1C
Z_1253:
	ld hl,0x1388	; 1253  21 88 13
Z_1256:
	ld de,0x01	; 1256  11 01 00
Z_1259:
	call SFX_64C8	; 1259  CD 94 20
Z_125C:
	pop af	; 125C  F1
Z_125D:
	ret nz	; 125D  C0
Z_125E:
	ld a,0x02	; 125E  3E 02
Z_1260:
	jp L_0F27	; 1260  C3 27 0F
D_1263:
Z_1263:
	db	0xC9,0xCD,0xA7,0xCC,0x3A,0x7B,0xCD,0xC6,0x80,0x47,0xCD,0x84,0xD1,0x3A,0xF6,0xC1	; 1263
Z_1273:
	db	0xCD,0x6C	; 1273
L_1275:
Z_1275:
	ld (il_tmp),hl	; 1275  FD 21 7C 16
	ld hl,LEVEL_VARS+0x1
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_1279:
	ld b,0x03	; 1279  06 03
Z_127B:
	ld a,(LEVEL_VARS+0x7)	; 127B  3A 82 16
Z_127E:
	or a	; 127E  B7
Z_127F:
	jp nz,L_1283	; 127F  20 02
Z_1281:
	ld b,0x01	; 1281  06 01
L_1283:
Z_1283:
	push bc	; 1283  C5
Z_1284:
	ld a,(GAME_VARS+0xC)	; 1284  3A F6 0A
Z_1287:
	call il_iy_cp	; 1287  FD BE 00
	db 0x00
Z_128A:
	jp nz,L_1296	; 128A  20 0A
Z_128C:
	call L_12B5	; 128C  CD B5 12
Z_128F:
	ld d,0x00	; 128F  16 00
Z_1291:
	call L_12AB	; 1291  CD AB 12
Z_1294:
	jp L_12A3	; 1294  18 0D
L_1296:
Z_1296:
	ld a,(LEVEL_VARS)	; 1296  3A 7B 16
Z_1299:
	ld d,0x60	; 1299  16 60
Z_129B:
	call il_iy_cp	; 129B  FD BE 00
	db 0x00
Z_129E:
	jp nz,L_12A3	; 129E  20 03
L_12A0:
Z_12A0:
	call L_12AB	; 12A0  CD AB 12
L_12A3:
Z_12A3:
	ld (il_tmp),hl	; 12A3  FD 23
	ld hl,(z80_iy)
	inc hl
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_12A5:
	ld (il_tmp),hl	; 12A5  FD 23
	ld hl,(z80_iy)
	inc hl
	ld (z80_iy),hl
	ld hl,(il_tmp)
Z_12A7:
	pop bc	; 12A7  C1
Z_12A8:
	dec b	; 12A8  10 D9
	jp nz,L_1283
Z_12AA:
	ret	; 12AA  C9
L_12AB:
Z_12AB:
	call il_iy_ldl	; 12AB  FD 6E 0C
	db 0x0C
Z_12AE:
	call il_iy_ldh	; 12AE  FD 66 0D
	db 0x0D
Z_12B1:
	call il_iy_ldb	; 12B1  FD 46 01
	db 0x01
Z_12B4:
	jp (hl)	; 12B4  E9
L_12B5:
Z_12B5:
	call il_iy_lda	; 12B5  FD 7E 06
	db 0x06
Z_12B8:
	or a	; 12B8  B7
Z_12B9:
	ret nz	; 12B9  C0
Z_12BA:
	ld a,0xF6	; 12BA  3E F6
Z_12BC:
	out (0xAA),a	; 12BC  D3 AA
Z_12BE:
	nop	; 12BE  00
Z_12BF:
	in a,(0xA9)	; 12BF  DB A9
Z_12C1:
	ld (il_a),a	; 12C1  CB 47
	and 0x01
	ld a,(il_a)
Z_12C3:
	nop	; 12C3  00
Z_12C4:
	nop	; 12C4  00
Z_12C5:
	ret nz	; 12C5  C0
Z_12C6:
	call il_iy_ldb	; 12C6  FD 46 01
	db 0x01
Z_12C9:
	ld a,(GAME_VARS+0xB)	; 12C9  3A F5 0A
Z_12CC:
	add a,0x04	; 12CC  C6 04
Z_12CE:
	cp b	; 12CE  B8
Z_12CF:
	ret c	; 12CF  D8
Z_12D0:
	sub 0x08	; 12D0  D6 08
Z_12D2:
	cp b	; 12D2  B8
Z_12D3:
	ret nc	; 12D3  D0
Z_12D4:
	ld a,0x01	; 12D4  3E 01
Z_12D6:
	call il_iy_sta	; 12D6  FD 77 06
	db 0x06
Z_12D9:
	call il_iy_ldl	; 12D9  FD 6E 12
	db 0x12
Z_12DC:
	call il_iy_ldh	; 12DC  FD 66 13
	db 0x13
Z_12DF:
	jp (hl)	; 12DF  E9
L_12E0:
Z_12E0:
	ret	; 12E0  C9
L_12E1:
Z_12E1:
	ld a,0x07	; 12E1  3E 07
Z_12E3:
	out (0xA0),a	; 12E3  D3 A0
Z_12E5:
	ld a,0xFF	; 12E5  3E FF
Z_12E7:
	out (0xA1),a	; 12E7  D3 A1
Z_12E9:
	ld a,0x0E	; 12E9  3E 0E
Z_12EB:
	out (0xA0),a	; 12EB  D3 A0
Z_12ED:
	in a,(0xA2)	; 12ED  DB A2
Z_12EF:
	and 0x1F	; 12EF  E6 1F
Z_12F1:
	cp 0x1F	; 12F1  FE 1F
Z_12F3:
	ret z	; 12F3  C8
Z_12F4:
	cpl	; 12F4  2F
Z_12F5:
	ld b,a	; 12F5  47
Z_12F6:
	pop hl	; 12F6  E1
L_12F7:
Z_12F7:
	ret	; 12F7  C9
Z_12F8:
	push bc	; 12F8  C5
Z_12F9:
	ld a,0x1A	; 12F9  3E 1A
Z_12FB:
	call L_19A0	; 12FB  CD A0 19
Z_12FE:
	pop bc	; 12FE  C1
Z_12FF:
	ld a,b	; 12FF  78
Z_1300:
	sub 0x08	; 1300  D6 08
Z_1302:
	ld b,a	; 1302  47
Z_1303:
	ld a,c	; 1303  79
Z_1304:
	add a,0x08	; 1304  C6 08
Z_1306:
	ld c,a	; 1306  4F
Z_1307:
	pop af	; 1307  F1
Z_1308:
	dec a	; 1308  3D
Z_1309:
	jp nz,L_12F7	; 1309  20 EC
Z_130B:
	ret	; 130B  C9
L_130C:
Z_130C:
	ld hl,0x48C9	; 130C  21 C9 48
Z_130F:
	ld b,0x06	; 130F  06 06
L_1311:
Z_1311:
	push bc	; 1311  C5
L_1312:
Z_1312:
	push hl	; 1312  E5
Z_1313:
	ld a,0x77	; 1313  3E 77
Z_1315:
	ld bc,0x07	; 1315  01 07 00
Z_1318:
	call VDP_FILL	; 1318  CD 11 1C
Z_131B:
	pop hl	; 131B  E1
Z_131C:
	ld a,0x08	; 131C  3E 08
Z_131E:
	add a,l	; 131E  85
Z_131F:
	ld l,a	; 131F  6F
Z_1320:
	pop bc	; 1320  C1
Z_1321:
	dec b	; 1321  10 EE
	jp nz,L_1311
Z_1323:
	ld a,0x2F	; 1323  3E 2F
Z_1325:
	ld (L_122C+0x1),a	; 1325  32 2D 12
Z_1328:
	ret	; 1328  C9
DEAD_1329:
Z_1329:
	db	0x1D,0xD2,0x11,0x8D,0xF5,0x21,0x00,0x00,0xC1,0xCD,0x1D,0xD2,0xC1,0x0D,0x20,0xD7	; 1329
Z_1339:
	db	0xC9,0x0E,0x20,0xFD	; 1339
L_133D:
Z_133D:
	call L_18CA	; 133D  CD CA 18
Z_1340:
	nop	; 1340  00
Z_1341:
	nop	; 1341  00
Z_1342:
	nop	; 1342  00
Z_1343:
	call L_1694	; 1343  CD 94 16
Z_1346:
	call L_23E9	; 1346  CD E9 23
Z_1349:
	call L_130C	; 1349  CD 0C 13
Z_134C:
	call L_1807	; 134C  CD 07 18
Z_134F:
	call L_176A	; 134F  CD 6A 17
Z_1352:
	call L_0AFF	; 1352  CD FF 0A
Z_1355:
	call L_138D	; 1355  CD 8D 13
Z_1358:
	ld hl,WORK_RAM+0x111	; 1358  21 B9 3B  ; в каноне +0x100 этот операнд стухший
Z_135B:
	ld de,WORK_RAM+0x112	; 135B  11 BA 3B  ; в каноне +0x100 этот операнд стухший
Z_135E:
	ld bc,0x56	; 135E  01 56 00
Z_1361:
	ld (hl),0x00	; 1361  36 00
Z_1363:
	call il_ldir	; 1363  ED B0
Z_1365:
	xor a	; 1365  AF
Z_1366:
	ld (D_1642),a	; 1366  32 42 16
Z_1369:
	ld a,(LEVEL_VARS+0x1)	; 1369  3A 7C 16
Z_136C:
	ld (LEVEL_VARS),a	; 136C  32 7B 16
Z_136F:
	call L_0C8C	; 136F  CD 8C 0C
L_1372:
Z_1372:
	jp L_0F2B	; 1372  C3 2B 0F
D_1375:
Z_1375:
	db	0xCB,0x01,0x16,0xDD,0xCB,0x00	; 1375
L_137B:
Z_137B:
	nop	; 137B  00
Z_137C:
	nop	; 137C  00
Z_137D:
	nop	; 137D  00
Z_137E:
	nop	; 137E  00
Z_137F:
	nop	; 137F  00
Z_1380:
	call SFX_64E6	; 1380  CD E5 1F
Z_1383:
	ld a,(GAME_VARS+0x8)	; 1383  3A F2 0A
Z_1386:
	dec a	; 1386  3D
Z_1387:
	ld (GAME_VARS+0x8),a	; 1387  32 F2 0A
Z_138A:
	jp L_16D8	; 138A  C3 D8 16
L_138D:
Z_138D:
	ld hl,OBJ_ARRAY_INIT	; 138D  21 E6 14
Z_1390:
	ld de,OBJ_ARRAY_14BF	; 1390  11 BF 14
Z_1393:
	ld bc,0x27	; 1393  01 27 00
Z_1396:
	call il_ldir	; 1396  ED B0
Z_1398:
	xor a	; 1398  AF
Z_1399:
	ld (L_0899+0x1),a	; 1399  32 9A 08
Z_139C:
	ld (D_04D4),a	; 139C  32 D4 04
Z_139F:
	ret	; 139F  C9
L_13A0:
Z_13A0:
	ld hl,TEXT_SHORT	; 13A0  21 F9 9B  ; в каноне +0x100 этот операнд стухший
Z_13A3:
	ld de,0x0F1C	; 13A3  11 1C 0F
Z_13A6:
	ld b,0x13	; 13A6  06 13
Z_13A8:
	ld a,0x0F	; 13A8  3E 0F
Z_13AA:
	ld (L_0899+0x1),a	; 13AA  32 9A 08  ; в каноне +0x100 этот операнд стухший
Z_13AD:
	jp L_13BF	; 13AD  18 10
L_13AF:
Z_13AF:
	ld hl,TEXT_SHORT+0x13	; 13AF  21 0C 9C  ; в каноне +0x100 этот операнд стухший
L_13B2:
Z_13B2:
	ld de,0x0F1C	; 13B2  11 1C 0F
Z_13B5:
	jp L_13BD	; 13B5  18 06
L_13B7:
Z_13B7:
	ld hl,TEXT_SHORT+0x1E	; 13B7  21 17 9C  ; в каноне +0x100 этот операнд стухший
Z_13BA:
	ld de,0x111C	; 13BA  11 1C 11
L_13BD:
Z_13BD:
	ld b,0x0B	; 13BD  06 0B
L_13BF:
Z_13BF:
	call L_16F9	; 13BF  CD F9 16  ; в каноне +0x100 этот операнд стухший
Z_13C2:
	ld b,0x00	; 13C2  06 00
Z_13C4:
	ld hl,0x01	; 13C4  21 01 00
Z_13C7:
	call L_0F8A	; 13C7  CD 8A 0F  ; в каноне +0x100 этот операнд стухший
Z_13CA:
	ld a,(D_1642)	; 13CA  3A 42 16  ; в каноне +0x100 этот операнд стухший
Z_13CD:
	add a,0x0F	; 13CD  C6 0F
Z_13CF:
	ld (D_1642),a	; 13CF  32 42 16  ; в каноне +0x100 этот операнд стухший
Z_13D2:
	jp L_130C	; 13D2  C3 0C 13  ; в каноне +0x100 этот операнд стухший
L_13D5:
Z_13D5:
	ld b,0x02	; 13D5  06 02
L_13D7:
Z_13D7:
	push bc	; 13D7  C5
Z_13D8:
	ld de,GFX_9940	; 13D8  11 40 99
Z_13DB:
	call L_13E8	; 13DB  CD E8 13
Z_13DE:
	ld de,GFX_9940+0x50	; 13DE  11 90 99
Z_13E1:
	call L_13E8	; 13E1  CD E8 13
Z_13E4:
	pop bc	; 13E4  C1
Z_13E5:
	dec b	; 13E5  10 F0
	jp nz,L_13D7
Z_13E7:
	ret	; 13E7  C9
L_13E8:
Z_13E8:
	ld hl,0x4360	; 13E8  21 60 43
Z_13EB:
	ld b,0x02	; 13EB  06 02
L_13ED:
Z_13ED:
	push bc	; 13ED  C5
Z_13EE:
	ld bc,0x28	; 13EE  01 28 00
Z_13F1:
	push hl	; 13F1  E5
Z_13F2:
	call VDP_COPY_TO_VRAM	; 13F2  CD 33 1C
Z_13F5:
	pop hl	; 13F5  E1
Z_13F6:
	inc h	; 13F6  24
Z_13F7:
	pop bc	; 13F7  C1
Z_13F8:
	dec b	; 13F8  10 F3
	jp nz,L_13ED
Z_13FA:
	ld hl,0x00	; 13FA  21 00 00
L_13FD:
Z_13FD:
	dec hl	; 13FD  2B
Z_13FE:
	ld a,h	; 13FE  7C
Z_13FF:
	or l	; 13FF  B5
L_1400:
Z_1400:
	jp nz,L_13FD	; 1400  20 FB
Z_1402:
	ret	; 1402  C9
Z_1403:
	jp nz,L_1400	; 1403  20 FB
Z_1405:
	ret	; 1405  C9
D_1406:
Z_1406:
	db	0xFB,0xC9	; 1406
Z_1408:
	ld c,0x00	; 1408  0E 00
Z_140A:
	ld b,0x45	; 140A  06 45
Z_140C:
	call VDP_WR_STRIDE8	; 140C  CD 1D 1B  ; в каноне +0x100 этот операнд стухший
Z_140F:
	pop bc	; 140F  C1
L_1410:
Z_1410:
	dec c	; 1410  0D
L_1411:
Z_1411:
	jp nz,L_1410	; 1411  20 FD
Z_1413:
	ld a,(hl)	; 1413  7E
Z_1414:
	nop	; 1414  00
Z_1415:
	or a	; 1415  B7
Z_1416:
	jp z,L_141D	; 1416  28 05
Z_1418:
	call il_iy_dec	; 1418  FD 35 00
	db 0x00
Z_141B:
	jp L_1475	; 141B  18 58
L_141D:
Z_141D:
	call il_iy_ldl	; 141D  FD 6E 01
	db 0x01
Z_1420:
	call il_iy_ldh	; 1420  FD 66 02
	db 0x02
Z_1423:
	ld a,(hl)	; 1423  7E
Z_1424:
	inc hl	; 1424  23
Z_1425:
	cp 0x0F	; 1425  FE 0F
Z_1427:
	jp z,L_14A8	; 1427  28 7F
Z_1429:
	cp 0x0C	; 1429  FE 0C
Z_142B:
	jp z,L_149F	; 142B  28 72
Z_142D:
	or a	; 142D  B7
Z_142E:
	jp z,L_14B2	; 142E  CA B2 14  ; в каноне +0x100 этот операнд стухший
Z_1431:
	ld e,a	; 1431  5F
Z_1432:
	ld a,(hl)	; 1432  7E
Z_1433:
	inc hl	; 1433  23
Z_1434:
	call il_iy_sta	; 1434  FD 77 00
	db 0x00
Z_1437:
	call il_iy_stl	; 1437  FD 75 01
	db 0x01
Z_143A:
	call il_iy_sth	; 143A  FD 74 02
	db 0x02
Z_143D:
	ld bc,0x00	; 143D  01 00 00
Z_1440:
	ld d,0x00	; 1440  16 00
Z_1442:
	ld a,e	; 1442  7B
Z_1443:
	and 0x0C	; 1443  E6 0C
Z_1445:
	cp 0x08	; 1445  FE 08
Z_1447:
	jp nz,L_144D	; 1447  20 04
Z_1449:
	ld b,0x04	; 1449  06 04
Z_144B:
	jp L_1453	; 144B  18 06
L_144D:
Z_144D:
	cp 0x04	; 144D  FE 04
Z_144F:
	jp nz,L_1453	; 144F  20 02
Z_1451:
	ld b,0xFC	; 1451  06 FC
L_1453:
Z_1453:
	ld a,e	; 1453  7B
Z_1454:
	and 0x03	; 1454  E6 03
Z_1456:
	cp 0x03	; 1456  FE 03
Z_1458:
	jp nz,L_145E	; 1458  20 04
Z_145A:
	ld d,0x01	; 145A  16 01
Z_145C:
	jp L_146C	; 145C  18 0E
L_145E:
Z_145E:
	cp 0x02	; 145E  FE 02
Z_1460:
	jp nz,L_1466	; 1460  20 04
Z_1462:
	ld c,0x02	; 1462  0E 02
Z_1464:
	jp L_146C	; 1464  18 06
L_1466:
Z_1466:
	cp 0x01	; 1466  FE 01
Z_1468:
	jp nz,L_146C	; 1468  20 02
Z_146A:
	ld c,0xFE	; 146A  0E FE
L_146C:
Z_146C:
	call il_iy_stc	; 146C  FD 71 0C
	db 0x0C
Z_146F:
	call il_iy_stb	; 146F  FD 70 04
	db 0x04
Z_1472:
	call il_iy_std	; 1472  FD 72 05
	db 0x05
L_1475:
Z_1475:
	call il_iy_ldd	; 1475  FD 56 05
	db 0x05
Z_1478:
	call il_iy_ldc	; 1478  FD 4E 04
	db 0x04
Z_147B:
	call il_iy_ldb	; 147B  FD 46 0C
	db 0x0C
Z_147E:
	call il_iy_lda	; 147E  FD 7E 0B
	db 0x0B
Z_1481:
	and 0x80	; 1481  E6 80
Z_1483:
	ld e,a	; 1483  5F
Z_1484:
	ld a,0xFE	; 1484  3E FE
Z_1486:
	cp b	; 1486  B8
Z_1487:
	jp z,L_1492	; 1487  28 09
Z_1489:
	ld a,0x02	; 1489  3E 02
Z_148B:
	cp b	; 148B  B8
Z_148C:
	jp nz,L_1494	; 148C  20 06
Z_148E:
	ld e,0x80	; 148E  1E 80
Z_1490:
	jp L_1494	; 1490  18 02
L_1492:
Z_1492:
	ld e,0x00	; 1492  1E 00
L_1494:
Z_1494:
	call il_iy_lda	; 1494  FD 7E 07
	db 0x07
Z_1497:
	add a,c	; 1497  81
Z_1498:
	ld c,a	; 1498  4F
Z_1499:
	call il_iy_lda	; 1499  FD 7E 08
	db 0x08
Z_149C:
	add a,b	; 149C  80
Z_149D:
	ld b,a	; 149D  47
Z_149E:
	ret	; 149E  C9
L_149F:
Z_149F:
	ld e,(hl)	; 149F  5E
Z_14A0:
	inc hl	; 14A0  23
Z_14A1:
	ld d,(hl)	; 14A1  56
Z_14A2:
	inc hl	; 14A2  23
Z_14A3:
	ld a,(de)	; 14A3  1A
Z_14A4:
	and 0x80	; 14A4  E6 80
Z_14A6:
	jp z,L_14B2	; 14A6  28 0A
L_14A8:
Z_14A8:
	call il_rnd	; 14A8  ED 5F
Z_14AA:
	ld bc,0x02	; 14AA  01 02 00
Z_14AD:
	and 0x01	; 14AD  E6 01
Z_14AF:
	jp z,L_14B2	; 14AF  28 01
Z_14B1:
	add hl,bc	; 14B1  09
L_14B2:
Z_14B2:
	ld e,(hl)	; 14B2  5E
Z_14B3:
	inc hl	; 14B3  23
Z_14B4:
	ld d,(hl)	; 14B4  56
Z_14B5:
	ex de,hl	; 14B5  EB
Z_14B6:
	call il_iy_stl	; 14B6  FD 75 01
	db 0x01
Z_14B9:
	call il_iy_sth	; 14B9  FD 74 02
	db 0x02
Z_14BC:
	jp L_141D	; 14BC  C3 1D 14  ; в каноне +0x100 этот операнд стухший
OBJ_ARRAY_14BF:
Z_14BF:
	db	0x00,0x28,0x78,0x27,0x00,0x00,0x0B,0x50,0x32,0x00,0x2A,0x00,0x00,0x00,0x2E,0x78	; 14BF
Z_14CF:
	db	0x2B,0x00,0x00,0x32,0x50,0x80,0x00,0x2E,0x00,0x00,0x00,0x2B,0x78,0x2F,0x00,0x00	; 14CF
Z_14DF:
	db	0x53,0x30,0x52,0x00,0x30,0x00,0x00	; 14DF
OBJ_ARRAY_INIT:
Z_14E6:
	db	0x00,0x28,0x78,0x27,0x00,0x00,0x0B,0x50,0x32,0x00,0x2A,0x00,0x00,0x00,0x2E,0x78	; 14E6
Z_14F6:
	db	0x2B,0x00,0x00,0x32,0x50,0x80,0x00,0x2E,0x00,0x00,0x00,0x2B,0x78,0x2F,0x00,0x00	; 14F6
Z_1506:
	db	0x53,0x30,0x52,0x00,0x30,0x00,0x00	; 1506
L_150D:
Z_150D:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
Z_1510:
	ld hl,0x6000	; 1510  21 00 60
Z_1513:
	ld bc,0x181F	; 1513  01 1F 18
Z_1516:
	ld a,0x30	; 1516  3E 30
Z_1518:
	call L_1828	; 1518  CD 28 18
Z_151B:
	ld hl,WORK_RAM+0x111	; 151B  21 B9 3B  ; в каноне +0x100 этот операнд стухший
Z_151E:
	ld bc,0x5700	; 151E  01 00 57
L_1521:
Z_1521:
	ld a,(hl)	; 1521  7E
Z_1522:
	or a	; 1522  B7
Z_1523:
	jp z,L_1526	; 1523  28 01
Z_1525:
	inc c	; 1525  0C
L_1526:
Z_1526:
	inc hl	; 1526  23
Z_1527:
	dec b	; 1527  10 F8
	jp nz,L_1521
Z_1529:
	ld (il_a),a	; 1529  CB 39
	ld a,c
	or a
	rra
	ld c,a
	ld a,(il_a)
Z_152B:
	ld (il_a),a	; 152B  CB 39
	ld a,c
	or a
	rra
	ld c,a
	ld a,(il_a)
Z_152D:
	ld a,(D_1642)	; 152D  3A 42 16
Z_1530:
	add a,c	; 1530  81
Z_1531:
	ld c,0x00	; 1531  0E 00
L_1533:
Z_1533:
	cp 0x0A	; 1533  FE 0A
Z_1535:
	jp c,L_153C	; 1535  38 05
Z_1537:
	sub 0x0A	; 1537  D6 0A
Z_1539:
	inc c	; 1539  0C
Z_153A:
	jp L_1533	; 153A  18 F7
L_153C:
Z_153C:
	ld b,0x02	; 153C  06 02
Z_153E:
	ld hl,TEXT_ES+0x15	; 153E  21 F5 99
L_1541:
Z_1541:
	and a	; 1541  A7
Z_1542:
	jp z,L_1548	; 1542  28 04
Z_1544:
	add a,0x3A	; 1544  C6 3A
Z_1546:
	jp L_154A	; 1546  18 02
L_1548:
Z_1548:
	ld a,0x44	; 1548  3E 44
L_154A:
Z_154A:
	ld (hl),a	; 154A  77
Z_154B:
	dec hl	; 154B  2B
Z_154C:
	ld a,c	; 154C  79
Z_154D:
	dec b	; 154D  10 F2
	jp nz,L_1541
Z_154F:
	ld hl,TEXT_ES	; 154F  21 E0 99
Z_1552:
	ld de,0x0808	; 1552  11 08 08
Z_1555:
	ld b,0x29	; 1555  06 29
Z_1557:
	call L_16F9	; 1557  CD F9 16
Z_155A:
	jp MUS_TRACK_1	; 155A  C3 E7 28
L_155D:
Z_155D:
	ld a,0xF3	; 155D  3E F3
Z_155F:
	out (0xAA),a	; 155F  D3 AA
Z_1561:
	in a,(0xA9)	; 1561  DB A9
Z_1563:
	ld (il_a),a	; 1563  CB 6F
	and 0x20
	ld a,(il_a)
Z_1565:
	jp z,L_155D	; 1565  28 F6
L_1567:
Z_1567:
	ld b,0xF0	; 1567  06 F0
L_1569:
Z_1569:
	ld a,b	; 1569  78
Z_156A:
	out (0xAA),a	; 156A  D3 AA
Z_156C:
	nop	; 156C  00
Z_156D:
	in a,(0xA9)	; 156D  DB A9
Z_156F:
	cp 0xFF	; 156F  FE FF
Z_1571:
	ret nz	; 1571  C0
Z_1572:
	ld a,b	; 1572  78
Z_1573:
	inc a	; 1573  3C
Z_1574:
	ld b,a	; 1574  47
Z_1575:
	cp 0xF9	; 1575  FE F9
Z_1577:
	jp z,L_1567	; 1577  28 EE
Z_1579:
	jp L_1569	; 1579  18 EE
L_157B:
Z_157B:
	call L_12E1	; 157B  CD E1 12
Z_157E:
	push hl	; 157E  E5
Z_157F:
	push de	; 157F  D5
Z_1580:
	ld e,0x05	; 1580  1E 05
Z_1582:
	ld hl,D_1595	; 1582  21 95 15
Z_1585:
	ld b,0x00	; 1585  06 00
L_1587:
Z_1587:
	ld c,(hl)	; 1587  4E
Z_1588:
	nop	; 1588  00
Z_1589:
	call KBD_SCAN	; 1589  CD DF 1C
Z_158C:
	ld (il_a),a	; 158C  CB 10
	ld a,b
	rla
	ld b,a
	ld a,(il_a)
Z_158E:
	inc hl	; 158E  23
Z_158F:
	dec e	; 158F  1D
Z_1590:
	jp nz,L_1587	; 1590  20 F5
Z_1592:
	pop de	; 1592  D1
Z_1593:
	pop hl	; 1593  E1
Z_1594:
	ret	; 1594  C9
D_1595:
Z_1595:
	db	0x80,0x45,0x44,0x26,0x46	; 1595
L_159A:
Z_159A:
	ld hl,0x6000	; 159A  21 00 60
Z_159D:
	ld a,0xF1	; 159D  3E F1
Z_159F:
	call L_15B3	; 159F  CD B3 15
Z_15A2:
	ld hl,0x4000	; 15A2  21 00 40
Z_15A5:
	jp L_15B2	; 15A5  18 0B
L_15A7:
Z_15A7:
	ld hl,0x6C00	; 15A7  21 00 6C
Z_15AA:
	ld a,0xF1	; 15AA  3E F1
Z_15AC:
	call L_15B3	; 15AC  CD B3 15
Z_15AF:
	ld hl,0x4C00	; 15AF  21 00 4C
L_15B2:
Z_15B2:
	xor a	; 15B2  AF
L_15B3:
Z_15B3:
	ld e,0x0C	; 15B3  1E 0C
L_15B5:
Z_15B5:
	ld bc,0xC0	; 15B5  01 C0 00
Z_15B8:
	push af	; 15B8  F5
Z_15B9:
	call VDP_FILL	; 15B9  CD 11 1C
Z_15BC:
	pop af	; 15BC  F1
Z_15BD:
	ld l,0x00	; 15BD  2E 00
Z_15BF:
	inc h	; 15BF  24
Z_15C0:
	dec e	; 15C0  1D
Z_15C1:
	jp nz,L_15B5	; 15C1  20 F2
Z_15C3:
	ret	; 15C3  C9
D_15C4:
Z_15C4:
	db	0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9	; 15C4
L_15CF:
Z_15CF:
	ret	; 15CF  C9
L_15D0:
Z_15D0:
	ld a,0xC9	; 15D0  3E C9
Z_15D2:
	ld (L_20A8),a	; 15D2  32 A8 20
Z_15D5:
	xor a	; 15D5  AF
Z_15D6:
	call L_2168	; 15D6  CD 68 21
Z_15D9:
	ld a,0xE5	; 15D9  3E E5
Z_15DB:
	ld (L_20A8),a	; 15DB  32 A8 20
Z_15DE:
	ret	; 15DE  C9
Z_15DF:
	ex de,hl	; 15DF  EB
L_15E0:
Z_15E0:
	ld (hl),0xD1	; 15E0  36 D1
Z_15E2:
	dec b	; 15E2  10 FC
	jp nz,L_15E0
Z_15E4:
	ret	; 15E4  C9
D_15E5:
Z_15E5:
	db	0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9,0xC9	; 15E5
L_15F1:
Z_15F1:
	ld (il_tmp2),hl	; 15F1  FD 7E 04
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
Z_15F4:
	and 0x7F	; 15F4  E6 7F
Z_15F6:
	ld (il_tmp2),hl	; 15F6  FD 7E 03
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ld hl,(il_tmp2)
L_15F9:
Z_15F9:
	ret nz	; 15F9  C0
L_15FA:
Z_15FA:
	ld b,0x01	; 15FA  06 01
Z_15FC:
	ld (il_a),a	; 15FC  CB 77
	and 0x40
	ld a,(il_a)
Z_15FE:
	jp z,L_1602	; 15FE  28 02
Z_1600:
	ld b,0x02	; 1600  06 02
L_1602:
Z_1602:
	ld (il_a),a	; 1602  CB 7F
	and 0x80
	ld a,(il_a)
Z_1604:
	jp z,L_160B	; 1604  28 05
Z_1606:
	sub b	; 1606  90
Z_1607:
	xor 0x40	; 1607  EE 40
Z_1609:
	jp L_160C	; 1609  18 01
L_160B:
Z_160B:
	add a,b	; 160B  80
L_160C:
Z_160C:
	xor 0x80	; 160C  EE 80
Z_160E:
	ld (il_tmp2),hl	; 160E  FD 77 03
	ld hl,(z80_iy)
	inc hl
	inc hl
	inc hl
	ld (hl),a
	ld hl,(il_tmp2)
Z_1611:
	ret	; 1611  C9
L_1612:
Z_1612:
	call L_1643	; 1612  CD 43 16
Z_1615:
	ld hl,0x70C8	; 1615  21 C8 70
Z_1618:
	ld bc,0x0303	; 1618  01 03 03
Z_161B:
	ld a,0xF1	; 161B  3E F1
Z_161D:
	jp L_1634	; 161D  18 15
L_161F:
Z_161F:
	call L_1643	; 161F  CD 43 16
Z_1622:
	ld hl,0x6CC8	; 1622  21 C8 6C
Z_1625:
	ld bc,0x0304	; 1625  01 04 03
Z_1628:
	ld a,0xA0	; 1628  3E A0
Z_162A:
	jp L_1634	; 162A  18 08
L_162C:
Z_162C:
	ld hl,0x6CE8	; 162C  21 E8 6C
Z_162F:
	ld bc,0x0302	; 162F  01 02 03
Z_1632:
	ld a,0x50	; 1632  3E 50
L_1634:
Z_1634:
	call L_1828	; 1634  CD 28 18
Z_1637:
	ld a,(D_1642)	; 1637  3A 42 16
Z_163A:
	add a,0x0F	; 163A  C6 0F
Z_163C:
	ld (D_1642),a	; 163C  32 42 16
Z_163F:
	jp RET_STUB	; 163F  C3 F8 1C
D_1642:
Z_1642:
	db	0x00	; 1642
L_1643:
Z_1643:
	call il_iy_ldb	; 1643  FD 46 01
	db 0x01
Z_1646:
	ld c,0x38	; 1646  0E 38
Z_1648:
	ld a,0x17	; 1648  3E 17
Z_164A:
	jp L_15CF	; 164A  C3 CF 15
L_164D:
Z_164D:
	call il_iy_lda	; 164D  FD 7E 06
	db 0x06
Z_1650:
	and a	; 1650  A7
Z_1651:
	ret nz	; 1651  C0
Z_1652:
	ld a,0x19	; 1652  3E 19
Z_1654:
	jp L_1672	; 1654  18 1C
L_1656:
Z_1656:
	ld e,0x17	; 1656  1E 17
Z_1658:
	jp L_165C	; 1658  18 02
L_165A:
Z_165A:
	ld e,0x18	; 165A  1E 18
L_165C:
Z_165C:
	call il_iy_lda	; 165C  FD 7E 06
	db 0x06
Z_165F:
	and a	; 165F  A7
Z_1660:
	jp nz,L_1670	; 1660  20 0E
Z_1662:
	ld a,e	; 1662  7B
Z_1663:
	call il_exaf	; 1663  08
Z_1664:
	ld a,0x39	; 1664  3E 39
Z_1666:
	add a,d	; 1666  82
Z_1667:
	ld c,a	; 1667  4F
Z_1668:
	call il_exaf	; 1668  08
Z_1669:
	push bc	; 1669  C5
Z_166A:
	push de	; 166A  D5
Z_166B:
	call L_19A0	; 166B  CD A0 19
Z_166E:
	pop de	; 166E  D1
Z_166F:
	pop bc	; 166F  C1
L_1670:
Z_1670:
	ld a,0x16	; 1670  3E 16
L_1672:
Z_1672:
	call il_exaf	; 1672  08
Z_1673:
	ld a,0x50	; 1673  3E 50
Z_1675:
	add a,d	; 1675  82
Z_1676:
	ld c,a	; 1676  4F
Z_1677:
	call il_exaf	; 1677  08
Z_1678:
	jp L_19A0	; 1678  C3 A0 19
LEVEL_VARS:
Z_167B:
	db	0x35,0x35,0x90,0x1C,0x80,0x0F,0x50,0x00,0x00,0x00,0x00,0x00,0x00	; 167B
JUMP_TABLE_1688:
Z_1688:
	dw	L_165A	; 1688  5A 16
Z_168A:
	dw	L_1656	; 168A  56 16
Z_168C:
	dw	L_164D	; 168C  4D 16
Z_168E:
	dw	L_1612	; 168E  12 16
Z_1690:
	dw	L_161F	; 1690  1F 16
Z_1692:
	dw	L_162C	; 1692  2C 16
L_1694:
Z_1694:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
Z_16B9:
	ld hl,0x3E	; 16B9  21 3E 00
Z_16BC:
	ld b,0x00	; 16BC  06 00
L_16BE:
Z_16BE:
	in a,(0x1F)	; 16BE  DB 1F
Z_16C0:
	ld (il_a),a	; 16C0  CB 6F
	and 0x20
	ld a,(il_a)
Z_16C2:
	jp nz,L_16C9	; 16C2  20 05
Z_16C4:
	dec b	; 16C4  10 F8
	jp nz,L_16BE
Z_16C6:
	ld hl,0x1FDB	; 16C6  21 DB 1F
L_16C9:
Z_16C9:
	ld (L_157B),hl	; 16C9  22 7B 15  ; в каноне +0x100 этот операнд стухший
Z_16CC:
	ret	; 16CC  C9
L_16CD:
Z_16CD:
	ld de,0x18	; 16CD  11 18 00
Z_16D0:
	ld b,0x7F	; 16D0  06 7F
Z_16D2:
	ld hl,HUD_TILES	; 16D2  21 56 9B
Z_16D5:
	jp L_16F9	; 16D5  C3 F9 16
L_16D8:
Z_16D8:
	ld de,0x011D	; 16D8  11 1D 01
Z_16DB:
	ld hl,0x21E8	; 16DB  21 E8 21
L_16DE:
Z_16DE:
	and a	; 16DE  A7
Z_16DF:
	jp z,L_16EC	; 16DF  28 0B
Z_16E1:
	dec a	; 16E1  3D
Z_16E2:
	dec de	; 16E2  1B
Z_16E3:
	dec de	; 16E3  1B
Z_16E4:
	push af	; 16E4  F5
Z_16E5:
	ld a,l	; 16E5  7D
Z_16E6:
	sub 0x10	; 16E6  D6 10
Z_16E8:
	ld l,a	; 16E8  6F
Z_16E9:
	pop af	; 16E9  F1
Z_16EA:
	jp L_16DE	; 16EA  18 F2
L_16EC:
Z_16EC:
	ld a,0xA0	; 16EC  3E A0
Z_16EE:
	ld bc,0x0402	; 16EE  01 02 04
Z_16F1:
	call L_1828	; 16F1  CD 28 18
Z_16F4:
	ld b,0x0B	; 16F4  06 0B
Z_16F6:
	ld hl,HUD_TILES+0x98	; 16F6  21 EE 9B
L_16F9:
Z_16F9:
	push bc	; 16F9  C5
Z_16FA:
	push de	; 16FA  D5
Z_16FB:
	push hl	; 16FB  E5
Z_16FC:
	ld a,(hl)	; 16FC  7E
Z_16FD:
	cp 0x20	; 16FD  FE 20
Z_16FF:
	jp c,L_170E	; 16FF  38 0D
Z_1701:
	call L_1736	; 1701  CD 36 17
Z_1704:
	pop hl	; 1704  E1
Z_1705:
	pop de	; 1705  D1
Z_1706:
	inc hl	; 1706  23
Z_1707:
	call L_1719	; 1707  CD 19 17
L_170A:
Z_170A:
	pop bc	; 170A  C1
Z_170B:
	dec b	; 170B  10 EC
	jp nz,L_16F9
Z_170D:
	ret	; 170D  C9
L_170E:
Z_170E:
	pop hl	; 170E  E1
Z_170F:
	inc hl	; 170F  23
Z_1710:
	pop de	; 1710  D1
Z_1711:
	ld b,a	; 1711  47
L_1712:
Z_1712:
	call L_1719	; 1712  CD 19 17
Z_1715:
	dec b	; 1715  10 FB
	jp nz,L_1712
Z_1717:
	jp L_170A	; 1717  18 F1
L_1719:
Z_1719:
	inc de	; 1719  13
Z_171A:
	ld a,0x1F	; 171A  3E 1F
Z_171C:
	cp e	; 171C  BB
Z_171D:
	ret nc	; 171D  D0
Z_171E:
	ld e,0x00	; 171E  1E 00
Z_1720:
	inc d	; 1720  14
Z_1721:
	ret	; 1721  C9
Z_1722:
	jp nz,L_1729	; 1722  20 05
Z_1724:
	ld a,l	; 1724  7D
Z_1725:
	sub 0x08	; 1725  D6 08
Z_1727:
	ld l,a	; 1727  6F
Z_1728:
	inc h	; 1728  24
L_1729:
Z_1729:
	inc l	; 1729  2C
Z_172A:
	pop bc	; 172A  C1
Z_172B:
	dec b	; 172B  05
Z_172C:
	jp nz,L_1A49	; 172C  C2 49 1A  ; в каноне +0x100 этот операнд стухший
Z_172F:
	ret	; 172F  C9
D_1730:
Z_1730:
	db	0xC8,0xC1,0xC5,0xAF,0xBB,0xC4	; 1730
L_1736:
Z_1736:
	ld hl,HUD_TILES+0x8C	; 1736  21 E2 9B
Z_1739:
	ld bc,0x08	; 1739  01 08 00
L_173C:
Z_173C:
	dec a	; 173C  3D
Z_173D:
	jp z,L_1742	; 173D  28 03
Z_173F:
	add hl,bc	; 173F  09
Z_1740:
	jp L_173C	; 1740  18 FA
L_1742:
Z_1742:
	ex de,hl	; 1742  EB
Z_1743:
	call L_175F	; 1743  CD 5F 17
Z_1746:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
Z_174B:
	ld c,a	; 174B  4F
Z_174C:
	ld a,(de)	; 174C  1A
L_174D:
Z_174D:
	nop	; 174D  00
L_175F:
Z_175F:
	ld (il_a),a	; 175F  CB 25
	ld a,l
	add a,a
	ld l,a
	ld a,(il_a)
Z_1761:
	ld (il_a),a	; 1761  CB 25
	ld a,l
	add a,a
	ld l,a
	ld a,(il_a)
Z_1763:
	ld (il_a),a	; 1763  CB 25
	ld a,l
	add a,a
	ld l,a
	ld a,(il_a)
Z_1765:
	ret	; 1765  C9
Z_1766:
	rla	; 1766  17
Z_1767:
	sub h	; 1767  94
Z_1768:
	ld h,a	; 1768  67
Z_1769:
	ret	; 1769  C9
L_176A:
Z_176A:
	ld b,0x0B	; 176A  06 0B
Z_176C:
	ld a,0x36	; 176C  3E 36
Z_176E:
	ld hl,PARAM_TABLE_17AA+0x24	; 176E  21 CE 17
L_1771:
Z_1771:
	ld e,(hl)	; 1771  5E
Z_1772:
	inc hl	; 1772  23
Z_1773:
	ld d,(hl)	; 1773  56
Z_1774:
	inc hl	; 1774  23
Z_1775:
	ld (de),a	; 1775  12
Z_1776:
	dec b	; 1776  10 F9
	jp nz,L_1771
Z_1778:
	ld b,0x09	; 1778  06 09
L_177A:
Z_177A:
	ld e,(hl)	; 177A  5E
Z_177B:
	inc hl	; 177B  23
Z_177C:
	ld d,(hl)	; 177C  56
Z_177D:
	inc hl	; 177D  23
Z_177E:
	ld a,(hl)	; 177E  7E
Z_177F:
	inc hl	; 177F  23
Z_1780:
	ld (de),a	; 1780  12
Z_1781:
	dec b	; 1781  10 F7
	jp nz,L_177A
Z_1783:
	ld de,0x7F9C	; 1783  11 9C 7F
Z_1786:
	ld bc,0x08	; 1786  01 08 00
Z_1789:
	call il_ldir	; 1789  ED B0
Z_178B:
	call il_rnd	; 178B  ED 5F
Z_178D:
	and 0x0F	; 178D  E6 0F
Z_178F:
	inc a	; 178F  3C
Z_1790:
	ld hl,PARAM_TABLE_17AA	; 1790  21 AA 17
L_1793:
Z_1793:
	dec a	; 1793  3D
Z_1794:
	jp z,L_179A	; 1794  28 04
Z_1796:
	inc hl	; 1796  23
Z_1797:
	inc hl	; 1797  23
Z_1798:
	jp L_1793	; 1798  18 F9
L_179A:
Z_179A:
	ld de,LEVEL_VARS+0x1	; 179A  11 7C 16
Z_179D:
	ld bc,0x06	; 179D  01 06 00
Z_17A0:
	call il_ldir	; 17A0  ED B0
Z_17A2:
	xor a	; 17A2  AF
Z_17A3:
	ld b,0x06	; 17A3  06 06
L_17A5:
Z_17A5:
	ld (de),a	; 17A5  12
Z_17A6:
	inc de	; 17A6  13
Z_17A7:
	dec b	; 17A7  10 FC
	jp nz,L_17A5
Z_17A9:
	ret	; 17A9  C9
PARAM_TABLE_17AA:
Z_17AA:
	db	0x09,0x78,0x35,0x90,0x1C,0x80,0x0F,0x50,0x44,0x20,0x12,0x88,0x4D,0x24,0x23,0x3C	; 17AA
Z_17BA:
	db	0x43,0x60,0x3C,0x90,0x27,0x58,0x48,0x50,0x50,0x28,0x2E,0x50,0x1E,0x98,0x45,0x04	; 17BA
Z_17CA:
	db	0x1A,0x98,0x53,0x90	; 17CA
Z_17CE:
	dw	ROOM_MAPS+0x201	; 17CE  48 6A
Z_17D0:
	dw	ROOM_MAPS+0x597	; 17D0  DE 6D
Z_17D2:
	dw	ROOM_MAPS+0xA65	; 17D2  AC 72
Z_17D4:
	dw	ROOM_MAPS+0xD67	; 17D4  AE 75
Z_17D6:
	dw	ROOM_MAPS+0x2105	; 17D6  4C 89
Z_17D8:
	dw	ROOM_MAPS+0x1933	; 17D8  7A 81
Z_17DA:
	dw	ROOM_MAPS+0x1E35	; 17DA  7C 86
Z_17DC:
	dw	ROOM_MAPS+0x1E39	; 17DC  80 86
Z_17DE:
	dw	ROOM_MAPS+0x1E3D	; 17DE  84 86
Z_17E0:
	dw	ROOM_MAPS+0x1F19	; 17E0  60 87
Z_17E2:
	dw	ROOM_MAPS+0x1F1D	; 17E2  64 87
Z_17E4:
	dw	ROOM_MAPS+0x180	; 17E4  C7 69
Z_17E6:
	db	0x23	; 17E6
Z_17E7:
	dw	ROOM_MAPS+0x7B6	; 17E7  FD 6F
Z_17E9:
	db	0x2A	; 17E9
Z_17EA:
	dw	ROOM_MAPS+0x9F8	; 17EA  3F 72
Z_17EC:
	db	0x24	; 17EC
Z_17ED:
	dw	ROOM_MAPS+0xC7C	; 17ED  C3 74
Z_17EF:
	db	0x23	; 17EF
Z_17F0:
	dw	ROOM_MAPS+0x1992	; 17F0  D9 81
Z_17F2:
	db	0x18	; 17F2
Z_17F3:
	dw	ROOM_MAPS+0x19F8	; 17F3  3F 82
Z_17F5:
	db	0x1A	; 17F5
Z_17F6:
	dw	ROOM_MAPS+0x1E00	; 17F6  47 86
Z_17F8:
	db	0x15	; 17F8
Z_17F9:
	dw	ROOM_MAPS+0x1EBC	; 17F9  03 87
Z_17FB:
	db	0x23	; 17FB
Z_17FC:
	dw	ROOM_MAPS+0x2090	; 17FC  D7 88
Z_17FE:
	db	0x20,0x14,0x40,0x90,0xBD,0x14,0x30,0x90,0xBD	; 17FE
L_1807:
Z_1807:
	ld hl,0x20C0	; 1807  21 C0 20
Z_180A:
	ld de,VRAM_COLOR_ROWS	; 180A  11 22 9C
Z_180D:
	ld c,0x18	; 180D  0E 18
L_180F:
Z_180F:
	push hl	; 180F  E5
Z_1810:
	ld b,0x08	; 1810  06 08
L_1812:
Z_1812:
	push bc	; 1812  C5
Z_1813:
	ld bc,0x08	; 1813  01 08 00
Z_1816:
	ld a,(de)	; 1816  1A
Z_1817:
	call VDP_FILL	; 1817  CD 11 1C
Z_181A:
	inc de	; 181A  13
Z_181B:
	ld bc,0x08	; 181B  01 08 00
Z_181E:
	add hl,bc	; 181E  09
Z_181F:
	pop bc	; 181F  C1
Z_1820:
	dec b	; 1820  10 F0
	jp nz,L_1812
Z_1822:
	pop hl	; 1822  E1
Z_1823:
	inc h	; 1823  24
Z_1824:
	dec c	; 1824  0D
Z_1825:
	jp nz,L_180F	; 1825  20 E8
Z_1827:
	ret	; 1827  C9
L_1828:
Z_1828:
	ld (il_a),a	; 1828  CB 01
	ld a,c
	rlca
	ld c,a
	ld a,(il_a)
Z_182A:
	ld (il_a),a	; 182A  CB 01
	ld a,c
	rlca
	ld c,a
	ld a,(il_a)
Z_182C:
	ld (il_a),a	; 182C  CB 01
	ld a,c
	rlca
	or a
	ld c,a
	ld a,(il_a)
L_182E:
Z_182E:
	push bc	; 182E  C5
Z_182F:
	push hl	; 182F  E5
Z_1830:
	ld b,0x00	; 1830  06 00
Z_1832:
	call VDP_FILL	; 1832  CD 11 1C
Z_1835:
	pop hl	; 1835  E1
Z_1836:
	ld bc,0x0100	; 1836  01 00 01
Z_1839:
	add hl,bc	; 1839  09
Z_183A:
	pop bc	; 183A  C1
Z_183B:
	dec b	; 183B  10 F1
	jp nz,L_182E
Z_183D:
	ret	; 183D  C9
L_183E:
Z_183E:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
Z_1841:
	ld hl,0x2900	; 1841  21 00 29
Z_1844:
	ld bc,0x0100	; 1844  01 00 01
Z_1847:
	ld a,0xA1	; 1847  3E A1
Z_1849:
	call VDP_FILL	; 1849  CD 11 1C
Z_184C:
	inc h	; 184C  24
Z_184D:
	ld bc,0x0100	; 184D  01 00 01
Z_1850:
	ld a,0x71	; 1850  3E 71
Z_1852:
	call VDP_FILL	; 1852  CD 11 1C
Z_1855:
	inc h	; 1855  24
Z_1856:
	ld bc,0x0100	; 1856  01 00 01
Z_1859:
	ld a,0xC1	; 1859  3E C1
Z_185B:
	call VDP_FILL	; 185B  CD 11 1C
Z_185E:
	ld a,0xA9	; 185E  3E A9
Z_1860:
	ld (L_174D),a	; 1860  32 4D 17
L_1863:
Z_1863:
	ld b,0x06	; 1863  06 06
Z_1865:
	ld hl,TEXT_ES+0x29	; 1865  21 09 9A
Z_1868:
	ld de,BUF_1890+0x14	; 1868  11 A4 18
L_186B:
Z_186B:
	push bc	; 186B  C5
Z_186C:
	ld a,(de)	; 186C  1A
Z_186D:
	ld b,a	; 186D  47
Z_186E:
	push hl	; 186E  E5
Z_186F:
	push de	; 186F  D5
Z_1870:
	ld de,0x1108	; 1870  11 08 11
Z_1873:
	call L_16F9	; 1873  CD F9 16
Z_1876:
	call L_1921	; 1876  CD 21 19
Z_1879:
	pop de	; 1879  D1
Z_187A:
	pop hl	; 187A  E1
Z_187B:
	ld a,(de)	; 187B  1A
Z_187C:
	ld c,a	; 187C  4F
Z_187D:
	ld b,0x00	; 187D  06 00
Z_187F:
	add hl,bc	; 187F  09
Z_1880:
	inc de	; 1880  13
Z_1881:
	pop bc	; 1881  C1
Z_1882:
	call L_18AA	; 1882  CD AA 18
Z_1885:
	jp nz,L_188B	; 1885  20 04
Z_1887:
	dec b	; 1887  10 E2
	jp nz,L_186B
Z_1889:
	jp L_1863	; 1889  18 D8
L_188B:
Z_188B:
	xor a	; 188B  AF
Z_188C:
	ld (L_174D),a	; 188C  32 4D 17
Z_188F:
	ret	; 188F  C9
BUF_1890:
Z_1890:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 1890
Z_18A0:
	db	0x00,0x00,0x00,0x00,0x13,0x1D,0x1C,0x1E,0x18,0x17	; 18A0
L_18AA:
Z_18AA:
	call L_18AD	; 18AA  CD AD 18
L_18AD:
Z_18AD:
	push bc	; 18AD  C5
Z_18AE:
	push hl	; 18AE  E5
Z_18AF:
	ld h,0x46	; 18AF  26 46
L_18B1:
Z_18B1:
	ld b,0xF0	; 18B1  06 F0
L_18B3:
Z_18B3:
	ld a,b	; 18B3  78
Z_18B4:
	out (0xAA),a	; 18B4  D3 AA
Z_18B6:
	in a,(0xA9)	; 18B6  DB A9
Z_18B8:
	cp 0xFF	; 18B8  FE FF
Z_18BA:
	jp nz,L_18C7	; 18BA  20 0B
Z_18BC:
	inc b	; 18BC  04
Z_18BD:
	ld a,0xF9	; 18BD  3E F9
Z_18BF:
	cp b	; 18BF  B8
Z_18C0:
	jp z,L_18B1	; 18C0  28 EF
Z_18C2:
	dec hl	; 18C2  2B
Z_18C3:
	ld a,h	; 18C3  7C
Z_18C4:
	or l	; 18C4  B5
Z_18C5:
	jp nz,L_18B3	; 18C5  20 EC
L_18C7:
Z_18C7:
	pop hl	; 18C7  E1
Z_18C8:
	pop bc	; 18C8  C1
Z_18C9:
	ret	; 18C9  C9
L_18CA:
Z_18CA:
	ld hl,0x1B00	; 18CA  21 00 1B
Z_18CD:
	ld bc,0x80	; 18CD  01 80 00
Z_18D0:
	ld a,0xD1	; 18D0  3E D1
Z_18D2:
	call VDP_FILL	; 18D2  CD 11 1C
Z_18D5:
	ld bc,0x1800	; 18D5  01 00 18
Z_18D8:
	ld hl,0x00	; 18D8  21 00 00
Z_18DB:
	xor a	; 18DB  AF
Z_18DC:
	call VDP_FILL	; 18DC  CD 11 1C
Z_18DF:
	ld bc,0x1800	; 18DF  01 00 18
Z_18E2:
	ld hl,0x2000	; 18E2  21 00 20
Z_18E5:
	ld a,0x11	; 18E5  3E 11
Z_18E7:
	jp VDP_FILL	; 18E7  C3 11 1C
DEAD_18EA:
Z_18EA:
	db	0xF1,0xD3,0x98,0x78,0xB1,0x20,0xE9,0xDD,0xE1,0x11,0x64,0x00,0xDD,0x19,0xE1,0xC1	; 18EA
Z_18FA:
	db	0x10,0xD7,0x01,0x00,0x18,0x21,0x00	; 18FA
D_1900:
Z_1900:
	db	0x00,0x00,0xAF,0x00,0x00,0x00,0x01	; 1900
L_1907:
Z_1907:
	ld a,0xC9	; 1907  3E C9
Z_1909:
	ld (L_1FA9),a	; 1909  32 A9 1F
Z_190C:
	call L_0834	; 190C  CD 34 08
Z_190F:
	call L_1D9B	; 190F  CD 9B 1D
Z_1912:
	call L_0F4A	; 1912  CD 4A 0F
Z_1915:
	ld a,0xCD	; 1915  3E CD
Z_1917:
	ld (L_1FA9),a	; 1917  32 A9 1F
Z_191A:
	ret	; 191A  C9
D_191B:
Z_191B:
	db	0x02,0xD2,0x32,0x11,0xD3,0xC9	; 191B
L_1921:
Z_1921:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
Z_1966:
	jp VDP_FILL	; 1966  C3 11 1C
D_1969:
Z_1969:
	db	0xFF	; 1969
SCR_ADDR_BIT13:
Z_1992:
	ld a,c	; 1992  79
Z_1993:
	and 0xF8	; 1993  E6 F8
Z_1995:
	rrca	; 1995  0F
Z_1996:
	rrca	; 1996  0F
Z_1997:
	rrca	; 1997  0F
Z_1998:
	ld h,a	; 1998  67
Z_1999:
	ld a,b	; 1999  78
Z_199A:
	and 0xF8	; 199A  E6 F8
Z_199C:
	ld l,a	; 199C  6F
Z_199D:
	push af	; 199D  CB EC
	ld a,h
	or 0x20
	ld h,a
	pop af
Z_199F:
	ret	; 199F  C9
L_19A0:
Z_19A0:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
L_19F2:
Z_19F2:
	ld (il_tmp),hl	; 19F2  DD 21 29 3B  ; в каноне +0x100 этот операнд стухший  ; ВПЕЧЁННАЯ ВРЕЗКА: res:D0F2 ld ix,F229 -> 3B32: затравка цепочки за концом буфера зеркалирования (BYTE_TAB 19F4)
	ld hl,WORK_RAM+0x8A
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_19F6:
	call il_ix_stn	; 19F6  DD 36 FF FF
	db 0xFF, 0xFF
Z_19FA:
	call il_ix_stn	; 19FA  DD 36 FD 00
	db 0xFD, 0x00
Z_19FE:
	call il_ix_stn	; 19FE  DD 36 FE F8  ; ВПЕЧЁННАЯ ВРЕЗКА: res:D0FE ld (ix-2),0xF8 -> 0x41: теневые образы спрайтов 4100, а не F800 (BYTE_TAB 1A01)
	db 0xFE, 0x41
Z_1A02:
	jp L_1D90	; 1A02  21 7E 40  ; в каноне +0x100 этот операнд стухший  ; ВПЕЧЁННАЯ ВРЕЗКА: ЭТАП E: обе чистки теневых таблиц выброшены, сразу на сброс указателей (BYTE_TAB 1A02..1A04)
Z_1A1F:
	ld (WORK_RAM+0x5D6),hl	; 1A1F  22 7E 40  ; в каноне +0x100 этот операнд стухший
Z_1A22:
	ret	; 1A22  C9
D_1A23:
Z_1A23:
	db	0x00	; 1A23
L_1A24:
Z_1A24:
	ld a,(D_1A23)	; 1A24  3A 23 1A
Z_1A27:
	and a	; 1A27  A7
Z_1A28:
	jp z,L_1F64	; 1A28  CA 64 1F
Z_1A2B:
	push hl	; 1A2B  ED 5B 16 1D
	ld hl,(D_1D08+0xE)
	ld d,h
	ld e,l
	pop hl
Z_1A2F:
	ld hl,WORK_RAM+0x656	; 1A2F  21 FE 40  ; в каноне +0x100 этот операнд стухший
Z_1A32:
	and a	; 1A32  A7
Z_1A33:
	ld a,l	; 1A33  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
Z_1A35:
	ld (il_a),a	; 1A35  CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_1A37:
	ld (il_a),a	; 1A37  CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_1A39:
	ld b,l	; 1A39  45
Z_1A3A:
	dec de	; 1A3A  1B
Z_1A3B:
	ld hl,WORK_RAM+0x655	; 1A3B  21 FD 40  ; в каноне +0x100 этот операнд стухший
Z_1A3E:
	jp L_1F55	; 1A3E  C3 55 1F
L_1A49:
Z_1A49:
	ld b,0x00	; 1A49  06 00
Z_1A4B:
	add hl,bc	; 1A4B  09
Z_1A4C:
	pop bc	; 1A4C  C1
Z_1A4D:
	nop	; 1A4D  00
L_1A4E:
Z_1A4E:
	push bc	; 1A4E  C5
Z_1A4F:
	push hl	; 1A4F  E5
L_1A50:
Z_1A50:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
L_1A6C:
Z_1A6C:
	ld hl,ROOM_MAPS-0x1	; 1A6C  21 46 68
Z_1A6F:
	ld b,0x00	; 1A6F  06 00
L_1A71:
Z_1A71:
	and a	; 1A71  A7
Z_1A72:
	ret z	; 1A72  C8
Z_1A73:
	dec a	; 1A73  3D
Z_1A74:
	ld c,0x04	; 1A74  0E 04
Z_1A76:
	add hl,bc	; 1A76  09
Z_1A77:
	ld c,(hl)	; 1A77  4E
Z_1A78:
	inc hl	; 1A78  23
Z_1A79:
	inc hl	; 1A79  23
Z_1A7A:
	add hl,bc	; 1A7A  09
Z_1A7B:
	add hl,bc	; 1A7B  09
Z_1A7C:
	add hl,bc	; 1A7C  09
Z_1A7D:
	add hl,bc	; 1A7D  09
Z_1A7E:
	jp L_1A71	; 1A7E  18 F1
D_1A80:
Z_1A80:
	db	0xC9,0x00,0x06,0x18	; 1A80
L_1A84:
Z_1A84:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
Z_1A87:
	jp z,L_1A8B	; 1A87  28 02
Z_1A89:
	ld a,0x60	; 1A89  3E 60
L_1A8B:
Z_1A8B:
	ld (L_1AA4+0x1),a	; 1A8B  32 A5 1A
Z_1A8E:
	ld a,b	; 1A8E  78
Z_1A8F:
	and 0x7F	; 1A8F  E6 7F
Z_1A91:
	call L_1A6C	; 1A91  CD 6C 1A
Z_1A94:
	ld de,D_1D08	; 1A94  11 08 1D
Z_1A97:
	ld bc,0x04	; 1A97  01 04 00
Z_1A9A:
	call il_ldir	; 1A9A  ED B0
Z_1A9C:
	inc hl	; 1A9C  23
Z_1A9D:
	ld b,(hl)	; 1A9D  46
Z_1A9E:
	inc hl	; 1A9E  23
L_1A9F:
Z_1A9F:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
Z_1AA2:
	inc hl	; 1AA2  23
Z_1AA3:
	ld a,(hl)	; 1AA3  7E
L_1AA4:
Z_1AA4:
	add a,0x00	; 1AA4  C6 00
L_1ABD:
Z_1ABD:
	push af	; 1ABD  F5
Z_1ABE:
	call SCR_ADDR_BIT13	; 1ABE  CD 92 19
Z_1AC1:
	pop af	; 1AC1  F1
L_1AC2:
Z_1AC2:
	push hl	; 1AC2  E5
Z_1AC3:
	call L_1DB8	; 1AC3  CD B8 1D
Z_1AC6:
	cp 0x31	; 1AC6  FE 31
Z_1AC8:
	jp z,L_1AD2	; 1AC8  28 08
Z_1ACA:
	cp 0x51	; 1ACA  FE 51
Z_1ACC:
	jp c,L_1AD4	; 1ACC  38 06
Z_1ACE:
	cp 0x54	; 1ACE  FE 54
Z_1AD0:
	jp nc,L_1AD4	; 1AD0  30 02
L_1AD2:
Z_1AD2:
	ld (hl),0x20	; 1AD2  36 20
L_1AD4:
Z_1AD4:
	ld b,a	; 1AD4  47
Z_1AD5:
	call SPR_BANK_A89C	; 1AD5  CD 4C 1B
Z_1AD8:
	ld b,(hl)	; 1AD8  46
Z_1AD9:
	inc hl	; 1AD9  23
Z_1ADA:
	ld c,(hl)	; 1ADA  4E
Z_1ADB:
	inc hl	; 1ADB  23
Z_1ADC:
	ex de,hl	; 1ADC  EB
Z_1ADD:
	pop hl	; 1ADD  E1
L_1ADE:
Z_1ADE:
	push bc	; 1ADE  C5
Z_1ADF:
	push hl	; 1ADF  E5
L_1AE0:
Z_1AE0:
	push bc	; 1AE0  C5
Z_1AE1:
	call L_1DCF	; 1AE1  CD CF 1D
Z_1AE4:
	ld a,(de)	; 1AE4  1A
Z_1AE5:
	ld bc,0x08	; 1AE5  01 08 00
Z_1AE8:
	call VDP_FILL	; 1AE8  CD 11 1C
Z_1AEB:
	ld a,0x08	; 1AEB  3E 08
Z_1AED:
	add a,l	; 1AED  85
Z_1AEE:
	ld l,a	; 1AEE  6F
Z_1AEF:
	inc de	; 1AEF  13
Z_1AF0:
	pop bc	; 1AF0  C1
Z_1AF1:
	dec c	; 1AF1  0D
Z_1AF2:
	jp nz,L_1AE0	; 1AF2  20 EC
Z_1AF4:
	pop hl	; 1AF4  E1
Z_1AF5:
	inc h	; 1AF5  24
Z_1AF6:
	pop bc	; 1AF6  C1
Z_1AF7:
	dec b	; 1AF7  10 E5
	jp nz,L_1ADE
Z_1AF9:
	ret	; 1AF9  C9
D_1AFA:
Z_1AFA:
	db	0xE7,0xE1,0x24,0xC1,0x10,0xE0,0xC9,0xC9	; 1AFA
L_1B02:
Z_1B02:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
VDP_WR_STRIDE8:
Z_1B1D:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
SPR_HDR:
Z_1B44:
	call SPR_BANK_HI	; 1B44  CD 58 1B
Z_1B47:
	ld b,(hl)	; 1B47  46
Z_1B48:
	inc hl	; 1B48  23
Z_1B49:
	ld a,(hl)	; 1B49  7E
Z_1B4A:
	inc hl	; 1B4A  23
Z_1B4B:
	ret	; 1B4B  C9
SPR_BANK_A89C:
Z_1B4C:
	ld hl,SPR_DATA_8B9C	; 1B4C  21 9C 8B
Z_1B4F:
	xor a	; 1B4F  AF
Z_1B50:
	jp L_1B5D	; 1B50  18 0B
SPR_BANK_VAR:
Z_1B52:
	ld hl,SPR_DATA_8E76	; 1B52  21 76 8E
Z_1B55:
	xor a	; 1B55  AF
Z_1B56:
	jp L_1B5D	; 1B56  18 05
SPR_BANK_HI:
Z_1B58:
	ld hl,SPR_BANK_294B	; 1B58  21 4B 29
Z_1B5B:
	ld a,0x00	; 1B5B  3E 00
L_1B5D:
Z_1B5D:
	ld (L_1B6A),a	; 1B5D  32 6A 1B
Z_1B60:
	ld a,b	; 1B60  78
Z_1B61:
	ld d,0x00	; 1B61  16 00
L_1B63:
Z_1B63:
	and a	; 1B63  A7
Z_1B64:
	ret z	; 1B64  C8
Z_1B65:
	dec a	; 1B65  3D
Z_1B66:
	ld e,(hl)	; 1B66  5E
Z_1B67:
	inc hl	; 1B67  23
Z_1B68:
	ld b,(hl)	; 1B68  46
Z_1B69:
	inc hl	; 1B69  23
L_1B6A:
Z_1B6A:
	nop	; 1B6A  00
Z_1B6B:
	add hl,de	; 1B6B  19
Z_1B6C:
	dec b	; 1B6C  10 FC
	jp nz,L_1B6A
Z_1B6E:
	jp L_1B63	; 1B6E  18 F3
SCR_ADDR_BIT14:
Z_1B70:
	ld a,c	; 1B70  79
Z_1B71:
	and 0xF8	; 1B71  E6 F8
Z_1B73:
	rrca	; 1B73  0F
Z_1B74:
	rrca	; 1B74  0F
Z_1B75:
	rrca	; 1B75  0F
Z_1B76:
	ld h,a	; 1B76  67
Z_1B77:
	ld a,b	; 1B77  78
	jp	Z_1B78	; мост в следующий кусок
	org	0x1F00
Z_1B78:
	and 0xF8	; 1B78  E6 F8
Z_1B7A:
	ld l,a	; 1B7A  6F
Z_1B7B:
	ld a,c	; 1B7B  79
Z_1B7C:
	and 0x07	; 1B7C  E6 07
Z_1B7E:
	add a,l	; 1B7E  85
Z_1B7F:
	ld l,a	; 1B7F  6F
Z_1B80:
	ld a,b	; 1B80  78
Z_1B81:
	and 0x07	; 1B81  E6 07
Z_1B83:
	ld b,a	; 1B83  47
Z_1B84:
	push af	; 1B84  CB F4
	ld a,h
	or 0x40
	ld h,a
	pop af
Z_1B86:
	ret	; 1B86  C9
Z_1B87:
	ld hl,WORK_RAM+0x1A5	; 1B87  21 4D 3C  ; в каноне +0x100 этот операнд стухший
Z_1B8A:
	ld de,WORK_RAM+0x1A5	; 1B8A  11 4D 3C  ; в каноне +0x100 этот операнд стухший
Z_1B8D:
	jp L_1B95	; 1B8D  18 06
D_1B8F:
Z_1B8F:
	db	0x21,0x6D,0xF4,0x11,0x6D,0xF4	; 1B8F
L_1B95:
Z_1B95:
	ld bc,0x0120	; 1B95  01 20 01
Z_1B98:
	jp L_1BA3	; 1B98  18 09
D_1B9A:
Z_1B9A:
	db	0x21,0x4D,0xF3,0x11,0x4D,0xF3,0x01,0x40,0x02	; 1B9A
L_1BA3:
Z_1BA3:
	call il_ldir	; 1BA3  ED B0
Z_1BA5:
	ret	; 1BA5  C9
Z_1BA6:
	call il_ix_lde	; 1BA6  DD 5E FD
	db 0xFD
Z_1BA9:
	call il_ix_ldd	; 1BA9  DD 56 FE
	db 0xFE
Z_1BAC:
	ld a,(D_1D08+0x18)	; 1BAC  3A 20 1D  ; в каноне +0x100 этот операнд стухший
Z_1BAF:
	ld b,a	; 1BAF  47
Z_1BB0:
	ld a,(D_1D08+0x10)	; 1BB0  3A 18 1D  ; в каноне +0x100 этот операнд стухший
Z_1BB3:
	ld c,a	; 1BB3  4F
L_1BB4:
Z_1BB4:
	push bc	; 1BB4  C5
Z_1BB5:
	push de	; 1BB5  D5
Z_1BB6:
	ld b,0x00	; 1BB6  06 00
Z_1BB8:
	call il_ldir	; 1BB8  ED B0
Z_1BBA:
	pop de	; 1BBA  D1
Z_1BBB:
	push hl	; 1BBB  E5
Z_1BBC:
	ld hl,(D_1D08+0x12)	; 1BBC  2A 1A 1D  ; в каноне +0x100 этот операнд стухший
Z_1BBF:
	add hl,de	; 1BBF  19
Z_1BC0:
	ex de,hl	; 1BC0  EB
Z_1BC1:
	pop hl	; 1BC1  E1
Z_1BC2:
	pop bc	; 1BC2  C1
Z_1BC3:
	dec b	; 1BC3  10 EF
	jp nz,L_1BB4
Z_1BC5:
	call il_ix_ste	; 1BC5  DD 73 06
	db 0x06
Z_1BC8:
	call il_ix_std	; 1BC8  DD 72 07
	db 0x07
Z_1BCB:
	ret	; 1BCB  C9
VDP_SET_RADDR:
Z_1BFD:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
VDP_SET_WADDR:
Z_1C06:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
L_1C0C:
Z_1C0C:
	or 0x40	; 1C0C  F6 40
Z_1C0E:
	out (0x99),a	; 1C0E  D3 99
Z_1C10:
	ret	; 1C10  C9
VDP_FILL:
Z_1C11:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
VDP_RD_BYTE:
Z_1C20:
	db	0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 2 б (SCR_PATCH)
Z_1C23:
	ex (sp),hl	; 1C23  E3
Z_1C24:
	ex (sp),hl	; 1C24  E3
Z_1C25:
	in a,(0x98)	; 1C25  DB 98
Z_1C27:
	ret	; 1C27  C9
VDP_WR_BYTE:
Z_1C28:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
VDP_COPY_TO_VRAM:
Z_1C33:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
D_1CAF:
Z_1CAF:
	db	0x07,0x32,0x18,0xD4,0xC9	; 1CAF
VDP_RD_STRIDE8:
Z_1CB4:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
KBD_SCAN:
Z_1CDF:
	push bc	; 1CDF  C5
Z_1CE0:
	ld a,c	; 1CE0  79
Z_1CE1:
	and 0x07	; 1CE1  E6 07
Z_1CE3:
	inc a	; 1CE3  3C
Z_1CE4:
	ld b,a	; 1CE4  47
Z_1CE5:
	ld a,c	; 1CE5  79
Z_1CE6:
	and 0xF0	; 1CE6  E6 F0
Z_1CE8:
	rrca	; 1CE8  0F
Z_1CE9:
	rrca	; 1CE9  0F
Z_1CEA:
	rrca	; 1CEA  0F
Z_1CEB:
	rrca	; 1CEB  0F
Z_1CEC:
	or 0xF0	; 1CEC  F6 F0
Z_1CEE:
	out (0xAA),a	; 1CEE  D3 AA
Z_1CF0:
	nop	; 1CF0  00
Z_1CF1:
	in a,(0xA9)	; 1CF1  DB A9
Z_1CF3:
	cpl	; 1CF3  2F
L_1CF4:
Z_1CF4:
	rrca	; 1CF4  0F
Z_1CF5:
	dec b	; 1CF5  10 FD
	jp nz,L_1CF4
Z_1CF7:
	pop bc	; 1CF7  C1
RET_STUB:
Z_1CF8:
	ret	; 1CF8  C9
D_1CF9:
Z_1CF9:
	db	0xC9,0x48,0x09,0xD6,0x08	; 1CF9
THUNK_CDC5_D00:
Z_1CFE:
	ld d,0x00	; 1CFE  16 00
Z_1D00:
	jp D_15C4+0x1	; 1D00  C3 C5 15
THUNK_CDC5_D60:
Z_1D03:
	ld d,0x60	; 1D03  16 60
Z_1D05:
	jp D_15C4+0x1	; 1D05  C3 C5 15
D_1D08:
Z_1D08:
	db	0x11,0x1B,0x15,0x17,0x11,0x50,0x70,0xB1,0x11,0x50,0x80,0xB1,0xF8,0xD3,0xE2,0xF7	; 1D08
Z_1D18:
	db	0x30,0x02,0x20,0x27,0x1C,0x38,0x01,0xC9,0x02,0xA7,0x10,0x50,0x90,0xD0,0x30,0x70	; 1D18
Z_1D28:
	db	0xB0,0xE0,0x02,0xD1,0x01,0x05,0x08,0x0D,0x02,0x07,0x11,0x0E	; 1D28
L_1D34:
Z_1D34:
	ld a,0x07	; 1D34  3E 07
Z_1D36:
	and l	; 1D36  A5
Z_1D37:
	cp 0x07	; 1D37  FE 07
Z_1D39:
	jp nz,L_1D40	; 1D39  20 05
Z_1D3B:
	ld a,l	; 1D3B  7D
Z_1D3C:
	sub 0x08	; 1D3C  D6 08
Z_1D3E:
	ld l,a	; 1D3E  6F
Z_1D3F:
	inc h	; 1D3F  24
L_1D40:
Z_1D40:
	inc l	; 1D40  2C
Z_1D41:
	pop bc	; 1D41  C1
Z_1D42:
	dec b	; 1D42  05
Z_1D43:
	jp nz,L_1A4E	; 1D43  C2 4E 1A
Z_1D46:
	ret	; 1D46  C9
L_1D71:
Z_1D71:
	push bc	; 1D71  C5
Z_1D72:
	push hl	; 1D72  E5
L_1D73:
Z_1D73:
	ld a,(de)	; 1D73  1A
Z_1D74:
	ld (hl),a	; 1D74  77
Z_1D75:
	inc de	; 1D75  13
Z_1D76:
	push bc	; 1D76  C5
Z_1D77:
	ld bc,0x10	; 1D77  01 10 00
Z_1D7A:
	add hl,bc	; 1D7A  09
Z_1D7B:
	pop bc	; 1D7B  C1
Z_1D7C:
	dec b	; 1D7C  10 F5
	jp nz,L_1D73
Z_1D7E:
	pop hl	; 1D7E  E1
Z_1D7F:
	ld a,0x0F	; 1D7F  3E 0F
Z_1D81:
	and l	; 1D81  A5
Z_1D82:
	cp 0x0F	; 1D82  FE 0F
Z_1D84:
	jp nz,L_1D8A	; 1D84  20 04
L_1D86:
Z_1D86:
	ld bc,0x10	; 1D86  01 10 00
Z_1D89:
	add hl,bc	; 1D89  09
L_1D8A:
Z_1D8A:
	inc hl	; 1D8A  23
Z_1D8B:
	pop bc	; 1D8B  C1
Z_1D8C:
	dec c	; 1D8C  0D
Z_1D8D:
	jp nz,L_1D71	; 1D8D  20 E2
Z_1D8F:
	ret	; 1D8F  C9
L_1D90:
Z_1D90:
	ld hl,WORK_RAM+0x656	; 1D90  21 FE 40  ; в каноне +0x100 этот операнд стухший
Z_1D93:
	ld (D_1D08+0xE),hl	; 1D93  22 16 1D
Z_1D96:
	xor a	; 1D96  AF
Z_1D97:
	ld (D_1D08+0x14),a	; 1D97  32 1C 1D
Z_1D9A:
	ret	; 1D9A  C9
L_1D9B:
Z_1D9B:
	ld hl,WORK_RAM+0x1A5	; 1D9B  21 4D 3C  ; в каноне +0x100 этот операнд стухший
Z_1D9E:
	ld de,WORK_RAM+0x1A6	; 1D9E  11 4E 3C  ; в каноне +0x100 этот операнд стухший
Z_1DA1:
	ld bc,0x0120	; 1DA1  01 20 01
Z_1DA4:
	ld (hl),0x00	; 1DA4  36 00
Z_1DA6:
	call il_ldir	; 1DA6  ED B0
Z_1DA8:
	ret	; 1DA8  C9
L_1DA9:
Z_1DA9:
	ld hl,WORK_RAM+0x2C5	; 1DA9  21 6D 3D  ; в каноне +0x100 этот операнд стухший
Z_1DAC:
	ld de,WORK_RAM+0x2C6	; 1DAC  11 6E 3D  ; в каноне +0x100 этот операнд стухший
Z_1DAF:
	ld bc,0x0120	; 1DAF  01 20 01
Z_1DB2:
	ld (hl),0x00	; 1DB2  36 00
Z_1DB4:
	call il_ldir	; 1DB4  ED B0
Z_1DB6:
	ret	; 1DB6  C9
D_1DB7:
Z_1DB7:
	db	0xBD	; 1DB7
L_1DB8:
Z_1DB8:
	ld hl,L_1DEC+0x1	; 1DB8  21 ED 1D
Z_1DBB:
	ld (hl),0x00	; 1DBB  36 00
Z_1DBD:
	cp 0x55	; 1DBD  FE 55
Z_1DBF:
	ret c	; 1DBF  D8
Z_1DC0:
	sub 0x55	; 1DC0  D6 55
Z_1DC2:
	ld (hl),0x40	; 1DC2  36 40
Z_1DC4:
	cp 0x55	; 1DC4  FE 55
Z_1DC6:
	ret c	; 1DC6  D8
Z_1DC7:
	sub 0x55	; 1DC7  D6 55
Z_1DC9:
	ld (hl),0x80	; 1DC9  36 80
Z_1DCB:
	ret	; 1DCB  C9
D_1DCC:
Z_1DCC:
	db	0x0A,0xC1,0xB0	; 1DCC
L_1DCF:
Z_1DCF:
	push hl	; 1DCF  E5
Z_1DD0:
	ld (il_a),a	; 1DD0  CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_1DD2:
	ld (il_a),a	; 1DD2  CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_1DD4:
	ld (il_a),a	; 1DD4  CB 3D
	ld a,l
	or a
	rra
	ld l,a
	ld a,(il_a)
Z_1DD6:
	ld a,l	; 1DD6  7D
Z_1DD7:
	ld (il_a),a	; 1DD7  CB 24
	ld a,h
	add a,a
	ld h,a
	ld a,(il_a)
Z_1DD9:
	ld (il_a),a	; 1DD9  CB 24
	ld a,h
	add a,a
	ld h,a
	ld a,(il_a)
Z_1DDB:
	ld (il_a),a	; 1DDB  CB 24
	ld a,h
	add a,a
	ld h,a
	ld a,(il_a)
Z_1DDD:
	ld l,h	; 1DDD  6C
Z_1DDE:
	ld h,0x00	; 1DDE  26 00
Z_1DE0:
	ld c,l	; 1DE0  4D
Z_1DE1:
	ld b,h	; 1DE1  44
Z_1DE2:
	add hl,hl	; 1DE2  29
Z_1DE3:
	add hl,bc	; 1DE3  09
Z_1DE4:
	ld c,a	; 1DE4  4F
Z_1DE5:
	ld b,0x00	; 1DE5  06 00
Z_1DE7:
	add hl,bc	; 1DE7  09
Z_1DE8:
	ld bc,WORK_RAM+0x1A5	; 1DE8  01 4D 3C  ; в каноне +0x100 этот операнд стухший
Z_1DEB:
	add hl,bc	; 1DEB  09
L_1DEC:
Z_1DEC:
	ld a,0x00	; 1DEC  3E 00
Z_1DEE:
	ld (hl),a	; 1DEE  77
Z_1DEF:
	pop hl	; 1DEF  E1
Z_1DF0:
	ret	; 1DF0  C9
L_1DF1:
Z_1DF1:
	call L_1D9B	; 1DF1  CD 9B 1D
Z_1DF4:
	jp L_159A	; 1DF4  C3 9A 15
L_1DF7:
Z_1DF7:
	call L_1DA9	; 1DF7  CD A9 1D
Z_1DFA:
	jp L_15A7	; 1DFA  C3 A7 15
ATTR_ADDR:
Z_1F00:
	ld a,c	; 1F00  79
Z_1F01:
	and 0xF8	; 1F01  E6 F8
Z_1F03:
	ld c,a	; 1F03  4F
Z_1F04:
	ld a,b	; 1F04  78
Z_1F05:
	and 0xF8	; 1F05  E6 F8
Z_1F07:
	rra	; 1F07  1F
Z_1F08:
	rra	; 1F08  1F
Z_1F09:
	rra	; 1F09  1F
Z_1F0A:
	ld l,c	; 1F0A  69
Z_1F0B:
	ld h,0x00	; 1F0B  26 00
Z_1F0D:
	ld b,h	; 1F0D  44
Z_1F0E:
	add hl,hl	; 1F0E  29
Z_1F0F:
	add hl,bc	; 1F0F  09
Z_1F10:
	ld bc,WORK_RAM+0x1A5	; 1F10  01 4D 3C  ; в каноне +0x100 этот операнд стухший
Z_1F13:
	add hl,bc	; 1F13  09
Z_1F14:
	ld c,a	; 1F14  4F
Z_1F15:
	ld b,0x00	; 1F15  06 00
Z_1F17:
	add hl,bc	; 1F17  09
Z_1F18:
	ret	; 1F18  C9
L_1F19:
Z_1F19:
	ld b,0x20	; 1F19  06 20
Z_1F1B:
	ld hl,0x5B00	; 1F1B  21 00 5B
L_1F1E:
Z_1F1E:
	call VDP_RD_BYTE	; 1F1E  CD 20 1C
Z_1F21:
	cp 0x60	; 1F21  FE 60
Z_1F23:
	jp nc,L_1F2A	; 1F23  30 05
Z_1F25:
	ld a,0xD1	; 1F25  3E D1
Z_1F27:
	call VDP_WR_BYTE	; 1F27  CD 28 1C
L_1F2A:
Z_1F2A:
	ld a,0x04	; 1F2A  3E 04
Z_1F2C:
	add a,l	; 1F2C  85
Z_1F2D:
	ld l,a	; 1F2D  6F
Z_1F2E:
	dec b	; 1F2E  10 EE
	jp nz,L_1F1E
Z_1F30:
	jp L_0C8C	; 1F30  C3 8C 0C
D_1F33:
Z_1F33:
	db	0xFF,0xFF,0xFF	; 1F33
L_1F36:
Z_1F36:
	xor a	; 1F36  AF
Z_1F37:
	ld a,l	; 1F37  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
Z_1F39:
	ld b,l	; 1F39  45
L_1F3A:
Z_1F3A:
	ld (de),a	; 1F3A  12
Z_1F3B:
	inc de	; 1F3B  13
Z_1F3C:
	dec b	; 1F3C  10 FC
	jp nz,L_1F3A
Z_1F3E:
	ret	; 1F3E  C9
L_1F3F:
Z_1F3F:
	push hl	; 1F3F  E5
Z_1F40:
	push de	; 1F40  D5
Z_1F41:
	push bc	; 1F41  C5
Z_1F42:
	ld hl,WORK_RAM+0x3E5	; 1F42  21 8D 3E  ; в каноне +0x100 этот операнд стухший
Z_1F45:
	ld de,WORK_RAM+0x3E6	; 1F45  11 8E 3E  ; в каноне +0x100 этот операнд стухший
Z_1F48:
	ld bc,0x01F0	; 1F48  01 F0 01
Z_1F4B:
	ld (hl),0x00	; 1F4B  36 00
Z_1F4D:
	call il_ldir	; 1F4D  ED B0
Z_1F4F:
	pop bc	; 1F4F  C1
Z_1F50:
	pop de	; 1F50  D1
Z_1F51:
	pop hl	; 1F51  E1
Z_1F52:
	jp L_0F98	; 1F52  C3 98 0F
L_1F55:
Z_1F55:
	push bc	; 1F55  C5
Z_1F56:
	ld bc,0x03	; 1F56  01 03 00
Z_1F59:
	call il_lddr	; 1F59  ED B8
Z_1F5B:
	ld a,(hl)	; 1F5B  7E
Z_1F5C:
	add a,0x60	; 1F5C  C6 60
Z_1F5E:
	ld (de),a	; 1F5E  12
Z_1F5F:
	dec de	; 1F5F  1B
Z_1F60:
	dec hl	; 1F60  2B
Z_1F61:
	pop bc	; 1F61  C1
Z_1F62:
	dec b	; 1F62  10 F1
	jp nz,L_1F55
L_1F64:
Z_1F64:
	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 24 б (SCR_PATCH)
Z_1F7C:
	ld (il_tmp),hl	; 1F7C  DD 21 29 3B  ; в каноне +0x100 этот операнд стухший
	ld hl,WORK_RAM+0x81
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_1F80:
	jp L_228E	; 1F80  C3 8E 22
D_1F83:
Z_1F83:
	db	0xC9	; 1F83
KBD_CHK_F3B5:
Z_1F84:
	ld a,0xF3	; 1F84  3E F3
Z_1F86:
	out (0xAA),a	; 1F86  D3 AA
Z_1F88:
	in a,(0xA9)	; 1F88  DB A9
Z_1F8A:
	ld (il_a),a	; 1F8A  CB 6F
	and 0x20
	ld a,(il_a)
Z_1F8C:
	ret nz	; 1F8C  C0
Z_1F8D:
	jp L_155D	; 1F8D  C3 5D 15
D_1F90:
Z_1F90:
	db	0x70,0x45	; 1F90
L_1F92:
Z_1F92:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
L_1F9F:
Z_1F9F:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
L_1FA9:
Z_1FA9:
	call SCR_ADDR_BIT14	; 1FA9  CD 70 1B
Z_1FC7:
	db	0,0,0,0,0,0,0,0,0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 11 б (SCR_PATCH)
SFX_64D7:
Z_1FDA:
	push hl	; 1FDA  E5
Z_1FDB:
	push bc	; 1FDB  C5
Z_1FDC:
	ld hl,P1_SFX_64D7	; 1FDC  21 D7 4E
Z_1FDF:
	call L_03F5	; 1FDF  CD F5 03
Z_1FE2:
	pop bc	; 1FE2  C1
Z_1FE3:
	pop hl	; 1FE3  E1
Z_1FE4:
	ret	; 1FE4  C9
SFX_64E6:
Z_1FE5:
	ld hl,P1_SFX_64E6	; 1FE5  21 E6 4E
Z_1FE8:
	jp L_03F5	; 1FE8  C3 F5 03
D_1FEB:
Z_1FEB:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 1FEB
SFX_64D7_x25:
Z_1FF2:
	ld b,0x19	; 1FF2  06 19
L_1FF4:
Z_1FF4:
	push bc	; 1FF4  C5
Z_1FF5:
	ld hl,P1_SFX_64D7	; 1FF5  21 D7 4E
Z_1FF8:
	call L_03F5	; 1FF8  CD F5 03
Z_1FFB:
	ld hl,0x1388	; 1FFB  21 88 13
L_1FFE:
Z_1FFE:
	dec hl	; 1FFE  2B
Z_1FFF:
	ld a,h	; 1FFF  7C
Z_2000:
	or l	; 2000  B5
Z_2001:
	jp nz,L_1FFE	; 2001  20 FB
Z_2003:
	pop bc	; 2003  C1
Z_2004:
	dec b	; 2004  10 EE
	jp nz,L_1FF4
Z_2006:
	jp SFX_64F5	; 2006  C3 9A 20
D_2009:
Z_2009:
	db	0x00,0x00,0x08,0x00	; 2009
L_200D:
Z_200D:
	db	0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 1 б (SCR_PATCH)
D_2048:
Z_2048:
	db	0xDA	; 2048
Z_204D:
	db	0,0,0,0,0,0,0,0,0,0,0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 13 б (SCR_PATCH)
D_2065:
Z_2065:
	db	0x42,0x00,0x86,0x00,0x82,0x00,0x06,0x00,0x46	; 2065
Z_2070:
	db	0,0,0,0,0,0,0,0,0,0,0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 13 б (SCR_PATCH)
L_207E:
Z_207E:
	ld a,(GAME_VARS+0x7)	; 207E  3A F1 0A
Z_2081:
	cp 0x01	; 2081  FE 01
Z_2083:
	jp z,SFX_64AA	; 2083  28 09
Z_2085:
	cp 0x04	; 2085  FE 04
Z_2087:
	ret nz	; 2087  C0
SFX_64B9:
Z_2088:
	ld hl,P1_SFX_64B9	; 2088  21 B9 4E
Z_208B:
	jp L_03F5	; 208B  C3 F5 03
SFX_64AA:
Z_208E:
	ld hl,P1_SFX_64AA	; 208E  21 AA 4E
Z_2091:
	jp L_03F5	; 2091  C3 F5 03
SFX_64C8:
Z_2094:
	ld hl,P1_SFX_64C8	; 2094  21 C8 4E
Z_2097:
	jp L_03F5	; 2097  C3 F5 03
SFX_64F5:
Z_209A:
	ld hl,P1_SFX_64F5	; 209A  21 F5 4E
Z_209D:
	jp L_03F5	; 209D  C3 F5 03
D_20A0:
Z_20A0:
	db	0xFB,0x00,0x00,0x00,0x08,0x00,0x00,0x07	; 20A0
L_20A8:
Z_20A8:
	push hl	; 20A8  E5
Z_20A9:
	call il_ix_ldb	; 20A9  DD 46 02
	db 0x02
Z_20AC:
	ld a,b	; 20AC  78
Z_20AD:
	ld (il_a),a	; 20AD  CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_20AF:
	ld (il_a),a	; 20AF  CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_20B1:
	ld (il_a),a	; 20B1  CB 38
	ld a,b
	or a
	rra
	ld b,a
	ld a,(il_a)
Z_20B3:
	and 0x07	; 20B3  E6 07
Z_20B5:
	jp z,L_20B8	; 20B5  28 01
Z_20B7:
	inc b	; 20B7  04
L_20B8:
Z_20B8:
	ld hl,0x8278	; 20B8  21 78 82
Z_20BB:
	ld de,0x30	; 20BB  11 30 00
L_20BE:
Z_20BE:
	and a	; 20BE  A7
Z_20BF:
	ld a,l	; 20BF  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
Z_20C1:
	dec b	; 20C1  10 FB
	jp nz,L_20BE
Z_20C3:
	ex de,hl	; 20C3  EB
Z_20C4:
	pop hl	; 20C4  E1
Z_20C5:
	ld (il_tmp),hl	; 20C5  DD E5
	ld hl,(z80_ix)
	push hl
	ld hl,(il_tmp)
Z_20C7:
	ld a,(D_20A0+0x5)	; 20C7  3A A5 20
Z_20CA:
	add a,e	; 20CA  83
Z_20CB:
	ld e,a	; 20CB  5F
Z_20CC:
	call il_ix_lda	; 20CC  DD 7E 02
	db 0x02
Z_20CF:
	push de	; 20CF  D5
Z_20D0:
	ld (il_tmp),hl	; 20D0  DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_20D2:
	ld b,a	; 20D2  47
L_20D3:
Z_20D3:
	ld e,(hl)	; 20D3  5E
Z_20D4:
	inc hl	; 20D4  23
Z_20D5:
	ld d,(hl)	; 20D5  56
Z_20D6:
	inc hl	; 20D6  23
Z_20D7:
	ld c,(hl)	; 20D7  4E
Z_20D8:
	inc hl	; 20D8  23
Z_20D9:
	push bc	; 20D9  C5
Z_20DA:
	ld b,0x00	; 20DA  06 00
Z_20DC:
	ld a,(D_20A0+0x7)	; 20DC  3A A7 20
L_20DF:
Z_20DF:
	cp 0x00	; 20DF  FE 00
Z_20E1:
	jp z,L_20EE	; 20E1  28 0B
Z_20E3:
	dec a	; 20E3  3D
Z_20E4:
	ld (il_a),a	; 20E4  CB 3B
	ld a,e
	or a
	rra
	ld e,a
	ld a,(il_a)
Z_20E6:
	ld (il_a),a	; 20E6  CB 1A
	ld a,d
	rra
	ld d,a
	ld a,(il_a)
Z_20E8:
	ld (il_a),a	; 20E8  CB 19
	ld a,c
	rra
	ld c,a
	ld a,(il_a)
Z_20EA:
	ld (il_a),a	; 20EA  CB 18
	ld a,b
	rra
	ld b,a
	ld a,(il_a)
Z_20EC:
	jp L_20DF	; 20EC  18 F1
L_20EE:
Z_20EE:
	ld a,e	; 20EE  7B
Z_20EF:
	call il_ix_or	; 20EF  DD B6 00
	db 0x00
Z_20F2:
	call il_ix_sta	; 20F2  DD 77 00
	db 0x00
Z_20F5:
	ld a,d	; 20F5  7A
Z_20F6:
	call il_ix_or	; 20F6  DD B6 08
	db 0x08
Z_20F9:
	call il_ix_sta	; 20F9  DD 77 08
	db 0x08
Z_20FC:
	ld a,c	; 20FC  79
Z_20FD:
	call il_ix_or	; 20FD  DD B6 10
	db 0x10
Z_2100:
	call il_ix_sta	; 2100  DD 77 10
	db 0x10
Z_2103:
	ld a,b	; 2103  78
Z_2104:
	call il_ix_or	; 2104  DD B6 18
	db 0x18
Z_2107:
	call il_ix_sta	; 2107  DD 77 18
	db 0x18
Z_210A:
	pop bc	; 210A  C1
Z_210B:
	ld a,(z80_ix)	; 210B  DD 7D
Z_210D:
	and 0x07	; 210D  E6 07
Z_210F:
	cp 0x07	; 210F  FE 07
Z_2111:
	jp nz,L_2118	; 2111  20 05
Z_2113:
	ld de,0x28	; 2113  11 28 00
Z_2116:
	ld (il_tmp),hl	; 2116  DD 19
	ld hl,(z80_ix)
	add hl,de
	ld (z80_ix),hl
	ld hl,(il_tmp)
L_2118:
Z_2118:
	ld (il_tmp),hl	; 2118  DD 23
	ld hl,(z80_ix)
	inc hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_211A:
	dec b	; 211A  10 B7
	jp nz,L_20D3
Z_211C:
	ld (il_tmp),hl	; 211C  DD E1
	pop hl
	ld (z80_ix),hl
	ld hl,(il_tmp)
Z_211E:
	ld hl,0x82D7	; 211E  21 D7 82
Z_2121:
	ld c,0x04	; 2121  0E 04
Z_2123:
	ld a,0x03	; 2123  3E 03
Z_2125:
	ld (L_213C+0x1),a	; 2125  32 3D 21
Z_2128:
	ld (L_2144+0x1),a	; 2128  32 45 21
Z_212B:
	call il_ix_lda	; 212B  DD 7E 04
	db 0x04
Z_212E:
	cp 0xA8	; 212E  FE A8
Z_2130:
	jp nc,L_213C	; 2130  30 0A
Z_2132:
	ld a,0x04	; 2132  3E 04
Z_2134:
	ld (L_213C+0x1),a	; 2134  32 3D 21
Z_2137:
	ld a,0x02	; 2137  3E 02
Z_2139:
	ld (L_2144+0x1),a	; 2139  32 45 21
L_213C:
Z_213C:
	ld b,0x04	; 213C  06 04
Z_213E:
	ld a,0xF1	; 213E  3E F1
L_2140:
Z_2140:
	ld (hl),a	; 2140  77
Z_2141:
	inc hl	; 2141  23
Z_2142:
	dec b	; 2142  10 FC
	jp nz,L_2140
L_2144:
Z_2144:
	ld de,0x02	; 2144  11 02 00
Z_2147:
	add hl,de	; 2147  19
Z_2148:
	dec c	; 2148  0D
Z_2149:
	jp nz,L_213C	; 2149  20 F1
Z_214B:
	ret	; 214B  C9
D_214C:
Z_214C:
	db	0xCC,0xD2,0xDD,0x7E,0xFE,0xDD,0x77,0x07,0xDD,0x7E,0xFD,0xDD,0x77,0x06,0xCD,0xA8	; 214C
Z_215C:
	db	0xD7,0x01,0x09,0x00,0xDD,0x09,0xC9,0x00,0x00,0x18,0x00,0x20	; 215C
L_2168:
Z_2168:
	db	0,0,0	; ЗОНА ВРЕЗКИ АДАПТЕРА, 3 б (SCR_PATCH)
D_21BC:
Z_21BC:
	db	0x91,0xD6,0xBC,0xF5,0x11,0x08,0x01,0xA7,0xED,0x52,0xF1,0x28,0x2B,0x30,0x17,0x7C	; 21BC
Z_21CC:
	db	0xC6,0x06,0x67	; 21CC
D_228A:
Z_228A:
	db	0x00,0x00,0x00,0x00	; 228A
L_228E:
Z_228E:
	ld hl,(D_1F90)	; 228E  2A 90 1F
Z_2291:
	ld de,0x08	; 2291  11 08 00
Z_2294:
	and a	; 2294  A7
Z_2295:
	ld a,l	; 2295  ED 52
	sbc a,e
	ld l,a
	ld a,h
	sbc a,d
	ld h,a
	jp nz,il_AS5
	jp c,il_ASC6
	ld a,l
	or a
	jp il_AS5
il_ASC6:
	ld a,l
	or a
	scf
il_AS5:
Z_2297:
	push hl	; 2297  E5
Z_2298:
	call L_200D	; 2298  CD 0D 20
Z_229B:
	pop hl	; 229B  E1
Z_229C:
	ld a,(D_1A23)	; 229C  3A 23 1A
Z_229F:
	and a	; 229F  A7
Z_22A0:
	ret z	; 22A0  C8
Z_22A1:
	ld a,h	; 22A1  7C
Z_22A2:
	add a,0x0C	; 22A2  C6 0C
Z_22A4:
	ld h,a	; 22A4  67
Z_22A5:
	jp L_200D	; 22A5  C3 0D 20
D_22A8:
Z_22A8:
	db	0x00,0x00	; 22A8
D_22C9:
Z_22C9:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF	; 22C9
D_2343:
Z_2343:
	db	0x00,0x08,0x00,0x31,0x00,0x11,0x00,0x30,0x00,0x49,0x00,0x38,0x00,0xFF,0xC7,0xFF	; 2343
Z_2353:
	db	0xEF,0xFF,0xC7	; 2353
D_23CA:
Z_23CA:
	db	0x00,0xCD,0x68,0xD8,0xCD	; 23CA
L_23CF:
Z_23CF:
	ld a,0xC9	; 23CF  3E C9
Z_23D1:
	ld (L_20A8),a	; 23D1  32 A8 20
Z_23D4:
	push hl	; 23D4  ED 4B F4 0A
	ld hl,(GAME_VARS+0xA)
	ld b,h
	ld c,l
	pop hl
Z_23D8:
	ld a,0x00	; 23D8  3E 00
Z_23DA:
	call L_2168	; 23DA  CD 68 21
Z_23DD:
	call L_228E	; 23DD  CD 8E 22
Z_23E0:
	ld a,0xE5	; 23E0  3E E5
Z_23E2:
	ld (L_20A8),a	; 23E2  32 A8 20
Z_23E5:
	ret	; 23E5  C9
Z_23E6:
	jp L_228E	; 23E6  C3 8E 22  ; в каноне +0x100 этот операнд стухший
L_23E9:
Z_23E9:
	call L_16CD	; 23E9  CD CD 16
Z_23EC:
	ld hl,LOW_TILE_SRC	; 23EC  21 F4 01
Z_23EF:
	ld (L_1736+0x1),hl	; 23EF  22 37 17
Z_23F2:
	ld hl,D_240E	; 23F2  21 0E 24
Z_23F5:
	ld b,0x11	; 23F5  06 11
Z_23F7:
	ld de,0x1518	; 23F7  11 18 15
Z_23FA:
	call L_16F9	; 23FA  CD F9 16
Z_23FD:
	ld hl,HUD_TILES+0x8C	; 23FD  21 E2 9B
Z_2400:
	ld (L_1736+0x1),hl	; 2400  22 37 17
Z_2403:
	ld b,0x04	; 2403  06 04
Z_2405:
	ld de,0x171A	; 2405  11 1A 17
Z_2408:
	ld hl,D_240E+0x11	; 2408  21 1F 24
Z_240B:
	jp L_16F9	; 240B  C3 F9 16
D_240E:
Z_240E:
	db	0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x18,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F	; 240E
Z_241E:
	db	0x30,0x3B,0x43,0x42,0x41,0x00	; 241E
L_2424:
Z_2424:
	call SFX_64E6	; 2424  CD E5 1F
Z_2427:
	ld bc,0x2710	; 2427  01 10 27
L_242A:
Z_242A:
	dec bc	; 242A  0B
Z_242B:
	ld a,b	; 242B  78
Z_242C:
	or c	; 242C  B1
Z_242D:
	jp nz,L_242A	; 242D  20 FB
Z_242F:
	ret	; 242F  C9
D_2430:
Z_2430:
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2430
MUS_START:
Z_243A:
	ld hl,(D_256F+0x14)	; 243A  2A 83 25
Z_243D:
	ld (D_256F+0xA),hl	; 243D  22 79 25
Z_2440:
	ld hl,(D_256F+0x16)	; 2440  2A 85 25
Z_2443:
	ld (D_256F+0xC),hl	; 2443  22 7B 25
Z_2446:
	ld hl,(D_256F+0x18)	; 2446  2A 87 25
Z_2449:
	ld (D_256F+0xE),hl	; 2449  22 7D 25
Z_244C:
	ld hl,D_256F	; 244C  21 6F 25
Z_244F:
	ld b,(hl)	; 244F  46
Z_2450:
	inc hl	; 2450  23
L_2451:
Z_2451:
	push bc	; 2451  C5
Z_2452:
	ld a,(hl)	; 2452  7E
Z_2453:
	inc hl	; 2453  23
Z_2454:
	ld c,(hl)	; 2454  4E
Z_2455:
	inc hl	; 2455  23
Z_2456:
	call PSG_WR	; 2456  CD 69 25
Z_2459:
	pop bc	; 2459  C1
Z_245A:
	dec b	; 245A  10 F5
	jp nz,L_2451
L_245C:
Z_245C:
	push hl	; 245C  ED 4B 81 25
	ld hl,(D_256F+0x12)
	ld b,h
	ld c,l
	pop hl
Z_2478:
	ld hl,(D_256F+0xA)	; 2478  2A 79 25
Z_247B:
	ld a,(D_256F+0x9)	; 247B  3A 78 25
Z_247E:
	or 0x01	; 247E  F6 01
Z_2480:
	ld (D_256F+0x9),a	; 2480  32 78 25
Z_2483:
	ld c,a	; 2483  4F
Z_2484:
	ld a,0x07	; 2484  3E 07
Z_2486:
	call PSG_WR	; 2486  CD 69 25
Z_2489:
	ld a,(hl)	; 2489  7E
Z_248A:
	cp 0xFE	; 248A  FE FE
Z_248C:
	jp nz,L_2495	; 248C  20 07
Z_248E:
	ld hl,(D_256F+0x14)	; 248E  2A 83 25
Z_2491:
	ld (D_256F+0xA),hl	; 2491  22 79 25
Z_2494:
	ld a,(hl)	; 2494  7E
L_2495:
Z_2495:
	cp 0xFF	; 2495  FE FF
Z_2497:
	jp z,L_24BF	; 2497  28 26
Z_2499:
	add a,a	; 2499  CB 27
Z_249B:
	ld d,0x00	; 249B  16 00
Z_249D:
	ld e,a	; 249D  5F
Z_249E:
	push hl	; 249E  E5
Z_249F:
	ld hl,(D_256F+0x10)	; 249F  2A 7F 25
Z_24A2:
	add hl,de	; 24A2  19
Z_24A3:
	ld a,0x00	; 24A3  3E 00
Z_24A5:
	ld c,(hl)	; 24A5  4E
Z_24A6:
	call PSG_WR	; 24A6  CD 69 25
Z_24A9:
	ld a,0x01	; 24A9  3E 01
Z_24AB:
	inc hl	; 24AB  23
Z_24AC:
	ld c,(hl)	; 24AC  4E
Z_24AD:
	call PSG_WR	; 24AD  CD 69 25
Z_24B0:
	ld a,(D_256F+0x9)	; 24B0  3A 78 25
Z_24B3:
	and 0xFE	; 24B3  E6 FE
Z_24B5:
	ld (D_256F+0x9),a	; 24B5  32 78 25
Z_24B8:
	ld c,a	; 24B8  4F
Z_24B9:
	ld a,0x07	; 24B9  3E 07
Z_24BB:
	call PSG_WR	; 24BB  CD 69 25
Z_24BE:
	pop hl	; 24BE  E1
L_24BF:
Z_24BF:
	inc hl	; 24BF  23
Z_24C0:
	ld (D_256F+0xA),hl	; 24C0  22 79 25
Z_24C3:
	ld hl,(D_256F+0xC)	; 24C3  2A 7B 25
Z_24C6:
	ld a,(D_256F+0x9)	; 24C6  3A 78 25
Z_24C9:
	or 0x02	; 24C9  F6 02
Z_24CB:
	ld (D_256F+0x9),a	; 24CB  32 78 25
Z_24CE:
	ld c,a	; 24CE  4F
Z_24CF:
	ld a,0x07	; 24CF  3E 07
Z_24D1:
	call PSG_WR	; 24D1  CD 69 25
Z_24D4:
	ld a,(hl)	; 24D4  7E
Z_24D5:
	cp 0xFE	; 24D5  FE FE
Z_24D7:
	jp nz,L_24E0	; 24D7  20 07
Z_24D9:
	ld hl,(D_256F+0x16)	; 24D9  2A 85 25
Z_24DC:
	ld (D_256F+0xC),hl	; 24DC  22 7B 25
Z_24DF:
	ld a,(hl)	; 24DF  7E
L_24E0:
Z_24E0:
	cp 0xFF	; 24E0  FE FF
Z_24E2:
	jp z,L_250A	; 24E2  28 26
Z_24E4:
	add a,a	; 24E4  CB 27
Z_24E6:
	ld d,0x00	; 24E6  16 00
Z_24E8:
	ld e,a	; 24E8  5F
Z_24E9:
	push hl	; 24E9  E5
Z_24EA:
	ld hl,(D_256F+0x10)	; 24EA  2A 7F 25
Z_24ED:
	add hl,de	; 24ED  19
Z_24EE:
	ld a,0x02	; 24EE  3E 02
Z_24F0:
	ld c,(hl)	; 24F0  4E
Z_24F1:
	call PSG_WR	; 24F1  CD 69 25
Z_24F4:
	ld a,0x03	; 24F4  3E 03
Z_24F6:
	inc hl	; 24F6  23
Z_24F7:
	ld c,(hl)	; 24F7  4E
Z_24F8:
	call PSG_WR	; 24F8  CD 69 25
Z_24FB:
	ld a,(D_256F+0x9)	; 24FB  3A 78 25
Z_24FE:
	and 0xFD	; 24FE  E6 FD
Z_2500:
	ld (D_256F+0x9),a	; 2500  32 78 25
Z_2503:
	ld c,a	; 2503  4F
Z_2504:
	ld a,0x07	; 2504  3E 07
Z_2506:
	call PSG_WR	; 2506  CD 69 25
Z_2509:
	pop hl	; 2509  E1
L_250A:
Z_250A:
	inc hl	; 250A  23
Z_250B:
	ld (D_256F+0xC),hl	; 250B  22 7B 25
Z_250E:
	ld hl,(D_256F+0xE)	; 250E  2A 7D 25
Z_2511:
	ld a,(D_256F+0x9)	; 2511  3A 78 25
Z_2514:
	or 0x04	; 2514  F6 04
Z_2516:
	ld (D_256F+0x9),a	; 2516  32 78 25
Z_2519:
	ld c,a	; 2519  4F
Z_251A:
	ld a,0x07	; 251A  3E 07
Z_251C:
	call PSG_WR	; 251C  CD 69 25
Z_251F:
	ld a,(hl)	; 251F  7E
Z_2520:
	cp 0xFE	; 2520  FE FE
Z_2522:
	jp nz,L_252B	; 2522  20 07
Z_2524:
	ld hl,(D_256F+0x18)	; 2524  2A 87 25
Z_2527:
	ld (D_256F+0xE),hl	; 2527  22 7D 25
Z_252A:
	ld a,(hl)	; 252A  7E
L_252B:
Z_252B:
	cp 0xFF	; 252B  FE FF
Z_252D:
	jp z,L_2555	; 252D  28 26
Z_252F:
	add a,a	; 252F  CB 27
Z_2531:
	ld d,0x00	; 2531  16 00
Z_2533:
	ld e,a	; 2533  5F
Z_2534:
	push hl	; 2534  E5
Z_2535:
	ld hl,(D_256F+0x10)	; 2535  2A 7F 25
Z_2538:
	add hl,de	; 2538  19
Z_2539:
	ld a,0x04	; 2539  3E 04
Z_253B:
	ld c,(hl)	; 253B  4E
Z_253C:
	call PSG_WR	; 253C  CD 69 25
Z_253F:
	ld a,0x05	; 253F  3E 05
Z_2541:
	inc hl	; 2541  23
Z_2542:
	ld c,(hl)	; 2542  4E
Z_2543:
	call PSG_WR	; 2543  CD 69 25
Z_2546:
	ld a,(D_256F+0x9)	; 2546  3A 78 25
Z_2549:
	and 0xFB	; 2549  E6 FB
Z_254B:
	ld (D_256F+0x9),a	; 254B  32 78 25
Z_254E:
	ld c,a	; 254E  4F
Z_254F:
	ld a,0x07	; 254F  3E 07
Z_2551:
	call PSG_WR	; 2551  CD 69 25
Z_2554:
	pop hl	; 2554  E1
L_2555:
Z_2555:
	inc hl	; 2555  23
Z_2556:
	ld (D_256F+0xE),hl	; 2556  22 7D 25
Z_2559:
	jp L_245C	; 2559  C3 5C 24
L_255C:
Z_255C:
	pop bc	; 255C  C1
Z_255D:
	ld a,0x3F	; 255D  3E 3F
Z_255F:
	ld (D_256F+0x9),a	; 255F  32 78 25
Z_2562:
	ld c,a	; 2562  4F
Z_2563:
	ld a,0x07	; 2563  3E 07
Z_2565:
	call PSG_WR	; 2565  CD 69 25
Z_2568:
	ret	; 2568  C9
PSG_WR:
Z_2569:
	out (0xA0),a	; 2569  D3 A0
Z_256B:
	ld a,c	; 256B  79
Z_256C:
	out (0xA1),a	; 256C  D3 A1
Z_256E:
	ret	; 256E  C9
D_256F:
Z_256F:
	db	0x04,0x07,0x3F,0x08,0x00,0x09,0x00,0x0A,0x00,0x3F,0x00,0x00,0x00,0x00,0x00,0x00	; 256F
Z_257F:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 257F
Z_2587:
	dw	D_256F+0x376	; 2587  E5 28
Z_2589:
	db	0x5C,0x0D,0x9C,0x0C,0xE7,0x0B,0x3C,0x0B,0x9A,0x0A,0x02,0x0A,0x72,0x09,0xEA,0x08	; 2589
Z_2599:
	db	0x6A,0x08,0xF1,0x07,0x7F,0x07,0x13,0x07,0xAE,0x06,0x4E,0x06,0xF3,0x05,0x9E,0x05	; 2599
Z_25A9:
	db	0x4D,0x05,0x01,0x05,0xB9,0x04,0x75,0x04,0x35,0x04,0xF8,0x03,0xBF,0x03,0x89,0x03	; 25A9
Z_25B9:
	db	0x57,0x03,0x27,0x03,0xF9,0x02,0xCF,0x02,0xA6,0x02,0x80,0x02,0x5C,0x02,0x3A,0x02	; 25B9
Z_25C9:
	db	0x1A,0x02,0xFC,0x01,0xDF,0x01,0xC4,0x01,0xAB,0x01,0x93,0x01,0x7C,0x01,0x67,0x01	; 25C9
Z_25D9:
	db	0x53,0x01,0x40,0x01,0x2E,0x01,0x1D,0x01,0x0D,0x01,0xFE,0x00,0xEF,0x00,0xE2,0x00	; 25D9
Z_25E9:
	db	0xD5,0x00,0xC9,0x00,0xBE,0x00,0xB3,0x00,0xA9,0x00,0xA0,0x00,0x97,0x00,0x8E,0x00	; 25E9
Z_25F9:
	db	0x86,0x00,0x7F,0x00,0x77,0x00,0x71,0x00,0x6A,0x00,0x64,0x00,0x5F,0x00,0x59,0x00	; 25F9
Z_2609:
	db	0x54,0x00,0x50,0x00,0x4B,0x00,0x47,0x00,0x43,0x00,0x3F,0x00,0x3B,0x00,0x38,0x00	; 2609
Z_2619:
	db	0x35,0x00,0x32,0x00,0x2F,0x00,0x2C,0x00,0x2A,0x00,0x28,0x00,0x25,0x00,0x23,0x00	; 2619
Z_2629:
	db	0x21,0x00,0x1F,0x00,0x1D,0x00,0x1C,0x00,0x1A,0x00,0x19,0x00,0x17,0x00,0x16,0x00	; 2629
Z_2639:
	db	0x15,0x00,0x14,0x00,0x12,0x00,0x11,0x00,0x10,0x00,0x0F,0x00,0x0E,0x00,0x0E,0x00	; 2639
Z_2649:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 2649
Z_2659:
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01	; 2659
Z_2669:
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 2669
Z_2679:
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 2679
Z_2689:
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 2689
Z_2699:
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 2699
Z_26A9:
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 26A9
Z_26B9:
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 26B9
Z_26C9:
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 26C9
Z_26D9:
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 26D9
Z_26E9:
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 26E9
Z_26F9:
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A	; 26F9
Z_2709:
	db	0x01,0x05,0x03,0x08,0x06,0x05,0x03,0x01,0x0A,0x11,0x0F,0x0D,0x0C,0x08,0x05,0x08	; 2709
Z_2719:
	db	0x06,0x0D,0x0C,0x0A,0x08,0x01,0x03,0x05,0x06,0x03,0x06,0x0A,0x0C,0x08,0x0C,0x08	; 2719
Z_2729:
	db	0x03,0x0A,0x08,0x06,0x08,0x06,0x08,0x0A,0xFE,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2729
Z_2739:
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2739
Z_2749:
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2749
Z_2759:
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2759
Z_2769:
	db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF	; 2769
Z_2779:
	db	0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03,0xFF,0x03	; 2779
Z_2789:
	db	0xFF,0x01,0xFF,0x01,0xFF,0x01,0xFF,0x01,0xFF,0x0A,0xFF,0x0A,0xFF,0x0C,0xFF,0x0C	; 2789
Z_2799:
	db	0xFF,0x06,0xFF,0x06,0xFF,0x01,0xFF,0x01,0xFF,0x06,0xFF,0x06,0xFF,0x03,0xFF,0x08	; 2799
Z_27A9:
	db	0xFF,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03	; 27A9
Z_27B9:
	db	0x03,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x0A,0x0A,0x0A,0x0A,0x0C,0x0C,0x0C	; 27B9
Z_27C9:
	db	0x0C,0x06,0x06,0x06,0x06,0x01,0x01,0x01,0x01,0x06,0x06,0x06,0x06,0x03,0x03,0x08	; 27C9
Z_27D9:
	db	0x08,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F	; 27D9
Z_27E9:
	db	0x03,0x0D,0x01,0x0D,0x01,0x0D,0x01,0x0D,0x01,0x16,0x0A,0x16,0x0A,0x18,0x0C,0x18	; 27E9
Z_27F9:
	db	0x0C,0x12,0x06,0x12,0x06,0x0D,0x01,0x0D,0x01,0x12,0x06,0x12,0x06,0x0F,0x03,0x14	; 27F9
Z_2809:
	db	0x08,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0x03,0xFE,0x01,0x01,0x01,0x0C,0x08,0x08	; 2809
Z_2819:
	db	0x06,0x05,0x01,0x01,0x01,0x0C,0x08,0x08,0x06,0x05,0x05,0x05,0x05,0x10,0x0C,0x0C	; 2819
Z_2829:
	db	0x0A,0x08,0x05,0x05,0x05,0x10,0x0C,0x0C,0x0A,0x08,0x0A,0x0A,0x0A,0x15,0x11,0x11	; 2829
Z_2839:
	db	0x0F,0x0D,0x0A,0x0A,0x0A,0x15,0x11,0x11,0x0F,0x0D,0x06,0x06,0x06,0x11,0x0D,0x0D	; 2839
Z_2849:
	db	0x0C,0x0A,0x06,0x06,0x06,0x11,0x0D,0x0D,0x0C,0x0A,0x03,0x03,0x03,0x0E,0x0A,0x0A	; 2849
Z_2859:
	db	0x08,0x06,0x03,0x03,0x03,0x0E,0x0A,0x0A,0x08,0x06,0x08,0x08,0x08,0x13,0x0F,0x0D	; 2859
Z_2869:
	db	0x0F,0x0D,0x08,0x08,0x08,0x13,0x0F,0x0F,0x0D,0x0C,0x08,0x08,0x08,0x13,0x08,0x08	; 2869
Z_2879:
	db	0x08,0x13,0xFE,0x11,0x0D,0x11,0x0D,0x11,0x0D,0x11,0x08,0x11,0x0D,0x11,0x0D,0x0F	; 2879
Z_2889:
	db	0x0D,0x0F,0x08,0x11,0x05,0x11,0x05,0x11,0x05,0x11,0x0C,0x11,0x05,0x11,0x05,0x14	; 2889
Z_2899:
	db	0x05,0x14,0x0C,0x0D,0x0A,0x0D,0x0A,0x0D,0x0A,0x0D,0x05,0x0D,0x0A,0x0D,0x0A,0x0F	; 2899
Z_28A9:
	db	0x0A,0x11,0x05,0x12,0x06,0x12,0x06,0x12,0x06,0x12,0x0D,0x12,0x06,0x12,0x06,0x11	; 28A9
Z_28B9:
	db	0x06,0x11,0x0D,0x0F,0x03,0x0F,0x03,0x0F,0x03,0x0F,0x0A,0x0F,0x03,0x0F,0x03,0x16	; 28B9
Z_28C9:
	db	0x03,0x18,0x0A,0x19,0x08,0x19,0x08,0x19,0x08,0x19,0x0D,0x19,0x08,0x19,0x08,0x19	; 28C9
Z_28D9:
	db	0x08,0x19,0x0D,0x18,0x08,0x18,0x08,0x18,0x08,0x18,0x08,0xFE,0xFF,0xFE	; 28D9
MUS_TRACK_1:
Z_28E7:
	ld hl,D_256F+0xE2	; 28E7  21 51 26
Z_28EA:
	ld (D_256F+0x14),hl	; 28EA  22 83 25
Z_28ED:
	ld hl,D_256F+0x1C3	; 28ED  21 32 27
Z_28F0:
	ld (D_256F+0x16),hl	; 28F0  22 85 25
Z_28F3:
	ld hl,0x0480	; 28F3  21 80 04
Z_28F6:
	ld (D_256F+0x12),hl	; 28F6  22 81 25
Z_28F9:
	ld hl,D_256F+0x56	; 28F9  21 C5 25
Z_28FC:
	ld (D_256F+0x10),hl	; 28FC  22 7F 25
Z_28FF:
	ld a,0x0F	; 28FF  3E 0F
Z_2901:
	ld (D_256F+0x4),a	; 2901  32 73 25
Z_2904:
	ld a,0x0E	; 2904  3E 0E
Z_2906:
	ld (D_256F+0x6),a	; 2906  32 75 25
Z_2909:
	jp MUS_START	; 2909  C3 3A 24
D_290C:
Z_290C:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 290C
MUS_TRACK_2:
Z_2919:
	ld hl,D_256F+0x2A4	; 2919  21 13 28
Z_291C:
	ld (D_256F+0x14),hl	; 291C  22 83 25
Z_291F:
	ld hl,D_256F+0x30D	; 291F  21 7C 28
Z_2922:
	ld (D_256F+0x16),hl	; 2922  22 85 25
Z_2925:
	ld hl,0x04FF	; 2925  21 FF 04
Z_2928:
	ld (D_256F+0x12),hl	; 2928  22 81 25
Z_292B:
	ld hl,D_256F+0x60	; 292B  21 CF 25
Z_292E:
	ld (D_256F+0x10),hl	; 292E  22 7F 25
Z_2931:
	ld a,0x0C	; 2931  3E 0C
Z_2933:
	ld (D_256F+0x4),a	; 2933  32 73 25
Z_2936:
	ld a,0x0F	; 2936  3E 0F
Z_2938:
	ld (D_256F+0x6),a	; 2938  32 75 25
Z_293B:
	jp MUS_START	; 293B  C3 3A 24
D_293E:
Z_293E:
	db	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	; 293E
Z_1412:
	ld (il_tmp2),hl	; вход посреди команды Z80 1412
	ld hl,(z80_iy)
	ld a,(hl)
	ld hl,(il_tmp2)
	jp Z_1415
	org	0x1DFD
D_1DFD:
Z_1DFD:
	db	0xFF,0xF7,0xFF,0x00,0x80,0x40,0xC0,0x20,0xA0,0x60,0xE0,0x10,0x90,0x50,0xD0,0x30	; 1DFD
	org	0x1E0D
Z_1E0D:
	db	0xB0,0x70,0xF0,0x08,0x88,0x48,0xC8,0x28,0xA8,0x68,0xE8,0x18,0x98,0x58,0xD8,0x38	; 1E0D
	org	0x1E1D
Z_1E1D:
	db	0xB8,0x78,0xF8,0x04,0x84,0x44,0xC4,0x24,0xA4,0x64,0xE4,0x14,0x94,0x54,0xD4,0x34	; 1E1D
	org	0x1E2D
Z_1E2D:
	db	0xB4,0x74,0xF4,0x0C,0x8C,0x4C,0xCC,0x2C,0xAC,0x6C,0xEC,0x1C,0x9C,0x5C,0xDC,0x3C	; 1E2D
	org	0x1E3D
Z_1E3D:
	db	0xBC,0x7C,0xFC,0x02,0x82,0x42,0xC2,0x22,0xA2,0x62,0xE2,0x12,0x92,0x52,0xD2,0x32	; 1E3D
	org	0x1E4D
Z_1E4D:
	db	0xB2,0x72,0xF2,0x0A,0x8A,0x4A,0xCA,0x2A,0xAA,0x6A,0xEA,0x1A,0x9A,0x5A,0xDA,0x3A	; 1E4D
	org	0x1E5D
Z_1E5D:
	db	0xBA,0x7A,0xFA,0x06,0x86,0x46,0xC6,0x26,0xA6,0x66,0xE6,0x16,0x96,0x56,0xD6,0x36	; 1E5D
	org	0x1E6D
Z_1E6D:
	db	0xB6,0x76,0xF6,0x0E,0x8E,0x4E,0xCE,0x2E,0xAE,0x6E,0xEE,0x1E,0x9E,0x5E,0xDE,0x3E	; 1E6D
	org	0x1E7D
Z_1E7D:
	db	0xBE,0x7E,0xFE,0x01,0x81,0x41,0xC1,0x21,0xA1,0x61,0xE1,0x11,0x91,0x51,0xD1,0x31	; 1E7D
	org	0x1E8D
Z_1E8D:
	db	0xB1,0x71,0xF1,0x09,0x89,0x49,0xC9,0x29,0xA9,0x69,0xE9,0x19,0x99,0x59,0xD9,0x39	; 1E8D
	org	0x1E9D
Z_1E9D:
	db	0xB9,0x79,0xF9,0x05,0x85,0x45,0xC5,0x25,0xA5,0x65,0xE5,0x15,0x95,0x55,0xD5,0x35	; 1E9D
	org	0x1EAD
Z_1EAD:
	db	0xB5,0x75,0xF5,0x0D,0x8D,0x4D,0xCD,0x2D,0xAD,0x6D,0xED,0x1D,0x9D,0x5D,0xDD,0x3D	; 1EAD
	org	0x1EBD
Z_1EBD:
	db	0xBD,0x7D,0xFD,0x03,0x83,0x43,0xC3,0x23,0xA3,0x63,0xE3,0x13,0x93,0x53,0xD3,0x33	; 1EBD
	org	0x1ECD
Z_1ECD:
	db	0xB3,0x73,0xF3,0x0B,0x8B,0x4B,0xCB,0x2B,0xAB,0x6B,0xEB,0x1B,0x9B,0x5B,0xDB,0x3B	; 1ECD
	org	0x1EDD
Z_1EDD:
	db	0xBB,0x7B,0xFB,0x07,0x87,0x47,0xC7,0x27,0xA7,0x67,0xE7,0x17,0x97,0x57,0xD7,0x37	; 1EDD
	org	0x1EED
Z_1EED:
	db	0xB7,0x77,0xF7,0x0F,0x8F,0x4F,0xCF,0x2F,0xAF,0x6F,0xEF,0x1F,0x9F,0x5F,0xDF,0x3F	; 1EED
	org	0x1EFD
Z_1EFD:
	db	0xBF,0x7F,0xFF	; 1EFD
