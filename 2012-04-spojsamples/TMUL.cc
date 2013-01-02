#include "spojlib/lazy.h"
#include "spojlib/io.h"
#include "spojlib/bigint.h"

int main(void) {
  _fastio<30000, 10000> io;
  int n = io;
  while (n--) {
    string s1 = io.word();
    string s2 = io.word();
    io << static_cast<string>(bigint(s1) * bigint(s2)) << "\n";
  }
  return 0;
}
