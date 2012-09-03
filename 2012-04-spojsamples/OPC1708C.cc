#include "spojlib/lazy.h"
#include "spojlib/io.h"
#include "spojlib/modint.h"

typedef modint<1000000007> mint;

int main(void) {
  fastio io;
  vector<mint> fac(1000001);
  fac[0] = 1;
  for (int i = 1; i <= 1000000; i++) {
    fac[i] = fac[i - 1] * mint(i);
  }
  int tot = io;
  while (tot--) {
    io << int(fac[io]) << "\n";
  }
  return 0;
}
