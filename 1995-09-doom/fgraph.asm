  ; Fast Graphics Header File
  ; Ricardo Bittencourt (9/1995)

  .386C
  IDEAL
  MODEL LARGE,C

  CODESEG

; void InitGraph (void)
;
public InitGraph
PROC InitGraph

  push  bp
  mov   ax,00013h
  int   010h
  pop   bp
  ret

ENDP

; void CloseGraph (void)
;
public CloseGraph
PROC CloseGraph

  push  bp
  mov   ax,00003h
  int   010h
  pop   bp
  ret

ENDP

; void PutPixel (int x, int y, unsigned char color)
; x=  [bp+06] (2)
; y=  [bp+08] (2)
; cor=[bp+10] (1)
;
public PutPixel
PROC PutPixel

  push  bp
  mov   bp,sp
  mov   ax,0A000h
  mov   es,ax
  movzx ebx,[word bp+08]
  lea   ebx,[ebx+ebx*4] ; ebx = ebx*5
  shl   ebx,6           ; ebx = ebx*64
  add   bx,[bp+06]
  mov   al,[bp+10]
  mov   [es:bx],al
  pop   bp
  ret

ENDP

; void ClearScreen (unsigned char color)
; cor=[bp+06] (1)
;
public ClearScreen
PROC ClearScreen

  push  bp
  mov   bp,sp
  mov   ax,0A000h
  mov   es,ax
  mov   edi,0
  mov   ecx,320*200/4
  mov   bh,[bp+06]
  mov   bl,bh
  mov   ax,bx
  shl   ebx,16
  and   eax,0FFFFh
  or    eax,ebx
  cld
  rep   stosd
  pop   bp
  ret

ENDP

; void SetRGB (unsigned char color,
;              unsigned char r, unsigned char g, unsigned char b);
; color=[bp+04] (1)
; r=    [bp+06] (1)
; g=    [bp+08] (1)
; b=    [bp+10] (1)
;
public SetRGB
PROC SetRGB

  push  bp
  mov   bp,sp
  add   bp,2
  mov   dx,03C8h
  mov   al,[bp+04]
  out   dx,al
  inc   dx
  mov   al,[bp+06]
  out   dx,al
  mov   al,[bp+08]
  out   dx,al
  mov   al,[bp+10]
  out   dx,al
  pop   bp
  ret

ENDP

; void Line (int x1, int y1, int x2, int y2, unsigned char color)
; x1=   [bp+04] (2)
; y1=   [bp+06] (2)
; x2=   [bp+08] (2)
; y2=   [bp+10] (2)
; color=[bp+12] (1)
;
public Line
PROC Line

  push  bp
  mov   bp,sp
  add   bp,2
  push  ds
  mov   ax,0A000h
  mov   ds,ax           ; ds = video segment
  mov   ax,[bp+06]
  mov   dx,320
  mul   dx
  mov   di,[bp+04]
  add   di,ax           ; di = (320*y1+x1)
  mov   bl,[bp+12]      ; bl = color
  mov   dx,[bp+08]
  sub   dx,[bp+04]      ; dx = (x2-x1)
  cmp   dx,0
  jge   LineDxg         ; if (dx<0) goto LineDxl
  jmp   LineDxl

LineDxg:
  mov   si,[bp+10]
  sub   si,[bp+06]      ; si = (y2-y1)
  cmp   si,0
  jl    LineDxgDyl      ; if (si<0) goto LineDxgDyl
  cmp   dx,si
  jl    LineDxgDygAy    ; if (dx<dy) goto LineDxgDygAy

  ; case 0: dx>0 dy>0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  mov   cx,dx           ; cx = (x2-x1)
  shl   dx,1            ; dx *= 2
  inc   cx
LineInloop0:
  mov   [di],bl
  dec   cx
  jz    LineExitg
  cmp   ax,0
  jl    LineNoup0
  add   di,320
  sub   ax,dx
LineNoup0:
  inc   di
  add   ax,si
  jmp   LineInloop0

  ; case 1: dx>0 dy>0 ay>ax
LineDxgDygAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  mov   cx,si           ; cx = (y2-y1)
  shl   si,1            ; si *= 2
  inc   cx
LineInloop1:
  mov   [di],bl
  dec   cx
  jz    LineExitg
  cmp   ax,0
  jl    LineNoup1
  inc   di
  sub   ax,si
LineNoup1:
  add   di,320
  add   ax,dx
  jmp   LineInloop1

LineExitg:
  pop   ds
  pop   bp
  ret

LineDxgDyl:
  neg   si
  cmp   dx,si
  jl    LineDxgDylAy    ; if (dx<dy) goto LineDxgDylAy

  ; case 2: dx>0 dy<0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  mov   cx,dx           ; cx = (x2-x1)
  shl   dx,1            ; dx *= 2
  inc   cx
LineInloop2:
  mov   [di],bl
  dec   cx
  jz    LineExitg
  cmp   ax,0
  jl    LineNoup2
  sub   di,320
  sub   ax,dx
LineNoup2:
  inc   di
  add   ax,si
  jmp   LineInloop2

  ; case 3: dx>0 dy<0 ay>ax
LineDxgDylAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  mov   cx,si           ; cx = (y2-y1)
  shl   si,1            ; si *= 2
  inc   cx
LineInloop3:
  mov   [di],bl
  dec   cx
  jz    LineExitg
  cmp   ax,0
  jl    LineNoup3
  inc   di
  sub   ax,si
LineNoup3:
  sub   di,320
  add   ax,dx
  jmp   LineInloop3

LineDxl:
  neg   dx
  mov   si,[bp+10]
  sub   si,[bp+06]      ; si = (y2-y1)
  cmp   si,0
  jl    LineDxlDyl      ; if (si<0) goto LineDxlDyl
  cmp   dx,si
  jl    LineDxlDygAy    ; if (dx<dy) goto LineDxlDygAy

  ; case 4: dx<0 dy>0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  mov   cx,dx           ; cx = (x2-x1)
  shl   dx,1            ; dx *= 2
  inc   cx
LineInloop4:
  mov   [di],bl
  dec   cx
  jz    LineExitl
  cmp   ax,0
  jl    LineNoup4
  add   di,320
  sub   ax,dx
LineNoup4:
  dec   di
  add   ax,si
  jmp   LineInloop4

  ; case 5: dx<0 dy>0 ay>ax
LineDxlDygAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  mov   cx,si           ; cx = (y2-y1)
  shl   si,1            ; si *= 2
  inc   cx
LineInloop5:
  mov   [di],bl
  dec   cx
  jz    LineExitl
  cmp   ax,0
  jl    LineNoup5
  dec   di
  sub   ax,si
LineNoup5:
  add   di,320
  add   ax,dx
  jmp   LineInloop5

LineExitl:
  pop   ds
  pop   bp
  ret

LineDxlDyl:
  neg   si
  cmp   dx,si
  jl    LineDxlDylAy    ; if (dx<dy) goto LineDxlDylAy

  ; case 6: dx<0 dy<0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  mov   cx,dx           ; cx = (x2-x1)
  shl   dx,1            ; dx *= 2
  inc   cx
LineInloop6:
  mov   [di],bl
  dec   cx
  jz    LineExitl
  cmp   ax,0
  jl    LineNoup6
  sub   di,320
  sub   ax,dx
LineNoup6:
  dec   di
  add   ax,si
  jmp   LineInloop6

  ; case 7: dx<0 dy<0 ay>ax
LineDxlDylAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  mov   cx,si           ; cx = (y2-y1)
  shl   si,1            ; si *= 2
  inc   cx
LineInloop7:
  mov   [di],bl
  dec   cx
  jz    LineExitl
  cmp   ax,0
  jl    LineNoup7
  dec   di
  sub   ax,si
LineNoup7:
  sub   di,320
  add   ax,dx
  jmp   LineInloop7

ENDP

