#include "gtest/gtest.h"
#include "modint.h"

typedef modint<7> m7;
typedef modint<2000000000> mbig;

TEST(ModintTest, Assign) {
  EXPECT_EQ(0, m7(0));
  EXPECT_EQ(6, m7(6));
  EXPECT_EQ(0, m7(0));
  EXPECT_EQ(6, m7(-1));
  EXPECT_EQ(1, modint<3>(4));
}

TEST(ModintTest, Add) {
  EXPECT_EQ(0, m7(1) + m7(6));
  EXPECT_EQ(2, m7(1) + m7(1));
  EXPECT_EQ(1, mbig(2) + mbig(1999999999));
}

TEST(ModintTest, Sub) {
  EXPECT_EQ(5, m7(6) - m7(1));
  EXPECT_EQ(5, m7(1) - m7(3));
  EXPECT_EQ(0, m7(3) - m7(3));
}

TEST(ModintTest, Mul) {
  EXPECT_EQ(6, m7(2) * m7(3));
  EXPECT_EQ(3, m7(2) * m7(5));
  EXPECT_EQ(3, m7(2) * m7(-2));
  EXPECT_EQ(1, mbig(1999999999) * mbig(1999999999));
}

TEST(ModintTest, Power) {
  EXPECT_EQ(1, m7(2).power(0));
  EXPECT_EQ(2, m7(2).power(1));
  EXPECT_EQ(4, m7(2).power(2));
  EXPECT_EQ(1, m7(2).power(3));
  EXPECT_EQ(2, m7(2).power(1LL << 50));
  EXPECT_EQ(0, modint<1>(2).power(0));
}

TEST(ModintTest, Inverse) {
  EXPECT_EQ(1, m7(2) * m7(2).inverse());
  EXPECT_EQ(1, m7(3) * m7(3).inverse());
}

TEST(ModintTest, Negation) {
  EXPECT_EQ(1, -m7(-1));
  EXPECT_EQ(6, -m7(1));
  EXPECT_EQ(0, -m7(0));
}
