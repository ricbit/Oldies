
        .386C
        IDEAL
        MODEL LARGE,C

        CODESEG

; void AddVector (vector far *a, vector far *b, vector far *c);
; a = [bp+06] (4)
; b = [bp+10] (4)
; c = [bp+14] (4)
public AddVector
PROC AddVector

  push  bp
  mov   bp,sp
  les   ax,[bp+06]
  and   eax,0FFFFh
  lfs   bx,[bp+10]
  and   ebx,0FFFFh
  lgs   cx,[bp+14]
  and   ecx,0FFFFh
  mov   edx,[es:eax]
  add   edx,[fs:ebx]
  mov   [gs:ecx],edx
  mov   edx,[es:eax+4]
  add   edx,[fs:ebx+4]
  mov   [gs:ecx+4],edx
  mov   edx,[es:eax+8]
  add   edx,[fs:ebx+8]
  mov   [gs:ecx+8],edx
  pop   bp
  ret

ENDP

; void SubVector (vector far *a, vector far *b, vector far *c);
; a = [bp+06] (4)
; b = [bp+10] (4)
; c = [bp+14] (4)
public SubVector
PROC SubVector

  push  bp
  mov   bp,sp
  les   ax,[bp+06]
  and   eax,0FFFFh
  lfs   bx,[bp+10]
  and   ebx,0FFFFh
  lgs   cx,[bp+14]
  and   ecx,0FFFFh
  mov   edx,[es:eax]
  sub   edx,[fs:ebx]
  mov   [gs:ecx],edx
  mov   edx,[es:eax+4]
  sub   edx,[fs:ebx+4]
  mov   [gs:ecx+4],edx
  mov   edx,[es:eax+8]
  sub   edx,[fs:ebx+8]
  mov   [gs:ecx+8],edx
  pop   bp
  ret

ENDP

; void ScalarProduct (vector far *a, fixed n, vector far *v);
; a = [bp+06] (4)
; n = [bp+10] (4)
; v = [bp+14] (4)
public ScalarProduct
PROC ScalarProduct

  push  bp
  mov   bp,sp
  lgs   bx,[bp+06]
  and   ebx,0FFFFh
  lfs   cx,[bp+14]
  and   ecx,0FFFFh
  mov   eax,[gs:ebx]
  imul  [dword bp+10]
  shrd  eax,edx,16
  mov   [fs:ecx],eax
  mov   eax,[gs:ebx+4]
  imul  [dword bp+10]
  shrd  eax,edx,16
  mov   [fs:ecx+4],eax
  mov   eax,[gs:ebx+8]
  imul  [dword bp+10]
  shrd  eax,edx,16
  mov   [fs:ecx+8],eax
  pop   bp
  ret

ENDP

; void DotProduct (vector far *a, vector far *b, fixed far *n);
; a = [bp+06] (4)
; b = [bp+10] (4)
; n = [bp+14] (4)
public DotProduct
PROC DotProduct

  push  bp
  mov   bp,sp
  lgs   cx,[bp+06]
  and   ecx,0FFFFh
  lfs   bx,[bp+10]
  and   ebx,0FFFFh
  les   si,[bp+14]
  and   esi,0FFFFh
  mov   eax,[gs:ecx]
  imul  [dword fs:ebx]
  shrd  eax,edx,16
  mov   edi,eax
  mov   eax,[gs:ecx+4]
  imul  [dword fs:ebx+4]
  shrd  eax,edx,16
  add   edi,eax
  mov   eax,[gs:ecx+8]
  imul  [dword fs:ebx+8]
  shrd  eax,edx,16
  add   edi,eax
  mov   [es:esi],edi
  pop   bp
  ret

ENDP

; void CrossProduct (vector far *a, vector far *b, vector far *v);
; a = [bp+06] (4)
; b = [bp+10] (4)
; c = [bp+14] (4)
public CrossProduct
PROC CrossProduct

  push  bp
  mov   bp,sp
  les   bx,[bp+06]
  and   ebx,0FFFFh
  lfs   cx,[bp+10]
  and   ecx,0FFFFh
  lgs   di,[bp+14]
  and   edi,0FFFFh
  mov   eax,[es:ebx+4]
  imul  [dword fs:ecx+8]
  shrd  eax,edx,16
  mov   esi,eax
  mov   eax,[es:ebx+8]
  imul  [dword fs:ecx+4]
  shrd  eax,edx,16
  sub   esi,eax
  mov   [gs:edi],esi
  mov   eax,[es:ebx+8]
  imul  [dword fs:ecx]
  shrd  eax,edx,16
  mov   esi,eax
  mov   eax,[es:ebx]
  imul  [dword fs:ecx+8]
  shrd  eax,edx,16
  sub   esi,eax
  mov   [gs:edi+4],esi
  mov   eax,[es:ebx]
  imul  [dword fs:ecx+4]
  shrd  eax,edx,16
  mov   esi,eax
  mov   eax,[es:ebx+4]
  imul  [dword fs:ecx]
  shrd  eax,edx,16
  sub   esi,eax
  mov   [gs:edi+8],esi
  pop   bp
  ret

