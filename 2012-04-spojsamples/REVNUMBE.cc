#include "spojlib/lazy.h"
#include "spojlib/io.h"

llint reverse(llint n) {
  llint ans = 0;
  while (n) {
    ans = ans * 10 + n % 10;
    n /= 10;
  }
  return ans;
}

int main(void) {
  fastio io;
  int tot = io;
  for (int i = 0; i < tot; i++) {
    llint a = io;
    llint b = io;
    io << "Case " << i + 1 << "#: " << reverse(reverse(a) + reverse(b)) << "\n";
  }
  return 0;
}
