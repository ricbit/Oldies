#include "fixed.h"

fixed tofixed (float x) {
  return ((fixed) x*65536.0);
}

float tofloat (fixed x) {
  return (((float) x)/65536.0);
}

