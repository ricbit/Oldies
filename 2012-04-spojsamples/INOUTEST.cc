#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  unsigned n = io;
  while (n--) {
    int a = io;
    int b = io;
    io << a*b << "\n";
  }
  return 0;
}
