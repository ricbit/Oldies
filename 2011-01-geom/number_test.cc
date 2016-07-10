#include <limits.h>
#include "number.h"
#include <gtest/gtest.h>

using namespace std;

class NumberTest : public ::testing::Test {
 protected:
  string ToString(const Number* a) {
    unique_ptr<const Number> number(a);
    return number->ToString();
  }
  Number::NumberType Type(const Number* a) {
    unique_ptr<const Number> number(a);
    return number->type();
  }
  const Number* Simplify(const Number* a) {
    unique_ptr<const Number> number(a);
    return number->Simplify();
  }
  Number::SignType GetSign(const Number* a) {
    unique_ptr<const Number> number(a);
    return a->GetSign();
  }
  template<class T>
  const Number* Flip(T a) {
    unique_ptr<const Number> number(a);
    return a->Flip();
  }
  Comparator::Result Compare(const Number* a, const Number* b) {
    unique_ptr<const Number> a_(a);
    unique_ptr<const Number> b_(b);
    return Comparator::Compare(a, b);
  }
};

ostream& operator<<(ostream& os, const Number::NumberType& type) {
  string out;
  switch (type) {
    case Number::NumberType::RATIONAL:
      out = "RATIONAL";
      break;
    case Number::NumberType::DIV:
      out = "DIV";
      break;
    case Number::NumberType::MUL:
      out = "MUL";
      break;
    case Number::NumberType::ADD:
      out = "ADD";
      break;
    case Number::NumberType::SQRT:
      out = "SQRT";
      break;
  }
  return os << out;
}

TEST_F(NumberTest, Rational_type) {
  EXPECT_EQ(Number::NumberType::RATIONAL, Type(Rational(1, 2)));
}

TEST_F(NumberTest, Rational_ToString) {
  EXPECT_EQ("1/2", ToString(Rational(1,2)));
  EXPECT_EQ("40/7", ToString(Rational(40,7)));
  EXPECT_EQ("40/50", ToString(Rational(40,50)));
  EXPECT_EQ("-1/7", ToString(Rational(-1,7)));
}

TEST_F(NumberTest, Rational_Simplify) {
  EXPECT_EQ("1/2", ToString(Simplify(Rational(1,2))));
  EXPECT_EQ("1/2", ToString(Simplify(Rational(2,4))));
  EXPECT_EQ("-1/2", ToString(Simplify(Rational(-3,6))));
  EXPECT_EQ("0/1", ToString(Simplify(Rational(0,6))));
}

TEST_F(NumberTest, Rational_DivisionByZero) {
  EXPECT_DEATH(ToString(Simplify(Rational(1,0))), ".*");
}

TEST_F(NumberTest, Rational_Flip) {
  EXPECT_EQ("1/2", ToString(Flip(Rational(-1,2))));
  EXPECT_EQ("-1/2", ToString(Flip(Rational(1,2))));
  EXPECT_EQ("0/2", ToString(Flip(Rational(0,2))));
}

TEST_F(NumberTest, Rational_GetSign) {
  EXPECT_EQ(Number::POSITIVE, GetSign(Rational(1,2)));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Rational(-1,2)));
  EXPECT_EQ(Number::ZERO, GetSign(Rational(0,2)));
}

TEST_F(NumberTest, Add_type) {
  EXPECT_EQ(Number::NumberType::ADD, Type(Add(Rational(1, 2), Rational(1,2))));
}

TEST_F(NumberTest, Add_ToString) {
  EXPECT_EQ("(1/2)+(1/3)", ToString(Add(Rational(1,2), Rational(1,3))));
  EXPECT_EQ("(1/2)+((1/3)+(1/4))", 
            ToString(Add(Rational(1,2), 
	                 Add(Rational(1,3),Rational(1,4)))));
}

TEST_F(NumberTest, Add_Simplify) {
  EXPECT_EQ("5/6", ToString(Simplify(Add(Rational(1,2), Rational(1,3)))));
  EXPECT_EQ("0/1", ToString(Simplify(Add(Rational(1,2), Rational(-1,2)))));
  EXPECT_EQ("3/2", ToString(Simplify(Add(Rational(1,2),
                                         Add(Rational(1,2), Rational(1,2))))));
  EXPECT_EQ("sqrt(2/1)", ToString(Simplify(Add(Rational(0,2),
                                               Sqrt(Rational(2,1))))));
  EXPECT_EQ("sqrt(2/1)", ToString(Simplify(Add(Sqrt(Rational(2,1)),
                                               Rational(0,2)))));
}

