#include <cstdio>
#include <vector>

using namespace std;

int main() {
  int tot;
  scanf("%d", &tot);
  for (int t = 1; t <= tot; t++) {
    int e,r,n;
    scanf("%d",&e);
    scanf("%d",&r);
    scanf("%d",&n);
    vector<int> v(n);
    for (int i = 0; i < n; i++) {
      scanf("%d", &v[i]);
    }
    
    vector<vector<int> > memo(n, vector<int>(e + 1, 0));
    for (int i = 0; i <= e; i++) {
      int val = i * v[0];
      int idx = min(e, e - i + r);
      memo[0][idx] = max(val, memo[0][idx]);
    }
    for (int j = 1; j < n; j++) {
      for (int i = 0; i <= e; i++) {
        for (int k = 0; k <= i; k++) {
          int val = k * v[j] + memo[j - 1][i];
          int idx = min(e, i - k + r);
          memo[j][idx] = max(val, memo[j][idx]);
        }
      }
    }
    int m = memo[n - 1][r];
    for (int i = r + 1; i <= e; i++) {
      m = max(m, memo[n - 1][i]);
    }
    printf("Case #%d: %d\n", t, m);
  }
}
