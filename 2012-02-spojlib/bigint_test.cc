#include "gtest/gtest.h"
#include "bigint.h"

using namespace std;

template<int B>
ostream& operator<<(ostream& os, const _bigint<B>& b) {
  return os << static_cast<string>(b);
}

TEST(BigintTest, PowerOf10) {
  EXPECT_EQ(1, static_cast<int>(_bigint<0>::B10));
  EXPECT_EQ(10, static_cast<int>(_bigint<1>::B10));
  EXPECT_EQ(100, static_cast<int>(_bigint<2>::B10));
  EXPECT_EQ(1000, static_cast<int>(_bigint<3>::B10));
}

TEST(BigintTest, InputOutput) {
  EXPECT_EQ("1234567890", static_cast<string>(_bigint<1>("1234567890")));
  EXPECT_EQ("1234567890", static_cast<string>(_bigint<2>("1234567890")));
  EXPECT_EQ("1234567890", static_cast<string>(_bigint<3>("1234567890")));
  EXPECT_EQ("1000001", static_cast<string>(_bigint<3>("1000001")));
  EXPECT_EQ("0", static_cast<string>(_bigint<3>("0")));
  EXPECT_EQ("0", static_cast<string>(_bigint<3>("00000")));
}

TEST(BigintTest, Equals) {
  EXPECT_EQ(_bigint<2>("2"), _bigint<2>("2"));
  EXPECT_EQ(_bigint<2>("2"), _bigint<2>("000002"));
  EXPECT_EQ(_bigint<2>("0"), _bigint<2>("00000"));
}

TEST(BigintTest, Add) {
  EXPECT_EQ(_bigint<2>("2"), _bigint<2>("1") + _bigint<2>("1"));
  EXPECT_EQ(_bigint<2>("222"), _bigint<2>("111") + _bigint<2>("111"));
  EXPECT_EQ(_bigint<2>("1000000"), _bigint<2>("1") + _bigint<2>("999999"));
  EXPECT_EQ(_bigint<2>("1000000"), _bigint<2>("999999") + _bigint<2>("1"));
  EXPECT_EQ(_bigint<2>("123456"), _bigint<2>("123456") + _bigint<2>("0"));
}

TEST(BigintTest, Mul) {
  EXPECT_EQ(_bigint<2>("0"), _bigint<2>("0") * _bigint<2>("23"));
  EXPECT_EQ(_bigint<2>("222"), _bigint<2>("1") * _bigint<2>("222"));
  EXPECT_EQ(_bigint<2>("1110"), _bigint<2>("5") * _bigint<2>("222"));
  EXPECT_EQ(_bigint<4>("123437655"), _bigint<4>("9999") * _bigint<4>("12345"));
  EXPECT_EQ(_bigint<9>("13855980808080807943495311"), 
            _bigint<9>("112233445566778899") *
            _bigint<9>("123456789"));
}


