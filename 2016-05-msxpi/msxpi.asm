; Fast pi calculation
; by Ricardo Bittencourt 2016

        output  msxpi.com

        org     0100h

; ----------------------------------------------------------------
; Constants

N               equ     3500

; ----------------------------------------------------------------
; MSX bios

restart         equ     00000h  ; Return to DOS
bdos            equ     00005h  ; BDOS entry point
console_output  equ     00002h  ; Print char
string_output   equ     00009h  ; Print string terminated in $
jiffy           equ     0FC9Eh  ; Software clock, increment at 60Hz
chgcpu          equ     00180h  ; Enable R800 CPU
mainrom         equ     0FFF6h  ; Slot of main rom
callf           equ     0001Ch  ; Interslot call 

; ----------------------------------------------------------------
; Initialization.

global_init:
        ld      a, 128 + 1
        ld      iy, (mainrom)
        ld      ix, chgcpu
        call    callf
        ld      hl, (jiffy)
        ld      (save_jiffy), hl
        call    init_vector_r
        call    main
        call    print_eol
        ld      hl, (jiffy)
        ld      de, (save_jiffy)
        or      a
        sbc     hl, de
        call    print_time
        call    print_eol
        jp      restart

init_vector_r:
        ld      hl, 2000
        ld      (vector_r), hl
        ld      hl, vector_r
        ld      de, vector_r + 2
        ld      bc, N * 2
        ldir
        ret

main:
        ld      hl, N
        ld      (var_k), hl
        ld      hl, 0
        ld      (var_c), hl

outer_loop:
        ; i = k
        ld      hl, (var_k)
        ld      (var_i), hl
        ; d = 0
        ld      hl, 0
        ld      (var_d), hl
        ld      (var_d + 2), hl

inner_loop:
        ; d += r[i] * 10000
        ld      ix, (var_i)
        ld      bc, vector_r
        add     ix, ix
        add     ix, bc
        ld      l, (ix + 0)
        ld      h, (ix + 1)
        ld      bc, 10000
        muluw   hl, bc
        ld      bc, (var_d)
        add     hl, bc
        ld      bc, (var_d + 2)
        ex      de, hl
        adc     hl, bc
        ex      de, hl
        ; de:hl has updated value of var_d
        ; b = i * 2 - 1
        exx
        ld      hl, (var_i)
        add     hl, hl
        dec     hl
        ld      (var_b), hl
        ld      bc, hl
        exx
        ; d /= b
        call    div32x16
        ; de:hl has div 
        ; hl' has mod
        ; r[i] = d % b
        exx
        ld      (ix + 0), l
        ld      (ix + 1), h
        exx
        ; i--
        ld      bc, (var_i)
        dec     bc
        ld      a, b
        or      c
        ld      (var_i), bc
        jr      z, exit_inner_loop
        ; d *= i
        push    de
        muluw   hl, bc
        ld      (var_d), hl
        ex      de, hl
        ex      (sp), hl
        muluw   hl, bc
        pop     de
        add     hl, de
        ld      (var_d + 2), hl
        jr      inner_loop
        
exit_inner_loop:
        ; d / 10000
        ; at this point d = de:hl
        exx
        ld      bc, 10000
        exx
        call    div32x16
        ld      de, (var_c)
        add     hl, de
        exx
        ld      (var_c), hl
        exx
        call    print_decimal
        ; k -= 14
        ld      hl, (var_k)
        ld      de, 14
        or      a
        sbc     hl, de
        ld      (var_k), hl
        ret     z
        ret     c
        jp      outer_loop

; ----------------------------------------------------------------
; Unsigned division, 32x16 bits.

        macro   div slices
        exx
        dup     slices
        adc     a, a
        adc     hl, hl
        add     hl, de
        jr      c, 2f
        ; restore sub
        add     hl, bc
        or      a
2:
        ; don't restore sub
        edup
        exx
        endm

div32x16:
        ; enter DE:HL / BC'
        ; exit DE:HL result, HL' remainder
        exx
        ld      hl, 0
        ld      a, c
        cpl
        ld      e, a
        ld      a, b
        cpl
        ld      d, a
        inc     de
        exx
        ; first
        ld      a, d
        or      a
        jr      z, 1f
        add     a, a
        add     a, a
        add     a, a
        div     5
1:
        ld      d, a
        ld      a, e
        div     8
        ld      e, a
        ld      a, h
        div     8
        ld      h, a
        ld      a, l
        div     8
        ld      l, a
        adc     hl, hl
        ex      de, hl
        adc     hl, hl
        ex      de, hl
        ret

; ----------------------------------------------------------------
; Console output.

print_eol:
        ld      c, string_output
        ld      de, end_of_line
        jp      bdos

print_decimal:
power10 defl    1000
        dup     4
        ld      de, power10
        call    print_digit
power10 defl    power10 / 10
        edup
        ret

print_decimal_2:
power10 defl    10
        dup     2
        ld      de, power10
        call    print_digit
power10 defl    power10 / 10
        edup
        ret

print_digit:
        ld      a, '0' - 1
1:
        add     a, 1
        sbc     hl, de
        jr      nc, 1b
        add     hl, de
        ld      c, console_output
        ld      e, a
        push    hl
        call    bdos
        pop     hl
        ret

print_time:
        ld      de, 0
        exx
        ld      bc, 60
        exx
        call    div32x16
        exx
        push    hl
        exx
        call    print_decimal
        ld      e, '.'
        ld      c, console_output
        call    bdos
        pop     hl
        ld      bc, 100
        muluw   hl, bc
        ld      bc, 60
        call    div32x16
        jp      print_decimal_2

end_of_line:
        db      13, 10, '$'

; ----------------------------------------------------------------
; Variables

var_k   dw      0
var_i   dw      0
var_b   dw      0
var_c   dw      0
var_d   dword   0
save_jiffy dw   0

; ----------------------------------------------------------------

vector_r:

        end