; unsigned char GetPixel (int x, int y)
; x = [bp+06]
; y = [bp+08]
;
public GetPixel
PROC GetPixel

  push  bp
  mov   bp,sp
  movzx ebx,[word bp+08]
  lea   ebx,[ebx+ebx*4]
  shl   ebx,6
  add   bx,[bp+06]
  mov   ax,0A000h
  mov   es,ax
  xor   ax,ax
  mov   al,[es:bx]
  pop   bp
  ret

ENDP

; void PutShape (int x, int y, int dx, int dy, unsigned char far *shape)
; x =     [bp+04] (2)
; y =     [bp+06] (2)
; dx =    [bp+08] (2)
; dy =    [bp+10] (2)
; shape = [bp+12] (4)
;
public PutShape
PROC PutShape

  push  bp
  mov   bp,sp
  add   bp,2
  push  ds
  mov   ax,[bp+14]
  mov   ds,ax           ;ds = seg (shape)
  mov   ax,0A000h
  mov   es,ax           ;es = video segment
  mov   ax,[bp+12]
  mov   si,ax           ;si = ofs (shape)
  mov   bx,320
  mov   ax,[bp+06]
  mul   bx
  mov   di,[bp+04]
  add   di,ax           ;di = 320*y+x
  mov   ax,[bp+08]
  sub   bx,ax           ;bx = 320-D(x)
  mov   dx,[bp+10]      ;dx = D(y)
  shr   ax,2            ;ax = D(x)/4
PutShapeLoop:
  mov   cx,ax           ;cx = D(x)/4
  rep   movsd
  add   di,bx
  dec   dx
  jnz   PutShapeLoop
  pop   ds
  pop   bp
  ret

ENDP

; void PrecLine (int x1, int y1, int x2, int y2, int far *points)
; x1 =     [bp+04] (2)
; y1 =     [bp+06] (2)
; x2 =     [bp+08] (2)
; y2 =     [bp+10] (2)
; points = [bp+12] (4)
;
public PrecLine
PROC PrecLine

  push  bp
  mov   bp,sp
  add   bp,2
  push  ds
  mov   ds,[bp+14]      ; ds = seg (points)
  mov   di,[bp+12]      ; di = ofs (points)
  mov   dx,[bp+08]
  sub   dx,[bp+04]      ; dx = (x2-x1)
  cmp   dx,0
  jge   PrecLineDxg     ; if (dx<0) goto PrecLineDxl
  jmp   PrecLineDxl

PrecLineDxg:
  mov   si,[bp+10]
  sub   si,[bp+06]      ; si = (y2-y1)
  cmp   si,0
  jl    PrecLineDxgDyl      ; if (si<0) goto PrecLineDxgDyl
  cmp   dx,si
  jl    PrecLineDxgDygAy    ; if (dx<dy) goto PrecLineDxgDygAy

  ; case 0: dx>0 dy>0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecLineInloop0:
  mov   [di],cx
  add   di,2
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx      ; cx == x2 ?
  jz    PrecLineExitg
  cmp   ax,0
  jl    PrecLineNoup0
  inc   bx
  sub   ax,dx
PrecLineNoup0:
  inc   cx
  add   ax,si
  jmp   PrecLineInloop0

  ; case 1: dx>0 dy>0 ay>ax
PrecLineDxgDygAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecLineInloop1:
  mov   [di],bx
  add   di,2
  mov   [di],cx
  add   di,2
  cmp   [bp+10],cx      ; cx == y2 ?
  jz    PrecLineExitg
  cmp   ax,0
  jl    PrecLineNoup1
  inc   bx
  sub   ax,si
PrecLineNoup1:
  inc   cx
  add   ax,dx
  jmp   PrecLineInloop1

PrecLineExitg:
  mov   [word di],0FFFFh
  add   di,2
  mov   [word di],0FFFFh
  pop   ds
  pop   bp
  ret

