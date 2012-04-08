#include "spojlib/lazy.h"
#include "spojlib/io.h"
#include "spojlib/primes.h"

int main(void) {
  fastio io;
  int tot = io;
  const vector<int> primes = getprimes(45000);
  while (tot--) {
    int n = io;
    llint ans = sum_of_divisors<llint>(n, primes);
    io << ans << "\n";
  }
  return 0;
}
