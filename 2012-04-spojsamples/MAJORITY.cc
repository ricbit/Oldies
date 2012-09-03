#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  int n = io;
  vector<unsigned> v(n);
  for (int i = 0; i < n; i++) {
    v[i] = io;
  }
  sort(v.begin(), v.end());
  io << v[n / 2] << "\n";
  return 0;
}
