#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    int n = io;
    int a = 0, b = 0;
    double x = 0;
    while (n--) {
      int aa = io;
      int bb = io;
      double xx = bb * log(aa);
      if (xx > x) {
        a = aa;
        b = bb;
        x = xx;
      }
    }
    io << a << " " << b << "\n";
  }
  return 0;
}
