#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    int a = io;
    int b = io;
    int ans = 0;
    while (a && b) {
      if (a < b) {
        swap(a, b);
      }
      ans += a / b;
      a %= b;
    }
    io << ans << "\n";
  }
  return 0;
}
