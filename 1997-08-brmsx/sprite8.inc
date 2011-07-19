MAKE_SPRITE_COLOR macro r,g,b 

        db      (g shl 5) + (r shl 2) + (b/2)
        db      (g shl 5) + (r shl 2) + (b/2)
        db      (g shl 5) + (r shl 2) + (b/2)
        db      (g shl 5) + (r shl 2) + (b/2)

        endm

screen8_sprite_color:

 MAKE_SPRITE_COLOR      0,       0,       0
 MAKE_SPRITE_COLOR      0,       0,       2
 MAKE_SPRITE_COLOR      3,       0,       0
 MAKE_SPRITE_COLOR      3,       0,       2
 MAKE_SPRITE_COLOR      0,       3,       0
 MAKE_SPRITE_COLOR      0,       3,       2
 MAKE_SPRITE_COLOR      3,       3,       0
 MAKE_SPRITE_COLOR      3,       3,       2
 MAKE_SPRITE_COLOR      7,       4,       2
 MAKE_SPRITE_COLOR      0,       0,       7
 MAKE_SPRITE_COLOR      7,       0,       0
 MAKE_SPRITE_COLOR      7,       0,       7
 MAKE_SPRITE_COLOR      0,       7,       0
 MAKE_SPRITE_COLOR      0,       7,       7
 MAKE_SPRITE_COLOR      7,       7,       0
 MAKE_SPRITE_COLOR      7,       7,       7
