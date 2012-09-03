#include "spojlib/lazy.h"
#include "spojlib/io.h"
#include "spojlib/fibonacci.h"

int main(void) {
  fastio io;
  fibonacci<llint> fib(91);
  int tot = io;
  while (tot--) {
    int n = io;
    io << fib.nth(n + 1) - 1 << "\n";
  }
  return 0;
}
