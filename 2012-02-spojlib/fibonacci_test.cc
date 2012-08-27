#include "gtest/gtest.h"
#include "fibonacci.h"

TEST(FibonacciTest, Int) {
  fibonacci<int> fib(16); 
  int ans[16] = {0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610};
  for (int i = 0; i < 16; i++) {
    EXPECT_EQ(ans[i], fib.nth(i)); 
  }
}

TEST(FibonacciTest, UnsignedChar) {
  fibonacci<unsigned char> fib(16); 
  int ans[16] = {0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 121, 98};
  for (int i = 0; i < 16; i++) {
    EXPECT_EQ(ans[i], fib.nth(i)); 
  }
}


