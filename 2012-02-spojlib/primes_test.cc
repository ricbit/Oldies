#include <algorithm>
#include <vector>
#include "gtest/gtest.h"
#include "primes.h"

using namespace std;

TEST(PrimesTest, GetPrimes) {
  int p11[] = {2, 3, 5, 7, 11};
  vector<int> primes11 = getprimes(11);
  EXPECT_TRUE(equal(primes11.begin(), primes11.end(), p11));

  int p16[] = {2, 3, 5, 7, 11, 13};
  vector<int> primes16 = getprimes(16);
  EXPECT_TRUE(equal(primes16.begin(), primes16.end(), p16));
}


