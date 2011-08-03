// Optimum addition chain
// Ricardo Bittencourt 2008

#include <cstdio>
#include <vector>
#include <limits>
#include <bitset>

using namespace std;

int natural(int n) {
  return n > 1? n - 1 : 0;
}

int binary(int n) {
  if (n < 2) return 0;

  int half = binary(n / 2);
  if (n & 1)
    return 2 + half;
  else
    return 1 + half;
}

struct optimum_power {
  int n;
  int max_len;
  vector<int> best, cur;
  optimum_power(int _n): n(_n), max_len(binary(n)), best(max_len + 1, 0) {
    cur.reserve(max_len + 3);
    cur.push_back(1);
  }
  void search() {
    int last = cur.back();
    if (last > n || cur.size() > max_len+1 || cur.size() > best.size())
      return;
    if (last == n) {
      if (best.size() >= cur.size())
        best = cur;
      return;
    }
    vector<bool> used(n+1, false);
    for (int i = 0; i < cur.size(); ++i)
      for (int j = 0; j < cur.size(); ++j) {
        int x = cur[i] + cur[j];
        if (x > last && x <=n && !used[x]) {
          used[x] = true;
          cur.push_back(x);
          search();
          cur.pop_back();
        }
      }
  }
};

int main(void) {
  for (int i = 1; i <= 256; ++i) {
    optimum_power opt(i);
    opt.search();
    printf ("%d: %d %d %d\n", i, natural(i), binary(i), opt.best.size()-1);
    fflush(stdout);
  }
  return 0;
}
