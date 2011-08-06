; Mandelbrot Fractal under 512 bytes
; author: Ricardo Bittencourt
; thanks to Girino Vey for his help

; compile with Jasmin: http://jasmin.sourceforge.net/

.class  public synchronized F
.super  java/applet/Applet

; --------------------------------------------------
.method public <init>()V
    .limit stack 33  ; chosen to increse redundancy  
    .limit locals 33 ; for zip compression
    aload_0
    invokenonvirtual java/applet/Applet/<init>()V
    return
.end method

; --------------------------------------------------
.method public paint(Ljava/awt/Graphics;)V
    .limit stack 33
    .limit locals 33

    ; local 2 = j*256+i    
    iconst_0 
    istore_2 
outer_loop:    
    
    ; local 3 = c
    ; c=-1;    
    iconst_m1
    istore_3
    
    ; local 7 = x
    ; local 8 = y
    ; local 9 = x2
    ; local 6 = y2
    ; local 0 = k
    ; x=y=x2=y2=k=0;
    
    fconst_0
    dup
    dup2
    dup
    fstore 7 ;x
    fstore 8 ;y
    fstore 9 ;x2
    fstore 10 ;y2
    fstore_0 ;k

inner_loop:    
    ; y=x*y*2+(j+(-128))/100f;
    
    iload_2
    bipush 8
    ishr
    bipush -128
    iadd
    i2f
    ldc 100.0
    fdiv
    
    fload 7 ;x
    fload 8 ;y
    fmul
    fconst_2
    fmul
    fadd
    fstore 8 ;y
        
    ; x=x2-y2+i/100f-2;
    
    fload 9 ;x2
    fload 10 ;y2
    fsub
    iload_2 ; i
    ldc 255
    iand
    i2f
    ldc 100.0
    fdiv
    fadd
    fconst_2
    fsub
    dup
    fstore 7 ; x
    
    ; x2=x*x; 
        
    dup
    fmul
    dup
    fstore 9 ;x2    
    
    ; y2=y*y
    
    fload 8 ; y
    dup
    fmul
    dup
    fstore 10 ; y2
    
    ; if x2+y2>4
    fadd
    fconst_2
    fdiv
    fconst_2
    fcmpl
    ifge set_color
    
    ; k+=0.03
    fload_0 ;k
    ldc 0.03
    fadd
    dup
    fstore_0
    
    ; if k>1
    fconst_1
    fcmpg
    ifge draw_now
    goto inner_loop

set_color:    
    
    fload_0 ; k
    f2d
    ldc 0.7
    f2d
    invokestatic java/lang/Math/pow(DD)D
    ldc 255
    i2d
    dmul
    d2i
    bipush 8
    ishl
    istore_3 ; c
    
draw_now:
    aload_1
    new java/awt/Color
    dup
    iload_3
    invokenonvirtual java/awt/Color/<init>(I)V
    invokevirtual java/awt/Graphics/setColor(Ljava/awt/Color;)V
    
    ; g.drawrect (i,j,1,1);
    aload_1 
    iload_2 
    ldc 255
    iand
    iload_2
    bipush 8
    ishr
    iconst_1  
    iconst_1 
    invokevirtual java/awt/Graphics/drawRect(IIII)V 

    iinc 2 1
    iload_2 
    iconst_2
    bipush 16 
    ishl      
    if_icmple outer_loop 
    
    return
.end method