PrecLineDxgDyl:
  neg   si
  cmp   dx,si
  jl    PrecLineDxgDylAy    ; if (dx<dy) goto PrecLineDxgDylAy

  ; case 2: dx>0 dy<0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecLineInloop2:
  mov   [di],cx
  add   di,2
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx
  jz    PrecLineExitg
  cmp   ax,0
  jl    PrecLineNoup2
  dec   bx
  sub   ax,dx
PrecLineNoup2:
  inc   cx
  add   ax,si
  jmp   PrecLineInloop2

  ; case 3: dx>0 dy<0 ay>ax
PrecLineDxgDylAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecLineInloop3:
  mov   [di],bx
  add   di,2
  mov   [di],cx
  add   di,2
  cmp   [bp+10],cx
  jz    PrecLineExitg
  cmp   ax,0
  jl    PrecLineNoup3
  inc   bx
  sub   ax,si
PrecLineNoup3:
  dec   cx
  add   ax,dx
  jmp   PrecLineInloop3

PrecLineDxl:
  neg   dx
  mov   si,[bp+10]
  sub   si,[bp+06]      ; si = (y2-y1)
  cmp   si,0
  jl    PrecLineDxlDyl      ; if (si<0) goto PrecLineDxlDyl
  cmp   dx,si
  jl    PrecLineDxlDygAy    ; if (dx<dy) goto PrecLineDxlDygAy

  ; case 4: dx<0 dy>0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecLineInloop4:
  mov   [di],cx
  add   di,2
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx
  jz    PrecLineExitl
  cmp   ax,0
  jl    PrecLineNoup4
  inc   bx
  sub   ax,dx
PrecLineNoup4:
  dec   cx
  add   ax,si
  jmp   PrecLineInloop4

  ; case 5: dx<0 dy>0 ay>ax
PrecLineDxlDygAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecLineInloop5:
  mov   [di],bx
  add   di,2
  mov   [di],cx
  add   di,2
  cmp   [bp+10],cx
  jz    PrecLineExitl
  cmp   ax,0
  jl    PrecLineNoup5
  dec   bx
  sub   ax,si
PrecLineNoup5:
  inc   cx
  add   ax,dx
  jmp   PrecLineInloop5

PrecLineExitl:
  mov   [word di],0FFFFh
  add   di,2
  mov   [word di],0FFFFh
  pop   ds
  pop   bp
  ret

PrecLineDxlDyl:
  neg   si
  cmp   dx,si
  jl    PrecLineDxlDylAy    ; if (dx<dy) goto PrecLineDxlDylAy

  ; case 6: dx<0 dy<0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecLineInloop6:
  mov   [di],cx
  add   di,2
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx
  jz    PrecLineExitl
  cmp   ax,0
  jl    PrecLineNoup6
  dec   bx
  sub   ax,dx
PrecLineNoup6:
  dec   cx
  add   ax,si
  jmp   PrecLineInloop6

  ; case 7: dx<0 dy<0 ay>ax
PrecLineDxlDylAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecLineInloop7:
  mov   [di],bx
  add   di,2
  mov   [di],cx
  add   di,2
  cmp   [bp+10],cx
  jz    PrecLineExitl
  cmp   ax,0
  jl    PrecLineNoup7
  dec   bx
  sub   ax,si
PrecLineNoup7:
  dec   cx
  add   ax,dx
  jmp   PrecLineInloop7

ENDP

; void MappingLine (int dx, int far *points)
; dx =     [bp+04] (2)
; points = [bp+06] (4)
;
public MappingLine
PROC MappingLine

  push  bp
  mov   bp,sp
  add   bp,2
  push  ds
  mov   dx,[bp+04]      ; dx = D(x)
  lds   di,[bp+06]      ; ds:[di] = points
  cmp   dx,99
  jl    MappingLineL
  mov   si,dx           ; si = D(x)
  mov   ax,198
  sub   ax,dx
  shl   dx,1
  mov   cx,0
  inc   si
MappingLineGL:
  mov   [di],cx
  add   di,2
  dec   si
  jz    MappingExit
  cmp   ax,0
  jl    MappingLineGO
  inc   cx
  sub   ax,dx
