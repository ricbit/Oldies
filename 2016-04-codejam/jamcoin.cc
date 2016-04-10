#include <iostream>
#include <string>
#include <cstdlib>
#include <vector>
#include <ctime>

using namespace std;

__int128 convert(const vector<int>& coin, int base) {
  __int128 ans = 0;
  for (int c : coin) {
    ans = ans * base + c;
  }
  return ans;
}

string dump(const vector<int>& coin) {
  string out = "";
  for (int c : coin) {
    out += char(c + 48);
  }
  return out;
}

int find_small_div(__int128 x) {
  for (int i = 2; i < 10; i++) {
    if (x % i == 0) {
      return i;
    }
  }
  return 0;
}

pair<string, vector<int>> jamcoin(int j) {
  vector<int> coin(j, 1);
  for (int i = 1; i < j - 1; i++) {
    coin[i] = rand() < RAND_MAX / 2;
  }
  vector<int> divs(11);
  for (int i = 2; i <= 10; i++) {
    int d = find_small_div(convert(coin, i));
    if (!d) {
      return jamcoin(j);
    }
    divs[i] = d;
  }
  return make_pair(dump(coin), divs);
}

int main() {
  srand(time(NULL));
  int t,size,samples;
  cin >> t >> size >> samples;
  cout << "Case #1:\n";
  for (int i = 0; i < samples; i++) {
    auto ans = jamcoin(size);
    cout << ans.first;
    for (int i = 2; i <= 10; i++) {
      cout << " " << ans.second[i];
    }
    cout << "\n";
  }
  return 0;
}
