#include <cstdio>
#include <iostream>
#include <bitset>
#include <cstring>
#include <list>
#include <cmath>
#include <vector>
#include <map>
#include <set>
#include <queue>
#include <algorithm>
#include <numeric>
#include <functional>
#include <iterator>
#include <sstream>
#include <stack>
#include <ext/numeric>
#include <tr1/unordered_map>
#include <tr1/unordered_set>
#include <tr1/tuple>


using namespace std;
using namespace std::tr1;
using namespace __gnu_cxx;

typedef pair<int,int> pii;
typedef long long int llint;
typedef unsigned int uint;

#define hash_map unordered_map
#define hash_set unordered_set

struct custom {
  int big;
  unordered_multiset<int> pres;
  custom() : big(0) {}

  void push(int x) {
    pres.insert(x);
    if (x == big) {
      do {
        big += 1;
      } while (pres.find(big) != pres.end());
    }
  }
  int pop(int x) {
    unordered_multiset<int>::iterator it, it2;
    it = pres.find(x);
    it2 = it; ++it2;
    pres.erase(it, it2);
    if (x < big && pres.find(x) == pres.end()) {
      big = x;
    }
  }
};

int main() {
  int tot;
  scanf("%d", &tot);
  for (int t = 1; t <= tot; t++) {
    int n, k;
    scanf("%d %d", &n, &k);
    int a, b, c, r;
    scanf("%d %d %d %d", &a, &b, &c, &r);
    custom m;
    m.push(a);
    int last = a;
    vector<int> elem(k);
    elem[0] = a;
    for (int i = 1; i < k; i++) {
      last = (llint(last) * b + c) % r;
      m.push(last);
      elem[i] = last;
    }
    int p = 0;
    int i = k;
    for (i = k; i < n - 1 && i < 2 * k; i++) {
      int next = m.big;
      m.pop(elem[p]);
      elem[p] = next;
      m.push(next);
      p = (p + 1) % k;
    }
    int x = (n-1-i) % (k+1);
    if (x == 0) {
      printf("Case #%d: %d\n", t, m.big);
    } else {
      printf("Case #%d: %d\n", t, elem[x-1]);
    }
  }
  return 0;
}
