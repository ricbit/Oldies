#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    int n = io;
    int c = io;
    vector<int> x(n);
    for (int i = 0; i < n; i++) {
      x[i] = io;
    }
    sort(x.begin(), x.end());
    int a = 0, b = x[n - 1] + 1;
    while (b - a > 1) {
      int m = (a + b) / 2;
      int last = 0, bins = 1;
      for (int i = 1; i < n; i++) {
        if (x[i] - x[last] >= m) {
          last = i;
          bins++;
        }
      }
      if (bins >= c) {
        a = m;
      } else {
        b = m;
      }
    }
    io << a << "\n";
  }
  return 0;
}
