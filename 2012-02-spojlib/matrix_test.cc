#include "gtest/gtest.h"
#include "matrix.h"

TEST(MatrixTest, Assign) {
  matrix<int> m(2, 2);
  m[0][0] = 1;
  m[0][1] = 2;
  m[1][0] = 3;
  m[1][1] = 4;
  EXPECT_EQ(1, m[0][0]);
  EXPECT_EQ(2, m[0][1]);
  EXPECT_EQ(3, m[1][0]);
  EXPECT_EQ(4, m[1][1]);
}

TEST(MatrixTest, AssignInline) {
  const static int data[] = {1, 2, 3, 4};
  matrix<int> m(2, 2, data);
  EXPECT_EQ(1, m[0][0]);
  EXPECT_EQ(2, m[0][1]);
  EXPECT_EQ(3, m[1][0]);
  EXPECT_EQ(4, m[1][1]);
}

TEST(MatrixTest, Equal) {
  const static int a[] = {1, 2, 3, 4};
  const static int b[] = {1, 2, 3, 4};
  const static int c[] = {1, 2, 3, 5};
  matrix<int> ma(2, 2, a);
  matrix<int> mb(2, 2, b);
  matrix<int> mc(2, 2, c);
  EXPECT_EQ(ma, ma);
  EXPECT_EQ(ma, mb);
  EXPECT_NE(ma, mc);
}

TEST(MatrixTest, Add) {
  const static int a[] = {1, 2, 3, 4};
  const static int b[] = {2, 3, 4, 5};
  const static int c[] = {3, 5, 7, 9};
  matrix<int> ma(2, 2, a);
  matrix<int> mb(2, 2, b);
  matrix<int> mc(2, 2, c);
  EXPECT_EQ(mc, ma + mb);
}

TEST(MatrixTest, Mul) {
  const static int a[] = {2, 3, 4, 1, 2, 5};
  const static int b[] = {1, 4, 2, 5, 3, 6};
  const static int c[] = {20, 47, 20, 44};
  matrix<int> ma(2, 3, a);
  matrix<int> mb(3, 2, b);
  matrix<int> mc(2, 2, c);
  EXPECT_EQ(mc, ma * mb);
}

TEST(MatrixTest, Power) {
  const static int a[] = {1, 2, 3, 4};
  const static int b[] = {890461, 1297782, 1946673, 2837134};
  const static int c[] = {1, 0, 0, 1};
  matrix<int> ma(2, 2, a);
  matrix<int> mb(2, 2, b);
  matrix<int> mc(2, 2, c);
  EXPECT_EQ(mb, ma.power(9));
  EXPECT_EQ(mc, ma.power(0));
  EXPECT_EQ(mc, ma.power(0));
}

TEST(MatrixTest, Determinant) {
  const static int a[] = {1};
  const static int b[] = {1, 2, 3, 4};
  const static int c[] = {1, 2, 3, 4, 5, 3, 9, 7, 6};
  const static int d[] = {1, 2, 3, 5, 4, 5, 6, 8, 9, 7, 6, 1, 3, 5, 7, 9};
  matrix<int> ma(1, 1, a);
  matrix<int> mb(2, 2, b);
  matrix<int> mc(3, 3, c);
  matrix<int> md(4, 4, d);
  EXPECT_EQ(1, ma.determinant());
  EXPECT_EQ(-2, mb.determinant());
  EXPECT_EQ(-36, mc.determinant());
  EXPECT_EQ(6, md.determinant());
}