MappingLineGO:
  add   ax,198
  jmp   MappingLineGL

MappingLineL:
  mov   cx,dx           ; cx = D(x)
  inc   cx
  mov   ax,0
  mov   bx,0
  mov   si,bx
MappingLineLL:
  cmp   ax,0
  jge   MappingLineLO
  add   ax,dx
  inc   bx
  jmp   MappingLineLL
MappingLineLO:
  sub   ax,99
  mov   [di],bx
  add   di,2
  loop  MappingLineLL

MappingExit:
  pop   ds
  pop   bp
  ret

ENDP

; void FlushBuffer (unsigned char far *buffer)
; buffer = [bp+06]
;
public FlushBuffer
PROC FlushBuffer

  push  bp
  mov   bp,sp
  push  ds
  lds   si,[bp+06]
  and   esi,0FFFFh
  mov   edi,0
  mov   ax,0A000h
  mov   es,ax
  mov   ecx,64000/4
  cld
  mov   dx,03DAh                ; wait for vertical retrace
FlushBufferLoop:
  in    al,dx
  test  al,8
  jz    FlushBufferLoop
  rep   movsd
  pop   ds
  pop   bp
  ret

ENDP

; void ClearBuffer (unsigned char far *buffer)
; buffer = [bp+06]
;
public ClearBuffer
PROC ClearBuffer

  push  bp
  mov   bp,sp
  les   di,[bp+06]
  and   edi,0FFFFh
  mov   ecx,64000/4
  mov   eax,0
  cld
  rep   stosd
  pop   bp
  ret

ENDP

; void PrecYLine (int x1, int y1, int x2, int y2, int far *points)
; x1 =     [bp+04] (2)
; y1 =     [bp+06] (2)
; x2 =     [bp+08] (2)
; y2 =     [bp+10] (2)
; points = [bp+12] (4)
;
public PrecYLine
PROC PrecYLine

  push  bp
  mov   bp,sp
  add   bp,2
  push  ds
  lds   di,[bp+12]
  mov   dx,[bp+08]
  sub   dx,[bp+04]      ; dx = (x2-x1)
  cmp   dx,0
  jge   PrecYLineDxg     ; if (dx<0) goto PrecYLineDxl
  jmp   PrecYLineDxl

PrecYLineDxg:
  mov   si,[bp+10]
  sub   si,[bp+06]      ; si = (y2-y1)
  cmp   si,0
  jl    PrecYLineDxgDyl      ; if (si<0) goto PrecYLineDxgDyl
  cmp   dx,si
  jl    PrecYLineDxgDygAy    ; if (dx<dy) goto PrecYLineDxgDygAy

  ; case 0: dx>0 dy>0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecYLineInloop0:
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx      ; cx == x2 ?
  jz    PrecYLineExitg
  cmp   ax,0
  jl    PrecYLineNoup0
  inc   bx
  sub   ax,dx
PrecYLineNoup0:
  inc   cx
  add   ax,si
  jmp   PrecYLineInloop0

  ; case 1: dx>0 dy>0 ay>ax
PrecYLineDxgDygAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecYLineInloop1:
  mov   [di],cx
  cmp   [bp+10],cx      ; cx == y2 ?
  jz    PrecYLineExitg
  cmp   ax,0
  jl    PrecYLineNoup1
  add   di,2
  inc   bx
  sub   ax,si
PrecYLineNoup1:
  inc   cx
  add   ax,dx
  jmp   PrecYLineInloop1

PrecYLineExitg:
  pop   ds
  pop   bp
  ret

PrecYLineDxgDyl:
  neg   si
  cmp   dx,si
  jl    PrecYLineDxgDylAy    ; if (dx<dy) goto PrecYLineDxgDylAy

  ; case 2: dx>0 dy<0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecYLineInloop2:
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx
  jz    PrecYLineExitg
  cmp   ax,0
  jl    PrecYLineNoup2
  dec   bx
  sub   ax,dx
PrecYLineNoup2:
  inc   cx
  add   ax,si
  jmp   PrecYLineInloop2

  ; case 3: dx>0 dy<0 ay>ax
PrecYLineDxgDylAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecYLineInloop3:
  mov   [di],cx
  cmp   [bp+10],cx
  jz    PrecYLineExitg
  cmp   ax,0
  jl    PrecYLineNoup3
  add   di,2
  inc   bx
  sub   ax,si
PrecYLineNoup3:
  dec   cx
  add   ax,dx
  jmp   PrecYLineInloop3

PrecYLineDxl:
  neg   dx
  mov   si,[bp+10]
  sub   si,[bp+06]      ; si = (y2-y1)
  cmp   si,0
  jl    PrecYLineDxlDyl      ; if (si<0) goto PrecYLineDxlDyl
  cmp   dx,si
  jl    PrecYLineDxlDygAy    ; if (dx<dy) goto PrecYLineDxlDygAy

  ; case 4: dx<0 dy>0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecYLineInloop4:
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx
  jz    PrecYLineExitl
  cmp   ax,0
  jl    PrecYLineNoup4
  inc   bx
  sub   ax,dx
PrecYLineNoup4:
  dec   cx
  add   ax,si
  jmp   PrecYLineInloop4

  ; case 5: dx<0 dy>0 ay>ax
PrecYLineDxlDygAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecYLineInloop5:
  mov   [di],cx
  cmp   [bp+10],cx
  jz    PrecYLineExitl
  cmp   ax,0
  jl    PrecYLineNoup5
  add   di,2
  dec   bx
  sub   ax,si
PrecYLineNoup5:
  inc   cx
  add   ax,dx
  jmp   PrecYLineInloop5

PrecYLineExitl:
  pop   ds
  pop   bp
  ret

PrecYLineDxlDyl:
  neg   si
  cmp   dx,si
  jl    PrecYLineDxlDylAy    ; if (dx<dy) goto PrecYLineDxlDylAy

  ; case 6: dx<0 dy<0 ax>ay
  shl   si,1            ; si *= 2
  mov   ax,si
  sub   ax,dx           ; ax = 2*D(y)-D(x)
  shl   dx,1            ; dx *= 2
  mov   cx,[bp+04]      ; cx = x1
  mov   bx,[bp+06]      ; bx = y1
PrecYLineInloop6:
  mov   [di],bx
  add   di,2
  cmp   [bp+08],cx
  jz    PrecYLineExitl
  cmp   ax,0
  jl    PrecYLineNoup6
  dec   bx
  sub   ax,dx
PrecYLineNoup6:
  dec   cx
  add   ax,si
  jmp   PrecYLineInloop6

  ; case 7: dx<0 dy<0 ay>ax
PrecYLineDxlDylAy:
  shl   dx,1            ; dx *= 2
  mov   ax,dx
  sub   ax,si           ; ax = 2*D(x)-D(y)
  shl   si,1            ; si *= 2
  mov   bx,[bp+04]      ; bx = x1
  mov   cx,[bp+06]      ; cx = y1
PrecYLineInloop7:
  mov   [di],cx
  cmp   [bp+10],cx
  jz    PrecYLineExitl
  cmp   ax,0
  jl    PrecYLineNoup7
  add   di,2
  dec   bx
  sub   ax,si
PrecYLineNoup7:
  dec   cx
  add   ax,dx
  jmp   PrecYLineInloop7

ENDP

; void BufferMapping (unsigned char far *Buf, unsigned char far *Tex,
;                     int far *PrecV, int dy, byte decay);
; Buf =   [bp+06] (4)
; Tex =   [bp+10] (4)
; PrecV = [bp+14] (4)
; dy   =  [bp+18] (2)
; decay = [bp+20] (1)
;
public BufferMapping
PROC BufferMapping

  push  bp
  mov   bp,sp
  push  ds
  cld
  mov   di,0
  mov   si,0
  les   di,[bp+06]      ; es:[di] = Buf
  lds   si,[bp+10]      ; ds:[si] = Tex
  lfs   bx,[bp+14]      ; fs:[bx] = PrecV
  mov   cx,[bp+18]      ; cx = dy
  mov   dl,[bp+20]      ; dl = decay
