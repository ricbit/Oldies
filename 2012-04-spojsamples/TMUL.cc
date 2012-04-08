#include "spojlib/lazy.h"
#include "spojlib/io.h"
#include "spojlib/bigint.h"

int main(void) {
  _fastio<32768, 20020> io;
  int tot = io;
  while (tot--) {
    string a = io.word();
    string b = io.word();
    string ans = bigint(a) * bigint(b);
    io << ans << "\n";
  }
  return 0;
}
