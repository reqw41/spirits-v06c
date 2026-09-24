; СГЕНЕРИРОВАНО tools/recompile_i8080.py — правки вносить ТУДА.
; РАНТАЙМ РЕКОМПИЛЯЦИИ Z80 -> i8080: хелперы (ix+d)/(iy+d) с общими
; прологом и эпилогом, ldir/lddr, ex af,af', замена регистру R.
; Контракт хелперов: беречь HL, A и ФЛАГИ; DE/BC не трогать.
; ЭТОТ ФАЙЛ НЕ СОБИРАЕТСЯ отдельно: те же процедуры лежат внутри
; src/i8080/game.asm, разложенные по свободным кускам образа
; (docs/recompilation.md, §5).  Здесь — чтобы их можно было читать.
;
; Карта:
;   il_pro1 / il_pro2     пролог: спасти AF/HL, взять 1 или 2 inline-байта
;   il_pro_ix / il_pro_iy  то же + база IX или IY
;   il_adr                 прибавить смещение СО ЗНАКОМ к HL
;   il_epi / il_epi_a      эпилог: вернуть AF (+ A из il_a) и HL
;   il_ix_* / il_iy_*      формы: ld/or/cp/inc/dec/(hl) для холодных сайтов
;   il_rnd / il_ldir / il_lddr / il_exaf
;
; --- прологи: разобрать стек вызова и достать inline-смещение ---
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
il_adr:                                 ; hl = (ix|iy), a = смещение СО ЗНАКОМ
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
il_ret_hl:                              ; вернуть HL (флаги не трогаются)
                ld      hl,(il_tmp2)
                ret
il_epi:                                 ; вернуть AF и HL вызывателя
                ld      hl,(il_f)
                push    hl
                pop     af
                jp      il_ret_hl
il_epi_a:                               ; флаги и HL вызывателя, a = прочитанное
                ld      hl,(il_f)
                push    hl
                pop     af
                ld      a,(il_a)
                jp      il_ret_hl
; --- формы IX (холодные сайты: call + байт смещения) ---
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
; --- формы IY ---
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
; --- прочие замены команд Z80 ---
il_rnd:                                 ; ЗАМЕНА `ld a,r` (docs/determinism.md)
                ld      a,(z80_r)       ; у i8080 регистра R нет; ряд ведёт
                add     a,0x9D          ; эта ячейка: +0x9D на чтение,
                ld      (z80_r),a       ; +1 на кадр (V_ISR связки)
                ret
il_ldir:                                ; ldir: (hl)->(de), bc байт
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
il_exaf:                                ; ex af,af' через теневую ячейку
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
