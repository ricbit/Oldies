#include <iostream>

using namespace std;

template<int a, int b>
struct GCD {
  const static int result = GCD<b, a % b>::result;
};

template<int a>
struct GCD<a, 0> {
  const static int result = a;
};

template<int x, int i>
struct TotientHelper {
  const static int result =
      (GCD<x, i>::result == 1) +
      TotientHelper<x, i - 1>::result;
};

template<int x>
struct TotientHelper<x, 0> {
  const static int result = 0;
};

template<int x>
struct Totient {
  const static int result =
      TotientHelper<x, x - 1>::result;
};

int main() {
  const int x = Totient<NUMBER>::result;
  cout << x << endl;
}
