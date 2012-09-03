#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  vector<int> v(3);
  for (int i = 0; i < 3; i++) {
    v[i] = io;
  }
  sort(v.begin(), v.end());
  io << v[1] * v[2] << "\n";
  return 0;
}
