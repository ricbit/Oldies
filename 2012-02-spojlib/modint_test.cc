#include "gtest/gtest.h"
#include "modint.h"
#define VARMOD
#define modint varmod
#include "modint.h"
#undef modint

const int LIMIT = 0x7FFFFFFF;
const int BIG = 2000000000;

typedef modint<7> m7;
typedef modint<BIG> mbig;
typedef modint<LIMIT> mhuge;

TEST(ModintTest, Assign) {
  EXPECT_EQ(0, m7(0));
  EXPECT_EQ(6, m7(6));
  EXPECT_EQ(0, m7(0));
  EXPECT_EQ(6, m7(-1));
  EXPECT_EQ(1, modint<3>(4));
  EXPECT_EQ(LIMIT - 1, mhuge(-1));
  EXPECT_EQ(0, mhuge(LIMIT));
}

TEST(ModintTest, Add) {
  EXPECT_EQ(0, m7(1) + m7(6));
  EXPECT_EQ(2, m7(1) + m7(1));
  EXPECT_EQ(1, mbig(2) + mbig(BIG - 1));
  EXPECT_EQ(0, mhuge(LIMIT) + mhuge(-LIMIT));
  EXPECT_EQ(LIMIT - 2, mhuge(LIMIT - 1) + mhuge(LIMIT - 1));
}

TEST(ModintTest, PlusEqual) {
  m7 m = 5;
  EXPECT_EQ(3, m += m7(5));
  EXPECT_EQ(3, m);
}

TEST(ModintTest, Sub) {
  EXPECT_EQ(5, m7(6) - m7(1));
  EXPECT_EQ(5, m7(1) - m7(3));
  EXPECT_EQ(0, m7(3) - m7(3));
  EXPECT_EQ(1, mhuge(0) - mhuge(LIMIT - 1));
}

TEST(ModintTest, Mul) {
  EXPECT_EQ(6, m7(2) * m7(3));
  EXPECT_EQ(3, m7(2) * m7(5));
  EXPECT_EQ(3, m7(2) * m7(-2));
  EXPECT_EQ(1, mbig(BIG - 1) * mbig(BIG - 1));
  EXPECT_EQ(1, mhuge(LIMIT - 1) * mhuge(LIMIT - 1));
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
  EXPECT_EQ(1, -mhuge(LIMIT - 1));
  EXPECT_EQ(LIMIT - 1, -mhuge(1));
}

TEST(ModintTest, VarAdd) {
  M = 7;
  EXPECT_EQ(0, varmod(1) + varmod(6));
  EXPECT_EQ(2, varmod(1) + varmod(1));
  M = BIG;
  EXPECT_EQ(1, varmod(2) + varmod(BIG - 1));
  M = LIMIT;
  EXPECT_EQ(0, varmod(LIMIT) + varmod(-LIMIT));
  EXPECT_EQ(LIMIT - 2, varmod(LIMIT - 1) + varmod(LIMIT - 1));
}

TEST(ModintTest, VarInverse) {
  M = 7;
  EXPECT_EQ(1, varmod(2) * varmod(2).inverse());
  M = 2;
  EXPECT_EQ(1, varmod(1) * varmod(1).inverse());
}