TEST_F(NumberTest, Add_GetSign) {
  EXPECT_EQ(Number::POSITIVE, GetSign(Add(Rational(1,2), Rational(1,3))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Add(Rational(-1,2), Rational(1,3))));
  EXPECT_EQ(Number::ZERO, GetSign(Add(Rational(-1,2), Rational(1,2))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Add(Rational(-1,2), Rational(-1,2))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Add(Rational(0,2), Rational(-1,2))));
  EXPECT_EQ(Number::POSITIVE, GetSign(Add(Rational(0,2), Rational(1,2))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Add(Rational(-1,2), Rational(0,2))));
  EXPECT_EQ(Number::POSITIVE, GetSign(Add(Rational(1,2), Rational(0,2))));
  EXPECT_EQ(Number::ZERO, GetSign(Add(Rational(0,2), Rational(0,2))));
}

TEST_F(NumberTest, Mul_type) {
  EXPECT_EQ(Number::NumberType::MUL, Type(Mul(Rational(1, 2), Rational(1,2))));
}

TEST_F(NumberTest, Mul_ToString) {
  EXPECT_EQ("(1/2)*(1/3)", ToString(Mul(Rational(1,2), Rational(1,3))));
  EXPECT_EQ("(1/2)*((1/3)*(1/4))", 
            ToString(Mul(Rational(1,2), 
	                 Mul(Rational(1,3),Rational(1,4)))));
}

TEST_F(NumberTest, Mul_Simplify) {
  EXPECT_EQ("1/1", ToString(Simplify(Mul(Rational(1,2), Rational(2,1)))));
  EXPECT_EQ("4/1", ToString(Simplify(Mul(Rational(2,1), Rational(2,1)))));
  EXPECT_EQ("-15/14", ToString(Simplify(Mul(Rational(3,2), Rational(-5,7)))));
  EXPECT_EQ("1/8", ToString(Simplify(Mul(Rational(1,2),
                                         Mul(Rational(1,2), Rational(1,2))))));
  EXPECT_EQ("2/1", ToString(Simplify(Mul(Sqrt(Rational(2,1)), 
                                         Sqrt(Rational(2,1))))));
  EXPECT_EQ("-2/1", ToString(Simplify(Mul(nSqrt(Rational(2,1)), 
                                         Sqrt(Rational(2,1))))));
  EXPECT_EQ("-2/1", ToString(Simplify(Mul(Sqrt(Rational(2,1)), 
                                         nSqrt(Rational(2,1))))));
  EXPECT_EQ("2/1", ToString(Simplify(Mul(nSqrt(Rational(2,1)), 
                                         nSqrt(Rational(2,1))))));
  /*EXPECT_EQ("2/1", ToString(Simplify(Mul(Add(Rational(1,1),
                                             Sqrt(Rational(3,1))),
					 Add(Sqrt(Rational(3,1)
					     Rational(1,1))))));*/
}

TEST_F(NumberTest, Div_type) {
  EXPECT_EQ(Number::NumberType::DIV, Type(Div(Rational(1, 2), Rational(1,2))));
}

TEST_F(NumberTest, Div_ToString) {
  EXPECT_EQ("(1/2)/(1/3)", ToString(Div(Rational(1,2), Rational(1,3))));
  EXPECT_EQ("(1/2)/((1/3)/(1/4))", 
            ToString(Div(Rational(1,2), 
	                 Div(Rational(1,3),Rational(1,4)))));
}

TEST_F(NumberTest, Div_Simplify) {
  EXPECT_EQ("1/1", ToString(Simplify(Div(Rational(2,1), Rational(2,1)))));
  EXPECT_EQ("4/1", ToString(Simplify(Div(Rational(2,1), Rational(1,2)))));
  EXPECT_EQ("-21/10", ToString(Simplify(Div(Rational(3,2), Rational(-5,7)))));
  EXPECT_EQ("(sqrt(4/3))+(sqrt(2/3))", ToString(Simplify(
      Div(Add(Rational(2,1), Sqrt(Rational(2,1))),
          Sqrt(Rational(3,1))))));
}

TEST_F(NumberTest, Sqrt_type) {
  EXPECT_EQ(Number::NumberType::SQRT, Type(Sqrt(Rational(1, 2))));
}

TEST_F(NumberTest, Sqrt_ToString) {
  EXPECT_EQ("sqrt(1/2)", ToString(Sqrt(Rational(1,2))));
  EXPECT_EQ("(-sqrt(1/2))", ToString(nSqrt(Rational(1,2))));
}

TEST_F(NumberTest, Sqrt_Flip) {
  EXPECT_EQ("(-sqrt(1/2))", ToString(Flip(Sqrt(Rational(1,2)))));
  EXPECT_EQ("sqrt(1/2)", ToString(Flip(nSqrt(Rational(1,2)))));
}

TEST_F(NumberTest, Sqrt_Simplify) {
  EXPECT_EQ("sqrt(1/2)", ToString(Simplify(Sqrt(Rational(1,2)))));
  EXPECT_EQ("2/3", ToString(Simplify(Sqrt(Rational(4,9)))));
  EXPECT_EQ("(-sqrt(1/2))", ToString(Simplify(nSqrt(Rational(1,2)))));
  EXPECT_EQ("0/1", ToString(Simplify(nSqrt(Rational(0,1)))));
}

