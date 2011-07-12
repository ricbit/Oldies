 OPENFILE              = 1
 READFILE              = 1
 WRITEFILE             = 1
 LSEEKFILE             = 1
 CREATEFILE            = 1
 FILESIZE              = 1
 FILECOPY              = 1
 DELETEFILE            = 1
 FINDFILE              = 1
        .386p
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc

public  _filebufloc, _filebuflen
public  _closefile

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
_filebufloc     dd      0               ; location must be in low mem
_filebuflen     dw      4000h
oplen           dd      ?

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

ifdef   CREATEFILE
public  _createfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Create file
; In:
;   EDX -> ASCIIZ filename
; Out:
;   CF=1 - Error creating file
;   CF=0 - File created succesfully
;     V86R_BX - file handle
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_createfile:
        push ax
        push edx
        add edx,_code32a
        mov ax,dx
        shr edx,4
        and ax,0fh
        mov v86r_dx,ax
        mov v86r_ds,dx
        mov v86r_ax,3c00h
        mov v86r_cx,20h
        mov al,21h
        int 30h
        mov ax,v86r_ax
        mov v86r_bx,ax
        pop edx
        pop ax
        bt word ptr v86r_flags,0
        ret
endif

ifdef   OPENFILE
public  _openfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Open file
; In:
;   EDX -> ASCIIZ filename
; Out:
;   CF=1 - Error opening file
;   CF=0 - File opened succesfully
;     V86R_BX - file handle
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_openfile:
        push ax
        push edx
        add edx,_code32a
        mov ax,dx
        shr edx,4
        and ax,0fh
        mov v86r_dx,ax
        mov v86r_ds,dx
        mov v86r_ax,3d02h
        mov al,21h
        int 30h
        mov ax,v86r_ax
        mov v86r_bx,ax
        pop edx
        pop ax
        bt word ptr v86r_flags,0
        ret
endif

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Close a file
; In:
;   V86R_BX - file handle
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_closefile:
        push ax
        mov v86r_ax,3e00h
        mov al,21h
        int 30h
        pop ax
        ret

ifdef   DELETEFILE
public  _deletefile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Delete a file
; In:
;   EDX -> ASCIIZ filename
; Out:
;   CF=1 - Error opening file
;   CF=0 - File opened succesfully
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_deletefile:
        push ax
        push edx
        add edx,_code32a
        mov ax,dx
        shr edx,4
        and ax,0fh
        mov v86r_dx,ax
        mov v86r_ds,dx
        mov v86r_ah,41h
        mov al,21h
        int 30h
        pop edx
        pop ax
        bt word ptr v86r_flags,0
        ret
endif

ifdef   LSEEKFILE
public  _lseekfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Seek position in file
; In:
;   V86R_BX - file handle
;   EAX - signed offset to move to
;   BL - from: 0-beginning of file, 1-current location, 2-end of file
; Out:
;   CF=1  - Error seeking in file
;     EAX - ?
;   CF=0  - Seek fine
;     EAX - new offset from beginning of file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_lseekfile:
        mov v86r_ah,42h
        mov v86r_al,bl
        mov v86r_dx,ax
        shr eax,16
        mov v86r_cx,ax
        mov al,21h
        int 30h
        mov ax,v86r_dx
        shl eax,16
        mov ax,v86r_ax
        bt v86r_flags,0
        ret
endif

ifdef   FILESIZE
public  _filesize
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get size of file
; In:
;   V86R_BX - file handle
; Out:
;   CF=1  - Error checking file
;     EAX - ?
;   CF=0  - chek fine
;     EAX - size of file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_filesize:
        mov v86r_ax,4201h
        xor eax,eax
        mov v86r_cx,ax
        mov v86r_dx,ax
        mov al,21h
        int 30h
        push v86r_dx
        push v86r_ax
        mov v86r_ax,4202h
        xor eax,eax
        mov v86r_cx,ax
        mov v86r_dx,ax
        mov al,21h
        int 30h
        mov ax,v86r_dx
        shl eax,16
        mov ax,v86r_ax
        pop v86r_dx
        pop v86r_cx
        mov v86r_ax,4200h
        push eax
        mov al,21h
        int 30h
        pop eax
        bt v86r_flags,0
        ret
endif

ifdef   READFILE
public  _readfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Read from file
; In:
;   V86R_BX - file handle
;   EDX -> buffer to read to
;   ECX - number of bytes to read
; Out:
;   CF=1 - Error reading file
;     EAX - ?
;   CF=0 - Read went fine
;     EAX - number of bytes read
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_readfile:
        pushad
        xor ebp,ebp
        add edx,_code32a
        lea ebx,[ecx+edx]
        cmp ebx,100000h
        ja readlong
        mov eax,edx
        shr eax,4
        and dx,0fh
        mov v86r_ds,ax
        mov v86r_dx,dx
readl:
        mov eax,0fff0h
        cmp eax,ecx
        jbe readlf1
        mov eax,ecx
readlf1:
        mov v86r_cx,ax
        mov v86r_ax,3f00h
        mov al,21h
        int 30h
        movzx ebx,v86r_ax
        add ebp,ebx
        sub ecx,ebx
        jbe readdone
        or ebx,ebx
        jz readdone
        add v86r_ds,0fffh
        jmp readl
