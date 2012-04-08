#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    int n = io;
    const double PI = 3.1415926535;
    double ans = 4.5 * pow(192.0 * n / PI / 516.0, 1.0 / 3.0);
    io << static_cast<int>(floor(ans)) << "\n";
  }
  return 0;
}
