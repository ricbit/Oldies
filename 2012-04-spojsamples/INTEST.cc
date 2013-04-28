#include "lazy.h"
#include "spojlib/io.h"

int main() {
  fastio io;
  uint n = io;
  uint k = io;
  uint sum = 0;
  while (n--) {
    uint x = io;
    if (x % k == 0)
      sum++;
  }
  io << sum << "\n";
}
