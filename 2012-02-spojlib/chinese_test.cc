#include "gtest/gtest.h"
#include "chinese.h"

TEST(ChineseRemainderTest, Eval) {
  int mods[4] = {3, 5, 7, 13};
  int rems[4] = {1, 2, 3, 4};
  ChineseRemainder<int> crt(std::vector<int>(mods, mods + 4));
  int ans = crt.eval(std::vector<int>(rems, rems + 4));
  EXPECT_EQ(1, ans % 3);
  EXPECT_EQ(2, ans % 5);
  EXPECT_EQ(3, ans % 7);
  EXPECT_EQ(4, ans % 13);
}

