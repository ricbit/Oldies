// Monte carlo simulation for the expected value of a trial-and-error
// random prime number algorithm.

// Ricardo Bittencourt 2008

#include <cstdio>
#include <vector>
#include <ext/numeric>

using namespace std;
using namespace __gnu_cxx;

const int max_prime = 10000000;

vector<bool> sieve(int total) {
  vector<bool> p(total, true);
  p[0] = p[1] = false;
  for (int i = 2; i*i <= total; i++)
    if (p[i])
      for (int j = i*i; j < total; j += i)
        p[j] = false;
  return p;
}

int random_prime(const vector<bool>& prime) {
  static subtractive_rng random;
  int p = random(max_prime);
  int queries = 1;
  while (!prime[p]) {
    p = random(max_prime);
    queries++;
  }
  return queries;
}

int main(void) {
  vector<bool> prime = sieve(max_prime);
  int count = 0;
  for (int i = 0; i < 10000; i++)
    count += random_prime(prime);
  printf ("%lf\n", static_cast<double>(count) / 10000.0);
  return 0;
}