ENDP

; void FSetViewer (obs far *o);
; o    = [bp+06] (4)
; o.F  = [00] (12)
; o.T  = [12] (12)
; o.Up = [24] (12)
; o.Q  = [36] (12)
; o.Ud = [48] (12)
; o.Vd = [60] (12)
public FSetViewer
PROC FSetViewer

  push  bp
  mov   bp,sp
  push  ds
  lds   bx,[bp+06]
  and   ebx,0FFFFh
  mov   eax,[ebx]            ; Q=F+T
  add   eax,[ebx+12]
  mov   [ebx+36],eax
  mov   eax,[ebx+4]
  add   eax,[ebx+12+4]
  mov   [ebx+36+4],eax
  mov   eax,[ebx+8]
  add   eax,[ebx+12+8]
  mov   [ebx+36+8],eax
  mov   esi,199
  mov   eax,[ebx+24]
  imul  esi
  mov   [ebx+60],eax
  mov   eax,[ebx+24+4]
  imul  esi
  mov   [ebx+60+4],eax
  mov   eax,[ebx+24+8]
  imul  esi
  mov   [ebx+60+8],eax
  mov   esi,319                 ; Ud=319*(T^Up)
  mov   eax,[ebx+12+8]
  imul  [dword ebx+24+4]
  shrd  eax,edx,16
  mov   edi,eax
  mov   eax,[ebx+12+4]
  imul  [dword ebx+24+8]
  shrd  eax,edx,16
  sub   eax,edi
  imul  esi
  mov   [ebx+48],eax
  mov   eax,[ebx+12]
  imul  [dword ebx+24+8]
  shrd  eax,edx,16
  mov   edi,eax
  mov   eax,[ebx+12+8]
  imul  [dword ebx+24]
  shrd  eax,edx,16
  sub   eax,edi
  imul  esi
  mov   [ebx+48+4],eax
  mov   eax,[ebx+12+4]
  imul  [dword ebx+24]
  shrd  eax,edx,16
  mov   edi,eax
  mov   eax,[ebx+12]
  imul  [dword ebx+24+4]
  shrd  eax,edx,16
  sub   eax,edi
  imul  esi
  mov   [ebx+48+8],eax
  pop   ds
  pop   bp
  ret

ENDP

; void FInvert (fixed far *n)
; n = [bp+06]
public FInvert
PROC FInvert

  push  bp
  mov   bp,sp
  mov   eax,0
  mov   edx,1
  les   cx,[bp+06]
  and   ecx,0FFFFh
  idiv  [dword es:ecx]
  mov   [es:ecx],eax
  pop   bp
  ret

ENDP

; void FProject (obs far *o, vector far *W, pixel far *p);
; o       = [bp+06] (4)
; W       = [bp+10] (4)
; p       = [bp+14] (4)
; o.F     = [00] (12)
; o.T     = [12] (12)
; o.Up    = [24] (12)
; o.Q     = [36] (12)
; o.Ud    = [48] (12)
; o.Vd    = [60] (12)
; o.R     = [72] (12)
; o.P     = [84] (12)
; p.x     = [00] (2)
; p.y     = [02] (2)
; p.dist  = [04] (4)
; p.Valid = [08] (1)
public FProject
PROC FProject

  push  bp
  mov   bp,sp
  push  ds
  lds   bx,[bp+06]
  and   ebx,0FFFFh
  les   cx,[bp+10]
  and   ecx,0FFFFh
  lfs   si,[bp+14]
  and   esi,0FFFFh
  mov   eax,[es:ecx]            ; R=W-F
  sub   eax,[ebx]
  mov   [ebx+72],eax
  mov   [dword ebx+72+4],0FFFF0000h     ; ToFixed (-1.0)
  mov   eax,[es:ecx+8]
  sub   eax,[ebx+8]
  mov   [ebx+72+8],eax
  imul  [dword ebx+12+8]     ; (c)=R*T
  shrd  eax,edx,16
  mov   edi,eax
  mov   eax,[ebx+72]
  imul  [dword ebx+12]
  shrd  eax,edx,16
  add   edi,eax
  mov   [fs:esi+4],edi
  cmp   edi,80000              ;epsilon
  jg    FProjectValid
  mov   [byte fs:esi+8],0
  pop   ds
  pop   bp
  ret