readlong:
        mov edi,edx
        sub edi,_code32a
        mov edx,ecx
        mov eax,_filebufloc
        add eax,_code32a
        mov ebx,eax
        shr eax,4
        and bx,0fh
        mov v86r_ds,ax
        mov v86r_dx,bx
        movzx ebx,_filebuflen
readlongl:
        mov eax,ebx
        cmp eax,edx
        jbe readlonglf1
        mov eax,edx
readlonglf1:
        mov v86r_cx,ax
        mov v86r_ax,3f00h
        mov al,21h
        int 30h
        movzx ecx,v86r_ax
        add ebp,ecx
        mov eax,ecx
        or eax,eax
        jz readdone
        mov esi,_filebufloc
        rep movsb
        sub edx,eax
        ja readlongl
readdone:
        mov oplen,ebp
        popad
        mov eax,oplen
        bt v86r_flags,0
        ret
endif

ifdef   WRITEFILE
public  _writefile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Write to file
; In:
;   V86R_BX - file handle
;   EDX -> buffer to write from
;   ECX - number of bytes to write
; Out:
;   CF=1 - Error writing file
;     EAX - ?
;   CF=0 - Write went fine
;     EAX - number of bytes read
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_writefile:
        pushad
        xor ebp,ebp
        add edx,_code32a
        lea ebx,[ecx+edx]
        cmp ebx,100000h
        ja writelong
        mov eax,edx
        shr edx,4
        and ax,0fh
        mov v86r_ds,dx
        mov v86r_dx,ax
writel:
        mov eax,0fff0h
        cmp eax,ecx
        jbe writelf1
        mov eax,ecx
writelf1:
        mov v86r_cx,ax
        mov v86r_ax,4000h
        mov al,21h
        int 30h
        movzx ebx,v86r_ax
        add ebp,ebx
        sub ecx,ebx
        jbe writedone
        add v86r_ds,0fffh
        jmp writel
writelong:
        mov esi,edx
        sub esi,_code32a
        mov edx,ecx
        mov eax,_filebufloc
        add eax,_code32a
        mov ebx,eax
        shr eax,4
        and bx,0fh
        mov v86r_ds,ax
        mov v86r_dx,bx
        movzx ebx,_filebuflen
writelongl:
        mov eax,ebx
        cmp eax,edx
        jbe writelonglf1
        mov eax,edx
writelonglf1:
        mov ecx,eax
        mov edi,_filebufloc
        rep movsb
        mov v86r_cx,ax
        mov v86r_ax,4000h
        mov al,21h
        int 30h
        movzx ecx,v86r_ax
        add ebp,ecx
        sub edx,ecx
        ja writelongl
writedone:
        mov oplen,ebp
        popad
        mov eax,oplen
        bt v86r_flags,0
        ret
endif

ifdef   FILECOPY
public  _filecopy
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Copy some bytes from one file to another
; In:
;   V86R_SI - source file handle
;   V86R_DI - destination file handle
;   ECX - number of bytes to copy
; Out:
;   CF=1  - Error copying file
;     EAX - ?
;   CF=0  - copied fine
;     EAX - number of bytes copied
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_filecopy:
        pushad
        xor ebp,ebp
        mov edx,_filebufloc
        add edx,_code32a
        mov al,dl
        and ax,0fh
        shr edx,4
        mov v86r_ds,dx
        mov v86r_dx,ax
        movzx ebx,_filebuflen
copylongl:
        mov eax,ebx
        cmp eax,ecx
        jbe copylonglf1
        mov eax,ecx
copylonglf1:
        mov v86r_cx,ax
        mov v86r_ax,3f00h
        mov ax,v86r_si
        mov v86r_bx,ax
        mov al,21h
        int 30h
        mov ax,v86r_ax
        or ax,ax
        jz copydone
        mov v86r_cx,ax
        mov v86r_ax,4000h
        mov ax,v86r_di
        mov v86r_bx,ax
        mov al,21h
        int 30h
        movzx edx,v86r_ax
        add ebp,edx
        sub ecx,edx
        ja copylongl
copydone:
        mov oplen,ebp
        popad
        mov eax,oplen
        bt v86r_flags,0
        ret
endif

ifdef   FINDFILE
public  _findfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Do an AH=4E findfirst
; In:
;   AL - type of search: 4E-first, 4F-next
;   EDX -> 13 byte buffer for filename found
;   EDI -> search mask
; Out:
;   CF=1 - file not found
;     [EDX] - ?
;   CF=0 - file found
;     [EDX] - filename
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_findfile:
        push eax
        push esi
        push edi
        add edi,_code32a
        mov esi,edi
        and esi,0fh
        shr edi,4
        mov v86r_ds,di
        mov v86r_dx,si
        mov v86r_ah,al
        mov v86r_cx,20h
        mov al,21h
        int 30h
        mov esi,_code16a
        sub esi,62h
        mov edi,edx
        mov ax,gs
        mov ds,ax
        movsd
        movsd
        movsd
        movsb
        mov ax,es
        mov ds,ax
        pop edi
        pop esi
        pop eax
        bt v86r_flags,0
        ret
endif


code32  ends
        end

