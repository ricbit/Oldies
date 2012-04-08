#include "spojlib/lazy.h"
#include "spojlib/io.h"

uint reverse(uint x) {
  uint ans = 0;
  while (x) {
    ans = ans * 10 + x % 10;
    x /= 10;
  }
  return ans;
}

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    uint x = io;
    int n = 0;
    while (x != reverse(x)) {
      n++;
      x += reverse(x);
    }
    io << n << " " << x << "\n";
  }
  return 0;
}
