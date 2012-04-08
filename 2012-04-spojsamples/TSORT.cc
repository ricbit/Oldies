#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main() {
  fastio io;
  int n = io;
  const int M = 1000001;
  vector<int> hist(M);
  for (int i = 0; i < n; i++) {
    unsigned x = io;
    hist[x]++;
  }
  for (int i = 0; i < M; i++) {
    for (int j = 0; j < hist[i]; j++) {
      io << i << "\n";
    }
  }
  return 0;
}
