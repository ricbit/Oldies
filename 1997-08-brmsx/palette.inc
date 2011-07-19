palette:
        db      0,0,0
        db      0,0,0
        db      32/4,192/4,32/4
        db      96/4,224/4,96/4
        db      32/4,32/4,224/4
        db      64/4,96/4,224/4
        db      160/4,32/4,32/4
        db      64/4,192/4,224/4
        db      224/4,32/4,32/4
        db      224/4,96/4,96/4
        db      192/4,192/4,32/4
        db      192/4,192/4,128/4
        db      32/4,128/4,32/4
        db      192/4,64/4,160/4
        db      160/4,160/4,160/4
        db      224/4,224/4,224/4
        
HIGHCOLOR       macro r,g,b

                dw      ((r/8)*1024)+((g/8)*32)+(b/8)

                endm

sg1000_high_palette:
        HIGHCOLOR       0,0,0
        HIGHCOLOR       0,0,0
        HIGHCOLOR       32,192,32
        HIGHCOLOR       96,224,96
        HIGHCOLOR       32,32,224
        HIGHCOLOR       64,96,224
        HIGHCOLOR       160,32,32
        HIGHCOLOR       64,192,224
        HIGHCOLOR       224,32,32
        HIGHCOLOR       224,96,96
        HIGHCOLOR       192,192,32
        HIGHCOLOR       192,192,128
        HIGHCOLOR       32,128,32
        HIGHCOLOR       192,64,160
        HIGHCOLOR       160,160,160
        HIGHCOLOR       224,224,224
        