BufferMappingLoop:
;  movsb
;  add   di,319
;  add   si,[fs:bx]
;  add   bx,2
;  loop  BufferMappingLoop

  mov   al,[si]
  sub   al,dl
  js    BufferMappingNeg
  mov   [es:di],al
  add   di,320
  add   si,[fs:bx]
  add   bx,2
  loop  BufferMappingLoop
  pop   ds
  pop   bp
  ret
BufferMappingNeg:
  mov   [byte es:di],0
  add   di,320
  add   si,[fs:bx]
  add   bx,2
  loop  BufferMappingLoop
  pop   ds
  pop   bp
  ret

ENDP

; void BufferMapping2 (unsigned char far *Buf, unsigned char far *Tex,
;                      int far *PrecV, int dy);
; Buf =   [bp+06] (4)
; Tex =   [bp+10] (4)
; PrecV = [bp+14] (4)
; dy   =  [bp+18] (2)
;
public BufferMapping2
PROC BufferMapping2

  push  bp
  mov   bp,sp
  push  ds
  cld
  lds   si,[bp+10]      ; ds:[si] = Tex
  les   di,[bp+06]      ; es:[di] = Buf
  lfs   bx,[bp+14]      ; fs:[bx] = PrecV
;  mov   cx,[bp+18]      ; cx = dy
  mov   cx,99
BufferMappingLoop1:
  movsb
  dec   si
  add   di,319+320
  add   si,[fs:bx]
  add   bx,2
  loop  BufferMappingLoop1
  les   di,[bp+06]      ; es:[di] = Buf
  lds   si,[bp+10]      ; ds:[si] = Tex
  lfs   bx,[bp+14]      ; fs:[bx] = PrecV
;  mov   cx,[bp+18]      ; cx = dy
  mov   cx,99
  add   di,320
BufferMappingLoop2:
  movsb
  add   di,319+320
  add   si,[fs:bx]
  dec   si
  add   bx,2
  loop  BufferMappingLoop2
  pop   ds
  pop   bp
  ret

ENDP

; extern void far SetRGBUniform (void);
;
public SetRGBUniform
PROC SetRGBUniform

  mov   cx,256
  mov   bl,0
  mov   dx,03C8h
  mov   al,0
  out   dx,al
  inc   dx
SetRGBUniformLoop:
  mov   al,bl
  and   al,011100000b
  shr   al,2
  out   dx,al
  mov   al,bl
  and   al,011100b
  add   al,al
  out   dx,al
  mov   al,bl
  and   al,011b
  shl   al,4
  out   dx,al
  inc   bl
  loop  SetRGBUniformLoop
  ret

ENDP

; void GetShape (int x, int y, int dx, int dy, unsigned char far *shape)
; x =     [bp+04] (2)
; y =     [bp+06] (2)
; dx =    [bp+08] (2)
; dy =    [bp+10] (2)
; shape = [bp+12] (4)
;
public GetShape
PROC GetShape

  push  bp
  mov   bp,sp
  add   bp,2
  push  ds
  mov   ax,[bp+14]
  mov   es,ax           ;es = seg (shape)
  mov   ax,0A000h
  mov   ds,ax           ;ds = video segment
  mov   ax,[bp+12]
  mov   di,ax           ;di = ofs (shape)
  mov   bx,320
  mov   ax,[bp+06]
  mul   bx
  mov   si,[bp+04]
  add   si,ax           ;si = 320*y+x
  mov   ax,[bp+08]
  sub   bx,ax           ;bx = 320-D(x)
  mov   dx,[bp+10]      ;dx = D(y)
  shr   ax,2            ;ax = D(x)/4
GetShapeLoop:
  mov   cx,ax           ;cx = D(x)/4
  rep   movsd
  add   si,bx
  dec   dx
  jnz   GetShapeLoop
  pop   ds
  pop   bp
  ret

ENDP


END