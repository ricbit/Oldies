#include "spojlib/lazy.h"
#include "spojlib/io.h"

int square(llint n) {
  if (n < 2) {
    return 0;
  }
  if (n & 1) {
    return 2 + square(n / 2);
  } else {
    return 1 + square(n / 2);
  }
}

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    io << square(io) << "\n";
  }
  return 0;
}
