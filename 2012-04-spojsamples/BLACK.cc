#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  while (true) {
    int n = io;
    int m = io;
    int c = io;
    if (n + m + c == 0) break;
    int ans = 0;
    for (int i = 0; i <= n - 8; i++) {
      if (c) {
        ans += max((m - 6) / 2, 0);
      } else {
        ans += max((m - 7) / 2, 0);
      }
      c = 1 - c;
    }
    io << ans << "\n";
  }
  return 0;
}
