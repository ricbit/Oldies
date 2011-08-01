
CR              equ     13
LF              equ     10
PAGE1           equ     04000h

EXPTBL          equ     0FCC1h

PSLOT           equ     0A8h            ; primary slot selection port
SSLOT           equ     0FFFFh          ; secondary slot selection port
MAPPER1         equ     0FDh
MEGARAM         equ     08Eh
ENASLT          equ     0024h

; Check for MegaRAM, return slot in A (CALSLT format), 255 if not found
FIND_MEGARAM:
	ld      a,1
	call    findram         ; search for MegaRAM
	ld      (mrslt),a
	ret

; Check for Mapper, return slot in A (CALSLT format), 255 if not found
mapper: xor     a
	call    findram         ; search for Mapper
	ld      (mapslt),a
	ret

; Return MegaRAM size (number of 8k pages) in A
sizmega:ld      a,(mrslt)
	cp      255
	ret     z
	ld      b,a
	ld      a,1
	call    sizetst
	ret

; Return Mapper size (number of 16k pages) in A
sizmapp:ld      a,(mapslt)
	cp      255
	ret     z
	ld      b,a
	xor     a
	call    sizetst
	ret

; Search for MegaRAM (A=1) or Mapper (A=0) and return its slot (0FFh=not found)
; WARNING! This is a destructive test for Memory Mapper!
findram:ld      (memtest),a
	call    savecnf         ; save slot configuration
	xor     a
	ld      hl,exptbl       ; HL=expanded slot table
	ld      b,4             ; B=number of promary slots
fr1:    ld      (slot1),a
	ld      (slot2),a
	bit     7,(hl)          ; expanded?
	jr      nz,fr5
	call    test
	jr      c,fr3
fr2:    inc     hl
	ld      a,(slot1)
	inc     a
	djnz    fr1
	ld      a,255
	jr      fr4
fr3:    ld      a,(slot2)
fr4:    call    restcnf         ; restore slot configuration
	ret
; search for MegaRAM/Mapper on expanded slots
fr5:    push    bc
	push    hl
	ld      e,0             ; E=subslot 0
	ld      b,4             ; B=number of subslots
fr6:    ld      a,e
	rla
	rla
	and     00001100B
	ld      c,a
	ld      a,(slot1)
	and     00000011B
	or      c
	set     7,a
	ld      (slot2),a       ; A=subslot in CALSLT format
	call    test            ; search subslot
	jr      c,fr7           ; found
	inc     e
	djnz    fr6
fr7:    pop     hl
	pop     bc
	jp      nc,fr2
	jr      fr3
; Check for MegaRAM/Mapper in subslot in A
test:   push    bc
	push    de
	push    hl
	ld      a,(slot2)
	call    enapg1
	ld      a,(PAGE1)
	push    af              ; save slot byte at addr 4000h
	ld      e,0ACh          ; first test
	call    testmm
	ld      e,0CAh          ; second test
	call    testmm
test1:  pop     af
	ld      (PAGE1),a       ; restore slot byte at addr 4000h
	scf                     ; flag C - sucess
	jr      test4
; test subslot for Mapper or MegaRAM (pattern in E)
testmm: ld      a,(memtest)
	or      a
	jr      nz,testmr
; test subslot for Mapper (pattern in E)
testmp: out     (MEGARAM),a     ; prevent confusing MegaRAM with Mapper
	ld      a,2
	out     (MAPPER1),a
	ld      a,e             ; E=pattern byte
	ld      (PAGE1),a
	ld      a,1
	out     (MAPPER1),a
	xor     a
	ld      (PAGE1),a
	ld      a,2
	out     (MAPPER1),a
	jr      test2
; test subslot for MegaRAM (pattern in E)
testmr: out     (MEGARAM),a     ; MegaRAM ROM mode
	xor     a
	ld      (PAGE1),a       ; MegaRAM page 0
	in      a,(MEGARAM)     ; MegaRAM RAM mode
	ld      a,e             ; E=pattern byte
	ld      (PAGE1),a
	out     (MEGARAM),a     ; MegaRAM ROM mode
	xor     a
	ld      (PAGE1),a       ; MegaRAM page 0
