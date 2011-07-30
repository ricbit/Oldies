#include <iostream>

using namespace std;

constexpr int gcd(int a, int b) {
  return b == 0 ? a : gcd(b, a % b);
}

constexpr int totient(int x, int i) {
  return i == 0 ? 0 : (gcd(x, i) == 1) + totient(x, i - 1);
}

constexpr int totient(int x) {
  return totient(x, x - 1);
}

int main() {
  constexpr auto x = totient(NUMBER);
  cout << x << endl;
}
