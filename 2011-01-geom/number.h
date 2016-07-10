#include <memory>
#include <string>
#include <vector>
#include <iostream>
#include <gmpxx.h>

class Number {
 public:
  enum class NumberType {
    RATIONAL,
    ADD,
    MUL,
    DIV,
    SQRT
  };
  enum SignType {
    POSITIVE,
    NEGATIVE,
    ZERO
  };
  Number() : has_sign_(false), has_simplify_(false), sign_(ZERO) {}
  virtual ~Number() {}
  virtual NumberType type() const = 0;
  virtual std::string ToString() const = 0;
  virtual const Number* GetSimplify() const = 0;
  virtual SignType GetSign() const = 0;
  virtual const Number* Copy() const = 0;
  SignType sign() const {
    if (has_sign_)
      return sign_;
    else {
      has_sign_ = true;
      return sign_ = GetSign();
    }
  }
  const Number* Simplify() const {
    /*if (has_simplify_)
      return simplify_->Copy();
    else {
      has_simplify_ = true;
      simplify_.reset(GetSimplify());
      return simplify_->Copy();
    }*/
    return GetSimplify();
  }
 protected:
  mutable bool has_sign_;
  mutable bool has_simplify_;
  mutable SignType sign_;
  mutable std::unique_ptr<const Number> simplify_;
};

class RationalNumber : public Number {
 public:
  RationalNumber(mpz_class num, mpz_class den) : num_(num), den_(den) {}
  NumberType type() const { return NumberType::RATIONAL; }
  std::string ToString() const;
  const Number* GetSimplify() const;
  SignType GetSign() const;
  const Number* Flip() const;
  const Number* Copy() const;
  mpz_class den() const { return den_; }
  mpz_class num() const { return num_; }
 private:
  const mpz_class num_, den_;
};

RationalNumber* Rational(mpz_class num, mpz_class den);

class AddNumber : public Number {
 public:
  AddNumber(const Number* a, const Number* b);
  NumberType type() const { return NumberType::ADD; }
  std::string ToString() const;
  const Number* GetSimplify() const;
  SignType GetSign() const;
  const Number* Copy() const;
  const Number* a() const { return a_.get(); }
  const Number* b() const { return b_.get(); }
 private:
  std::shared_ptr<const Number> a_;
  std::shared_ptr<const Number> b_;
};

AddNumber* Add(const Number* a, const Number* b);

class MulNumber : public Number {
 public:
  MulNumber(const Number* a, const Number* b);
  NumberType type() const { return NumberType::MUL; }
  std::string ToString() const;
  const Number* GetSimplify() const;
  SignType GetSign() const;
  const Number* Copy() const;
  const Number* a() const { return a_.get(); }
  const Number* b() const { return b_.get(); }
 private:
  std::unique_ptr<const Number> a_;
  std::unique_ptr<const Number> b_;
};

MulNumber* Mul(const Number* a, const Number* b);

class DivNumber : public Number {
 public:
  DivNumber(const Number* a, const Number* b);
  NumberType type() const { return NumberType::DIV; }
  std::string ToString() const;
  const Number* GetSimplify() const;
  SignType GetSign() const;
  const Number* Copy() const;
  const Number* a() const { return a_.get(); }
  const Number* b() const { return b_.get(); }
 private:
  std::unique_ptr<const Number> a_;
  std::unique_ptr<const Number> b_;
};

DivNumber* Div(const Number* a, const Number* b);

class SqrtNumber : public Number {
 public:
  SqrtNumber(const Number* x, bool sign);
  NumberType type() const { return NumberType::SQRT; }
  std::string ToString() const;
  const Number* GetSimplify() const;
  SignType GetSign() const;
  const Number* Copy() const;
  const Number* Flip() const;
  const Number* x() const { return x_.get(); }
 private:
  std::unique_ptr<const Number> x_;
  bool sign_;
};

SqrtNumber* Sqrt(const Number* x);
SqrtNumber* nSqrt(const Number* x);

class Comparator {
 public:
  enum Result {
    LESSER,
    EQUAL,
    GREATER
  };
  static Result CompareModulus(const Number* a, const Number* b);
  static Result ComparePositive(const Number* a, const Number* b);
  static Result Compare(const Number* a, const Number* b);
};