test2:  ld      a,(PAGE1)
	pop     hl              ; HL=return address
	cp      e               ; RAM?
	jr      nz,test3        ; no: go to fail routine
	jp      (hl)            ; yes: return
; Fail routine
test3:  pop     af              ; restore slot 4000h byte
	ld      (PAGE1),a
	xor     a               ; flag NC - no success
test4:  pop     hl
	pop     de
	pop     bc
	ret

; Return the last page in A of MegaRAM (A=1) or Mapper (A=0) in slot in B
; WARNING! This is a destructive test!
sizetst:call    savecnf
	ld      (memtest),a
	ld      a,b
	call    enapg1          ; enable MegaRAM/Mapper at slot B
	ld      a,0
	call    sizechg
	ld      hl,srchstr      ; put flag on page 0
	ld      de,PAGE1+1000h
	ld      bc,17
	ldir
	ld      a,(memtest)
	or      a
	jr      nz,st1
	ld      a,3             ; start Mapper test at page 3, MegaRAM at 1
st1:    ld      hl,PAGE1+1080h    ; clear test area
	ld      de,PAGE1+1081h
	ld      bc,27
	ld      (hl),0
	ldir
	call    sizechg
	ld      hl,stopstr
	ld      de,PAGE1+1080h
	ld      bc,12
	ldir                    ; copy test pattern
	push    af
	ld      hl,srchstr
	ld      de,PAGE1+1000h
	ld      b,17
	call    compare         ; we reached again page 0?
	jr      z,st2           ; if yes, terminate test
	ld      hl,stopstr
	ld      de,PAGE1+1080h
	ld      b,12
	call    compare         ; this page is RAM?
	jr      nz,st2          ; if no, terminate test
	pop     af
	inc     a
	jr      st1             ; next page
st2:    ld      a,(memtest)     ; test end:
	or      a
	jr      nz,st3
	ld      a,3
st3:    dec     a
	call    sizechg         ; restore MegaRAM/Mapper page
	call    restcnf
	pop     af
	dec     a
	ret

; Select MegaRAM/Mapper (memtest=1/0) page A at RAM page 1
sizechg:push    af
	ld      a,(memtest)
	or      a
	jr      nz,sc1
	pop     af
	out     (MAPPER1),a
	ret
sc1:    pop     af
	push    af
	out     (MEGARAM),a
	ld      (PAGE1),a
	in      a,(MEGARAM)
	pop     af
	ret

; Enable page 1 in slot in A (CALSLT format)
enapg1: 
	push    af
	push    bc
	push    de
	ld      d,a
	and     00000011B
	rlca
	rlca
	ld      b,a
	rlca
	rlca
	rlca
	rlca
	or      b
	ld      b,a
	in      a,(PSLOT)               ; set main slot
	and     11110011b
	ld      c,a
	and     00110011b
	or      b
	out     (PSLOT),a
	ld      a,d
	and     00001100B
	ld      b,a
	ld      a,(SSLOT)
	cpl
	and     11110011B
	or      b
	ld      (SSLOT),a               ; set subslot
	ld      a,d
	and     11b
	rlca
	rlca
	or      c
	out     (PSLOT),a
	pop     de
	pop     bc
	pop     af
	
	ret

; Save actual slot configuration
savecnf:push    af
	in      a,(PSLOT)
	ld      (conf),a
	ld      a,(SSLOT)
	ld      (conf1),a
	pop     af
	ret

; Restore slot configuration
restcnf:push    af
	ld      a,(conf)
	out     (PSLOT),a
	ld      a,(conf1)
	cpl
	ld      (SSLOT),a
	pop     af
	ret

; Compare two regions of memory (HL and DE, size in B): flag Z if match
compare:ld      a,(de)
	cp      (hl)
	ret     nz
	inc     hl
	inc     de
	djnz    compare
	ret

; working variables
srchstr:defm    'A&L Software 1998'
stopstr:defm    'MSX for ever'
conf:   defb    0
conf1:  defb    0
slot1:  defb    0
slot2:  defb    0
mapslt: defb    0
mrslt:  defb    0
memtest:defb    0

endprg: 
