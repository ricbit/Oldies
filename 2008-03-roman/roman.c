/* Roman numerals in O(1) using preprocessor metaprogramming */
/* Ricardo Bittencourt 2008 */

#ifndef FIRST
  #define FIRST
  #define LEVEL0
char *roman[]={
#endif

#ifdef LAST
};

#include <stdio.h>

int main(void) {
  int n;
  scanf("%d", &n);
  puts(roman[n]);
  return 0;
}
#endif

#ifdef LEVEL0
  #undef LEVEL0
  #define LEVEL1
  #include "roman.c"
  #define M1
  #define LEVEL1
  #include "roman.c"
  #undef M1
  #define LAST
  #include "roman.c"
#endif

#ifdef LEVEL1
  #undef LEVEL1
  #define LEVEL2
  #include "roman.c"
  #define M0
  #define LEVEL2
  #include "roman.c"
  #undef M0
#endif

#ifdef LEVEL2
  #undef LEVEL2
  #define LEVEL3
  #include "roman.c"
  #define C3
  #define LEVEL3
  #include "roman.c"
  #undef C3
#endif

#ifdef LEVEL3
  #undef LEVEL3
  #define LEVEL4
  #include "roman.c"
  #define C2
  #define LEVEL4
  #include "roman.c"
  #undef C2
#endif

#ifdef LEVEL4
  #undef LEVEL4
  #define LEVEL5
  #include "roman.c"
  #define C1
  #define LEVEL5
  #include "roman.c"
  #undef C1
#endif

#ifdef LEVEL5
  #undef LEVEL5
  #define LEVEL6
  #include "roman.c"
  #define C0
  #define LEVEL6
  #include "roman.c"
  #undef C0
#endif

#ifdef LEVEL6
  #undef LEVEL6
  #define LEVEL7
  #include "roman.c"
  #define X3
  #define LEVEL7
  #include "roman.c"
  #undef X3
#endif

#ifdef LEVEL7
  #undef LEVEL7
  #define LEVEL8
  #include "roman.c"
  #define X2
  #define LEVEL8
  #include "roman.c"
  #undef X2
#endif

#ifdef LEVEL8
  #undef LEVEL8
  #define LEVEL9
  #include "roman.c"
  #define X1
  #define LEVEL9
  #include "roman.c"
  #undef X1
#endif

#ifdef LEVEL9
  #undef LEVEL9
  #define LEVEL10
  #include "roman.c"
  #define X0
  #define LEVEL10
  #include "roman.c"
  #undef X0
#endif

#ifdef LEVEL10
  #undef LEVEL10
  #define LEVEL11
  #include "roman.c"
  #define I3
  #define LEVEL11
  #include "roman.c"
  #undef I3
#endif

#ifdef LEVEL11
  #undef LEVEL11
  #define LEVEL12
  #include "roman.c"
  #define I2
  #define LEVEL12
  #include "roman.c"
  #undef I2
#endif

#ifdef LEVEL12
  #undef LEVEL12
  #define LEVEL13
  #include "roman.c"
  #define I1
  #define LEVEL13
  #include "roman.c"
  #undef I1
#endif

#ifdef LEVEL13
  #undef LEVEL13
  #define LEVEL14
  #include "roman.c"
  #define I0
  #define LEVEL14
  #include "roman.c"
  #undef I0
#endif

#ifdef LEVEL14
      #ifdef M1
        #ifdef M0
          #define SM "MMM"
        #else
          #define SM "MM"
        #endif
      #else
        #ifdef M0
          #define SM "M"
        #else
          #define SM ""
        #endif
      #endif
  #ifdef C3
    #ifdef C2
      #ifdef C1
        #ifdef C0
          #define INVALID
        #else
          #define INVALID
        #endif
      #else
        #ifdef C0
          #define INVALID
        #else
          #define INVALID
        #endif
      #endif
    #else
      #ifdef C1
        #ifdef C0
          #define INVALID
        #else
          #define INVALID
        #endif
      #else
        #ifdef C0
          #define SC "CM"
        #else
          #define SC "DCCC"
        #endif
      #endif
    #endif
  #else
    #ifdef C2
      #ifdef C1
        #ifdef C0
          #define SC "DCC"
        #else
          #define SC "DC"
        #endif
      #else
        #ifdef C0
          #define SC "D"
        #else
          #define SC "CD"
        #endif
      #endif
    #else
      #ifdef C1
        #ifdef C0
          #define SC "CCC"
        #else
          #define SC "CC"
        #endif
      #else
        #ifdef C0
          #define SC "C"
        #else
          #define SC ""
        #endif
      #endif
    #endif
  #endif
  #ifdef X3
    #ifdef X2
      #ifdef X1
        #ifdef X0
          #define INVALID
        #else
          #define INVALID
        #endif
      #else
        #ifdef X0
          #define INVALID
        #else
          #define INVALID
        #endif
      #endif
    #else
      #ifdef X1
        #ifdef X0
          #define INVALID
        #else
          #define INVALID
        #endif
      #else
        #ifdef X0
          #define SX "XC"
        #else
          #define SX "LXXX"
        #endif
      #endif
    #endif
  #else
    #ifdef X2
      #ifdef X1
        #ifdef X0
          #define SX "LXX"
        #else
          #define SX "LX"
        #endif
      #else
        #ifdef X0
          #define SX "L"
        #else
          #define SX "XL"
        #endif
      #endif
    #else
      #ifdef X1
        #ifdef X0
          #define SX "XXX"
        #else
          #define SX "XX"
        #endif
      #else
        #ifdef X0
          #define SX "X"
        #else
          #define SX ""
        #endif
      #endif
    #endif
  #endif
  #ifdef I3
    #ifdef I2
      #ifdef I1
        #ifdef I0
          #define INVALID
        #else
          #define INVALID
        #endif
      #else
        #ifdef I0
          #define INVALID
        #else
          #define INVALID
        #endif
      #endif
    #else
      #ifdef I1
        #ifdef I0
          #define INVALID
        #else
          #define INVALID
        #endif
      #else
        #ifdef I0
          #define SI "IX"
        #else
          #define SI "VIII"
        #endif
      #endif
    #endif
  #else
    #ifdef I2
      #ifdef I1
        #ifdef I0
          #define SI "VII"
        #else
          #define SI "VI"
        #endif
      #else
        #ifdef I0
          #define SI "V"
        #else
          #define SI "IV"
        #endif
      #endif
    #else
      #ifdef I1
        #ifdef I0
          #define SI "III"
        #else
          #define SI "II"
        #endif
      #else
        #ifdef I0
          #define SI "I"
        #else
          #define SI ""
        #endif
      #endif
    #endif
  #endif
  #undef LEVEL14
  #ifndef INVALID
    SM SC SX SI,
  #else
    #undef INVALID
  #endif
#endif
#ifdef SM
  #undef SM
#endif
#ifdef SC
  #undef SC
#endif
#ifdef SX
  #undef SX
#endif
#ifdef SI
  #undef SI
#endif
