#include "gtest/gtest.h"
#include "modint.h"

typedef modint<7> m7;
typedef modint<2000000000> mbig;

TEST(ModintTest, Assign) {
  EXPECT_EQ(0, m7(0).get());
  EXPECT_EQ(6, m7(6).get());
  EXPECT_EQ(0, m7(0).get());
  EXPECT_EQ(6, m7(-1).get());
  EXPECT_EQ(1, modint<3>(4).get());
}

TEST(ModintTest, Add) {
  EXPECT_EQ(0, (m7(1) + m7(6)).get());
  EXPECT_EQ(2, (m7(1) + m7(1)).get());
  EXPECT_EQ(1, (mbig(2) + mbig(1999999999)).get());
}

TEST(ModintTest, Mul) {
  EXPECT_EQ(6, (m7(2) * m7(3)).get());
  EXPECT_EQ(3, (m7(2) * m7(5)).get());
  EXPECT_EQ(3, (m7(2) * m7(-2)).get());
  EXPECT_EQ(1, (mbig(1999999999) * mbig(1999999999)).get());
}

TEST(ModintTest, Power) {
  EXPECT_EQ(1, (m7(2).power(0)).get());
  EXPECT_EQ(2, (m7(2).power(1)).get());
  EXPECT_EQ(4, (m7(2).power(2)).get());
  EXPECT_EQ(1, (m7(2).power(3)).get());
  EXPECT_EQ(2, (m7(2).power(1LL << 50)).get());
  EXPECT_EQ(0, (modint<1>(2).power(0)).get());
}

TEST(ModintTest, Inverse) {
  EXPECT_EQ(1, (m7(2) * m7(2).inverse()).get());
  EXPECT_EQ(1, (m7(3) * m7(3).inverse()).get());
}

TEST(ModintTest, Negation) {
  EXPECT_EQ(1, (-m7(-1)).get());
  EXPECT_EQ(6, (-m7(1)).get());
  EXPECT_EQ(0, (-m7(0)).get());
}
