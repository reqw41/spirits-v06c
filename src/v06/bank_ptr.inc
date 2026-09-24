; СГЕНЕРИРОВАНО tools/repack_banks.py — правки вносить ТУДА.
; Адрес ЗАГОЛОВКА записи банка: (hl) = высота, (hl+1) = ширина,
; hl+2 = данные ПО СТОЛБЦАМ (столбец = h подряд идущих байт).
; Заменяет линейный проход SPR_BANK_VAR/SPR_BANK_HI игры.
; Сами таблицы кладёт в образ tools/build_v06_rom.py.
BKP_DEC         equ     0x488C
BKP_DEC_N       equ     58
BKP_SPR         equ     0x4900
BKP_SPR_N       equ     53