FProjectValid:
  mov   edx,1                   ; (t)=1/(c)
  mov   eax,0
  idiv  edi
  mov   edi,eax                 ; P=R*(t)-T
  mov   eax,[ebx+72]
  imul  edi
  shrd  eax,edx,16
  sub   eax,[ebx+12]
  mov   [ebx+84],eax
  mov   eax,edi
  neg   eax
  mov   [ebx+84+4],eax
  mov   eax,[ebx+72+8]
  imul  edi
  shrd  eax,edx,16
  sub   eax,[ebx+12+8]
  mov   [ebx+84+8],eax
  imul  [dword ebx+48+8]        ; (P.x = P * Ud)
  shrd  eax,edx,16
  mov   edi,eax
  mov   eax,[ebx+84]
  imul  [dword ebx+48]
  shrd  eax,edx,16
  add   edi,eax
  add   edi,160*65536+32768
  shr   edi,16
  mov   [fs:esi],di
  mov   edi,100*65536-32768     ; (P.y = P * Vd)
  mov   eax,[ebx+84+4]
  imul  [dword ebx+60+4]
  shrd  eax,edx,16
  sub   edi,eax
  shr   edi,16
  mov   [fs:esi+2],di
  mov   [byte fs:esi+8],1
  pop   ds
  pop   bp
  ret

ENDP

; void DiffTime (struct time *tf, struct time *ti, long int *t);
; tf = [bp+06] (4)
; ti = [bp+10] (4)
; t  = [bp+14] (4)
; tf.ti_min  = [00] (1)
; tf.ti_hour = [01] (1)
; tf.ti_hund = [02] (1)
; tf.ti_sec =  [03] (1)
public DiffTime
PROC DiffTime

  push  bp
  mov   bp,sp
  les   bx,[bp+06]
  and   ebx,0FFFFh
  lfs   cx,[bp+10]
  and   ecx,0FFFFh
  lgs   si,[bp+14]
  and   esi,0FFFFh
  mov   al,[es:ebx+1]
  sub   al,[fs:ecx+1]
  movsx eax,al
  mov   esi,60*60*100
  imul  esi
  mov   edx,eax
  mov   al,[es:ebx]
  sub   al,[fs:ecx]
  movsx eax,al
  mov   esi,60*100
  imul  esi
  add   edx,eax
  mov   al,[es:ebx+3]
  sub   al,[fs:ecx+3]
  movsx eax,al
  mov   esi,100
  imul  esi
  add   edx,eax
  mov   al,[es:ebx+2]
  sub   al,[fs:ecx+2]
  movsx eax,al
  add   edx,eax
  mov   [gs:esi],edx
  pop   bp
  ret

ENDP

; extern void CalcPlane (plane far *p, vector far *v, fixed far *n);
; p = [bp+06] (4)
; v = [bp+10] (4)
; n = [bp+14] (4)
public CalcPlane
PROC CalcPlane

  push  bp
  mov   bp,sp
  push  ds
  mov   ebx,0
  lds   bx,[bp+06]
  mov   ecx,0
  lfs   cx,[bp+10]
  mov   edi,0
  lgs   di,[bp+14]
  mov   eax,[ebx]
  imul  [dword fs:ecx]
  shrd  eax,edx,16
  mov   esi,eax
  mov   eax,[ebx+8]
  imul  [dword fs:ecx+8]
  shrd  eax,edx,16
  add   esi,eax
  add   esi,[ebx+12]
  mov   [gs:edi],esi
  pop   ds
  pop   bp
  ret

ENDP CalcPlane

; extern void DepthInit (fixed d1, fixed d2, int dx, fixed far *dinc);
; d1   = [bp+06] (4)
; d2   = [bp+10] (4)
; dx   = [bp+14] (2)
; dinc = [bp+16] (4)
;
public DepthInit
PROC DepthInit

  push  bp
  mov   bp,sp
  mov   eax,[bp+10]
  sub   eax,[bp+06]
  cdq
  movzx ecx,[word bp+14]
  idiv  ecx
  mov   ebx,0
  les   bx,[bp+16]
  mov   [es:ebx],eax
  pop   bp
  ret

ENDP

; extern void DepthInc (fixed dinc, fixed far *da, unsigned char *dac);
; dinc = [bp+06] (4)
; da   = [bp+10] (4)
; dac  = [bp+14] (4)
;
public DepthInc
PROC DepthInc

  push  bp
  mov   bp,sp
  mov   ebx,0
  les   bx,[bp+10]
  mov   eax,[bp+06]
  add   [es:ebx],eax
  mov   edx,[es:ebx]
  shr   edx,16
  les   bx,[bp+14]
  mov   [es:ebx],dl
  pop   bp
  ret

ENDP DepthInc

END