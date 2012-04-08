#include "spojlib/lazy.h"
#include "spojlib/io.h"

vector<int> getvector(fastio& io) {
  int size = io;
  vector<int> a(size);
  for (int i = 0; i < size; i++) {
    a[i] = io;
  }
  sort(a.begin(), a.end(), greater<int>());
  return a;
}

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    vector<int> a = getvector(io);
    vector<int> b = getvector(io);
    if (a > b) {
      io << "Bajtocja\n";
    } else if (a < b) {
      io << "Megabajtolandia\n";
    } else {
      io << "Draw\n";
    }
  }
  return 0;
}
