#include <algorithm>
#include <vector>
#include "gtest/gtest.h"
#include "primes.h"

using namespace std;

struct Accumulate {
  vector<int> acc;
  void operator()(int p, int n) {
    acc.push_back(p);
    acc.push_back(n);
  }
};

TEST(PrimesTest, GetPrimes) {
  int p11[] = {2, 3, 5, 7, 11};
  vector<int> primes11 = getprimes(11);
  EXPECT_TRUE(equal(primes11.begin(), primes11.end(), p11));

  int p16[] = {2, 3, 5, 7, 11, 13};
  vector<int> primes16 = getprimes(16);
  EXPECT_TRUE(equal(primes16.begin(), primes16.end(), p16));
}

TEST(PrimesTest, Factorize) {
  vector<int> primes = getprimes(100);
  Accumulate acc;

  int f1[] = {1, 1};
  factorize(1, primes, acc);
  EXPECT_TRUE(equal(acc.acc.begin(), acc.acc.end(), f1));
  acc.acc.clear();

  int f7[] = {7, 1};
  factorize(7, primes, acc);
  EXPECT_TRUE(equal(acc.acc.begin(), acc.acc.end(), f7));
  acc.acc.clear();

  int f12[] = {2, 2, 3, 1};
  factorize(12, primes, acc);
  EXPECT_TRUE(equal(acc.acc.begin(), acc.acc.end(), f12));
  acc.acc.clear();
  
  int f5040[] = {2, 4, 3, 2, 5, 1, 7, 1};
  factorize(5040, primes, acc);
  EXPECT_TRUE(equal(acc.acc.begin(), acc.acc.end(), f5040));
  acc.acc.clear();
}

TEST(PrimesTest, DivisorSum) {
  int tot[] = {1, 1, 2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12};
  vector<int> primes = getprimes(20);
  vector<int> ans;
  for (int i = 1; i <= 13; i++) {
    ans.push_back(totient<int>(i, primes));
  }
  EXPECT_TRUE(equal(ans.begin(), ans.end(), tot));
}

TEST(PrimesTest, Totient) {
  int sod[] = {1, 3, 4, 7, 6, 12, 8, 15, 13, 18, 12, 28, 14};
  vector<int> primes = getprimes(20);
  vector<int> ans;
  for (int i = 1; i <= 13; i++) {
    ans.push_back(sum_of_divisors<int>(i, primes));
  }
  EXPECT_TRUE(equal(ans.begin(), ans.end(), sod));
}

TEST(PrimesTest, LargeTotient) {
  vector<int> primes = getprimes(7);
  EXPECT_EQ(6, totient<int>(7, primes));
  EXPECT_EQ(4, totient<int>(8, primes));
  EXPECT_EQ(16, totient<int>(48, primes));
  EXPECT_EQ(42, totient<int>(49, primes));
}


