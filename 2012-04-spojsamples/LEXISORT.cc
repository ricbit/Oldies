#include "spojlib/lazy.h"
#include "spojlib/io.h"

int main(void) {
  fastio io;
  int tot = io;
  while (tot--) {
    int n = io;
    vector<string> words(n);
    for (int i = 0; i < n; i++) {
      words[i] = io.word();
    }
    sort(words.begin(), words.end());
    for (int i = 0; i < n; i++) {
      io << words[i] << "\n";
    }    
  }
  return 0;
}