TEST_F(NumberTest, Sqrt_GetSign) {
  EXPECT_EQ(Number::POSITIVE, GetSign(Sqrt(Rational(1,1))));
  EXPECT_EQ(Number::ZERO, GetSign(Sqrt(Rational(0,1))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(nSqrt(Rational(1,1))));
  EXPECT_EQ(Number::ZERO, GetSign(nSqrt(Rational(0,1))));
}

TEST_F(NumberTest, Mixed_Simplify) {
  EXPECT_EQ("sqrt(8/1)", ToString(Simplify(Mul(Rational(2,1),
  					       Sqrt(Rational(2,1))))));
  EXPECT_EQ("sqrt(8/1)", ToString(Simplify(Mul(Sqrt(Rational(2,1)),
  					       Rational(2,1)))));
  EXPECT_EQ("(4/1)+(sqrt(8/1))",
            ToString(Simplify(Mul(Rational(2,1),
	                          Add(Rational(2,1),
				      Sqrt(Rational(2,1)))))));
  EXPECT_EQ("(-sqrt(2/1))", ToString(Simplify(Mul(Rational(-1,1),
                                                  Sqrt(Rational(2,1))))));
}

TEST_F(NumberTest, Mixed_GetSign) {
  EXPECT_EQ(Number::NEGATIVE,
            GetSign(Add(Rational(-2,1), Sqrt(Rational(2,1)))));
  EXPECT_EQ(Number::POSITIVE, GetSign(Add(Rational(2,1), Sqrt(Rational(2,1)))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Mul(Rational(-2,1), 
                                          Sqrt(Rational(1,1)))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Add(Rational(-4,1),
                                          Add(Rational(2,1),
  			                      Sqrt(Rational(2,1))))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Add(Rational(1,1),
                                      Add(Rational(-4,1),
   			                  Sqrt(Rational(2,1))))));
  EXPECT_EQ(Number::NEGATIVE, GetSign(Add(Sqrt(Rational(2,1)), 
                                          nSqrt(Rational(3,1)))));
  EXPECT_EQ(Number::POSITIVE, GetSign(Add(Sqrt(Rational(3,1)), 
                                          nSqrt(Rational(2,1)))));
}

TEST_F(NumberTest, Compare_SimpleComparations) {
  EXPECT_EQ(Comparator::EQUAL, Compare(Rational(2, 1),
                                       Mul(Sqrt(Rational(2,1)),
				           Sqrt(Rational(2,1)))));
  EXPECT_EQ(Comparator::EQUAL, Compare(
      Mul(Sqrt(Rational(45, 16)), nSqrt(Rational(45, 4))),
      Rational(-45, 8)));
  EXPECT_EQ(Comparator::EQUAL, Compare(
      Add(nSqrt(Rational(45, 4)), Sqrt(Rational(45, 16))),
      nSqrt(Rational(45, 16))));
  EXPECT_EQ(Comparator::EQUAL, Compare(
      Mul(Add(Rational(1, 2), Sqrt(Rational(5, 4))),
          Add(Rational(1, 2), Sqrt(Rational(5, 4)))),
      Add(Rational(6, 4), Sqrt(Rational(5, 4)))));
}

TEST_F(NumberTest, Compare_Fibonacci_2) {
  EXPECT_EQ(Comparator::EQUAL, Compare(
      Rational(1, 1),
      Add(Mul(Sqrt(Rational(1, 5)),
              Mul(Add(Rational(1, 2), Sqrt(Rational(5, 4))),
                  Add(Rational(1, 2), Sqrt(Rational(5, 4))))),
          Mul(nSqrt(Rational(1, 5)),
              Mul(Add(Rational(1, 2), nSqrt(Rational(5, 4))),
                  Add(Rational(1, 2), nSqrt(Rational(5, 4))))))));
}

TEST_F(NumberTest, Compare_HardDivisions) {
  EXPECT_EQ(Comparator::EQUAL, Compare(
    Add(Rational(-3,1), nSqrt(Rational(8,1))),
    Div(Add(Rational(1,1), Sqrt(Rational(2,1))),
        Add(Rational(1,1), nSqrt(Rational(2,1))))));

  EXPECT_EQ(Comparator::EQUAL, Compare(
    Sqrt(Rational(2,1)),
    Div(Rational(1,1), Div(Rational(1,1), Sqrt(Rational(2,1))))));
}

TEST_F(NumberTest, Compare_ComparisonsWithZero) {
  EXPECT_EQ(Comparator::LESSER, Compare(Rational(0,1), Rational(4,1)));
  EXPECT_EQ(Comparator::GREATER, Compare(Rational(0,1), Rational(-4,1)));
  EXPECT_EQ(Comparator::GREATER, Compare(Rational(4,1), Rational(0,1)));
  EXPECT_EQ(Comparator::LESSER, Compare(Rational(-4,1), Rational(0,1)));
  EXPECT_EQ(Comparator::EQUAL, Compare(Rational(0,1), Rational(0,1)));
}

