#include "gtest/gtest.h"
#include "bigint.h"

using namespace std;

template<int B>
ostream& operator<<(ostream& os, const bigint<B>& b) {
  return os << static_cast<string>(b);
}

TEST(BigintTest, PowerOf10) {
  EXPECT_EQ(1, static_cast<int>(bigint<0>::B10));
  EXPECT_EQ(10, static_cast<int>(bigint<1>::B10));
  EXPECT_EQ(100, static_cast<int>(bigint<2>::B10));
  EXPECT_EQ(1000, static_cast<int>(bigint<3>::B10));
}

TEST(BigintTest, InputOutput) {
  EXPECT_EQ("1234567890", static_cast<string>(bigint<1>("1234567890")));
  EXPECT_EQ("1234567890", static_cast<string>(bigint<2>("1234567890")));
  EXPECT_EQ("1234567890", static_cast<string>(bigint<3>("1234567890")));
  EXPECT_EQ("1000001", static_cast<string>(bigint<3>("1000001")));
  EXPECT_EQ("0", static_cast<string>(bigint<3>("0")));
  EXPECT_EQ("0", static_cast<string>(bigint<3>("00000")));
}

TEST(BigintTest, Equals) {
  EXPECT_EQ(bigint<2>("2"), bigint<2>("2"));
  EXPECT_EQ(bigint<2>("2"), bigint<2>("000002"));
  EXPECT_EQ(bigint<2>("0"), bigint<2>("00000"));
}

TEST(BigintTest, Add) {
  EXPECT_EQ(bigint<2>("2"), bigint<2>("1") + bigint<2>("1"));
  EXPECT_EQ(bigint<2>("222"), bigint<2>("111") + bigint<2>("111"));
  EXPECT_EQ(bigint<2>("1000000"), bigint<2>("1") + bigint<2>("999999"));
  EXPECT_EQ(bigint<2>("1000000"), bigint<2>("999999") + bigint<2>("1"));
  EXPECT_EQ(bigint<2>("123456"), bigint<2>("123456") + bigint<2>("0"));
}

TEST(BigintTest, Mul) {
  EXPECT_EQ(bigint<2>("0"), bigint<2>("0") * bigint<2>("23"));
  EXPECT_EQ(bigint<2>("222"), bigint<2>("1") * bigint<2>("222"));
  EXPECT_EQ(bigint<2>("1110"), bigint<2>("5") * bigint<2>("222"));
  EXPECT_EQ(bigint<4>("123437655"), bigint<4>("9999") * bigint<4>("12345"));
  EXPECT_EQ(bigint<9>("13855980808080807943495311"), 
            bigint<9>("112233445566778899") *
            bigint<9>("123456789"));
}


