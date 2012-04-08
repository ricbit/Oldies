#include "spojlib/lazy.h"
#include "spojlib/io.h"
#include "spojlib/primes.h"

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    int a = io;
    int b = io;
    io << gcd(a,b) << "\n";
  }
  return 0;
}
