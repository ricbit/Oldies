#include <cstdio>
#include <iostream>
#include <sstream>
#include "number.h"

using namespace std;

static mpz_class gcd(mpz_class a, mpz_class b) {
  mpz_class c;
  mpz_gcd(c.get_mpz_t(), a.get_mpz_t(), b.get_mpz_t());
  return c;
}

static bool square(mpz_class x) {
  return mpz_perfect_square_p(x.get_mpz_t()) != 0;
}

void Collect(const Number* a, bool positive_rational, bool positive_sqrt,
             vector<const Number*>& rationals,
	     vector<const Number*>& sqrts) {

  if (a->type() == Number::NumberType::RATIONAL) {
    if (positive_rational)
      rationals.push_back(a->Simplify());
    else
      rationals.push_back(dynamic_cast<const RationalNumber*>(a)->Flip());
    return;
  }
  if (a->type() == Number::NumberType::SQRT) {
    if (positive_sqrt)
      sqrts.push_back(a->Simplify());
    else
      sqrts.push_back(dynamic_cast<const SqrtNumber*>(a)->Flip());
    return;
  } 
  if (a->type() != Number::NumberType::ADD) {
    cout << "bug: " << a->ToString() << "\n";
    return;
  }
  auto add = dynamic_cast<const AddNumber*>(a);
  Collect(add->a(), positive_rational, positive_sqrt, rationals, sqrts);
  Collect(add->b(), positive_rational, positive_sqrt, rationals, sqrts);
}	     

const Number* CollectRationals(vector<const Number*>& rationals) {
  /*const Number* rational_sum = new RationalNumber(0, 1);
  for (auto it : rationals) {
    rational_sum = new AddNumber(rational_sum, it);
  }
  unique_ptr<const Number> rational_sum_(rational_sum);
  return rational_sum->Simplify();*/
  mpz_class num = 0;
  mpz_class den = 1;
  for (auto it : rationals) {
    auto r = dynamic_cast<const RationalNumber*>(it);
    num = num*r->den() + r->num()*den;
    den *= r->den();
  }
  mpz_class x = gcd(abs(num), den);
  return new RationalNumber(num / x, den / x);
}

const Number* CollectSqrts(vector<const Number*>& sqrts) {
  const Number* sqrt_sum = nullptr;
  for (auto it : sqrts) {
    if (sqrt_sum)
      sqrt_sum = new AddNumber(sqrt_sum, it);
    else
      sqrt_sum = it;
  }
  return sqrt_sum;
}

string RationalNumber::ToString() const {
  stringstream out;
  out << num() << "/" << den();
  return out.str();
}

RationalNumber* Rational(mpz_class num, mpz_class den) {
  if (den == 0) exit(1);
  return new RationalNumber(num, den);
}

const Number* RationalNumber::Copy() const {
  return new RationalNumber(num_, den_);
}

const Number* RationalNumber::GetSimplify() const {
  mpz_class x = gcd(abs(num()), den());
  return new RationalNumber(num() / x, den() / x);
}

const Number* RationalNumber::Flip() const {
  return new RationalNumber(-num(), den());
}

Number::SignType RationalNumber::GetSign() const {
  if (num() == 0)
    return ZERO;
  return num() > 0 ? POSITIVE : NEGATIVE;
}

AddNumber::AddNumber(const Number* a, const Number* b): a_(a), b_(b) {}

string AddNumber::ToString() const {
  stringstream out;
  out << "(" << a()->ToString() << ")+(" << b()->ToString() << ")";
  return out.str();
}

const Number* AddNumber::Copy() const {
  return new AddNumber(a_->Copy(), b_->Copy());
}

const Number* AddNumber::GetSimplify() const {
  auto sa = a()->Simplify();
  auto sb = b()->Simplify();
  //cout << "ADD1 " << sa->ToString() << "\n";
  //cout << "ADD2 " << sb->ToString() << "\n";
  if (sa->type() == NumberType::RATIONAL &&
      dynamic_cast<const RationalNumber*>(sa)->num() == 0) {
    delete sa;
    return sb;
  }
  if (sb->type() == NumberType::RATIONAL &&
      dynamic_cast<const RationalNumber*>(sb)->num() == 0) {
    delete sb;
    return sa;
  }
  if (sa->type() == NumberType::RATIONAL &&
      sb->type() == NumberType::RATIONAL) {
    auto ra = dynamic_cast<const RationalNumber*>(sa);
    auto rb = dynamic_cast<const RationalNumber*>(sb);
    unique_ptr<RationalNumber> sum(new RationalNumber(
        ra->num()*rb->den() + rb->num()*ra->den(), ra->den()*rb->den()));
    delete sa;
    delete sb;
    return sum->Simplify();	
  }
  /*vector<const Number*> rationals;
  vector<const Number*> sqrts;
  Collect(sa, true, true, rationals, sqrts);
  Collect(sb, true, true, rationals, sqrts);
  auto rationals_sum = CollectRationals(rationals);
  auto sqrt_sum = CollectSqrts(sqrts);
  const Number* ans;
  if (sqrt_sum == nullptr)
    ans = rationals_sum;
  else
    ans = new AddNumber(rationals_sum, sqrt_sum);
  delete sa;
  delete sb;
  return ans;*/
  return new AddNumber(sa, sb);
}

Number::SignType AddNumber::GetSign() const {
  auto a_sign = a()->GetSign();
  auto b_sign = b()->GetSign();
  if (a_sign == ZERO) {
    return b_sign;
  }
  if (b_sign == ZERO) {
    return a_sign;
  }
  if (a_sign == b_sign) {
    return a_sign;
  }
  auto result = Comparator::CompareModulus(a(), b());
  if (result == Comparator::EQUAL)
    return ZERO;
  return result == Comparator::GREATER ? a_sign : b_sign;
}

AddNumber* Add(const Number* a, const Number* b) {
  return new AddNumber(a,b);
}

MulNumber::MulNumber(const Number* a, const Number* b): a_(a), b_(b) {}

const Number* MulNumber::Copy() const {
  return new MulNumber(a_->Copy(), b_->Copy());
}

string MulNumber::ToString() const {
  stringstream out;
  out << "(" << a_->ToString() << ")*(" << b_->ToString() << ")";
  return out.str();
}

static const Number* Square(const Number* x) {
  switch (x->type()) {
    case Number::NumberType::RATIONAL: {
      auto rx = dynamic_cast<const RationalNumber*>(x);
      return new RationalNumber(rx->num()*rx->num(), rx->den()*rx->den());
    }
    case Number::NumberType::SQRT: {
      auto sx = dynamic_cast<const SqrtNumber*>(x);
      return sx->x()->Simplify();
    }
    default: {
      unique_ptr<Number> ans(new MulNumber(x->Simplify(), x->Simplify()));
      return ans->Simplify();
    }
  }
}

Number::SignType SignTimes(Number::SignType a, Number::SignType b) {
  if (a == Number::ZERO || b == Number::ZERO)
    return Number::ZERO;
  if (a == b)
    return Number::POSITIVE;
  else
    return Number::NEGATIVE;
}

const Number* MulNumber::GetSimplify() const {
  unique_ptr<const Number> sa(a()->Simplify());
  unique_ptr<const Number> sb(b()->Simplify());
  //cout << "MUL1 " << sa->ToString() << "\n";
  //cout << "MUL2 " << sb->ToString() << "\n";
  if (sa->type() == NumberType::RATIONAL &&
      sb->type() == NumberType::RATIONAL) {
    auto ra = dynamic_cast<const RationalNumber*>(sa.get());
    auto rb = dynamic_cast<const RationalNumber*>(sb.get());
    unique_ptr<Number> sum(new RationalNumber(
        ra->num()*rb->num(), ra->den()*rb->den()));
    return sum->Simplify();	
  } 
  if (sb->type() == NumberType::ADD) {
    sa.swap(sb);
  }
  if (sa->type() == NumberType::ADD) {
    auto ra = dynamic_cast<const AddNumber*>(sa.get());
    unique_ptr<Number> ans(new AddNumber(new MulNumber(sb->Simplify(),
                                                       ra->a()->Simplify()),
                                         new MulNumber(sb->Simplify(),
					               ra->b()->Simplify())));
    return ans->Simplify();
  }
  if (sb->type() == NumberType::SQRT) {
    sa.swap(sb);
  }
  if (sa->type() == NumberType::SQRT) {
    auto ra = dynamic_cast<const SqrtNumber*>(sa.get());
    auto signa = sa->GetSign();
    auto signb = sb->GetSign();
    auto signx = SignTimes(signa, signb);
    unique_ptr<Number> ans(new SqrtNumber(
        new MulNumber(Square(sb.get()), ra->x()->Simplify()),
	signx != Number::NEGATIVE));
    return ans->Simplify();	
  }
  cout <<"loop\n";
  unique_ptr<Number> ans(new MulNumber(sa->Simplify(), sb->Simplify()));
  return ans->Simplify();
}

Number::SignType MulNumber::GetSign() const{
  return SignTimes(a()->GetSign(), b()->GetSign());
}

MulNumber* Mul(const Number* a, const Number* b) {
  return new MulNumber(a,b);
}

DivNumber::DivNumber(const Number* a, const Number* b): a_(a), b_(b) {}

string DivNumber::ToString() const {
  stringstream out;
  out << "(" << a_->ToString() << ")/(" << b_->ToString() << ")";
  return out.str();
}

const Number* DivNumber::Copy() const {
  return new DivNumber(a_->Copy(), b_->Copy());
}

Number::SignType DivNumber::GetSign() const{
  return SignTimes(a()->GetSign(), b()->GetSign());
}

const Number* Minus(const Number* a, const Number* b) {
  return new AddNumber(a, new MulNumber(new RationalNumber(-1, 1), b));
}

const Number* DivNumber::GetSimplify() const {
  unique_ptr<const Number> sa(a()->Simplify());
  unique_ptr<const Number> sb(b()->Simplify());
  //cout << "DIV1 " << sa->ToString() << "\n";
  //cout << "DIV2 " << sb->ToString() << "\n";
  if (sa->type() == NumberType::RATIONAL &&
      sb->type() == NumberType::RATIONAL) {
    auto ra = dynamic_cast<const RationalNumber*>(sa.get());
    auto rb = dynamic_cast<const RationalNumber*>(sb.get());
    mpz_class den = ra->den()*rb->num();
    int sign = den < 0 ? -1 : 1;
    unique_ptr<Number> sum(new RationalNumber(
        ra->num()*rb->den()*sign, den*sign));
    return sum->Simplify();	
  } 
  if (sa->type() == NumberType::ADD) {
    auto ra = dynamic_cast<const AddNumber*>(sa.get());
    unique_ptr<Number> ans(new AddNumber(new DivNumber(ra->a()->Simplify(),
						       sb->Simplify()),
                                         new DivNumber(ra->b()->Simplify(),
						       sb->Simplify())));
    return ans->Simplify();
  }
  if (sb->type() == NumberType::ADD) {
    auto rb = dynamic_cast<const AddNumber*>(sb.get());
    unique_ptr<Number> ans(
        new DivNumber(new MulNumber(sa->Simplify(),
	                            Minus(rb->a()->Simplify(),
				          rb->b()->Simplify())),
		      Minus(Square(rb->a()),
		            Square(rb->b()))));
    return ans->Simplify();
  }
  if (sa->type() == NumberType::SQRT) {
    auto ra = dynamic_cast<const SqrtNumber*>(sa.get());
    auto signa = sa->GetSign();
    auto signb = sb->GetSign();
    auto signx = SignTimes(signa, signb);
    unique_ptr<Number> ans(new SqrtNumber(
        new DivNumber(ra->x()->Simplify(), Square(sb.get())),
	signx != Number::NEGATIVE));
    return ans->Simplify();	
  }
  if (sb->type() == NumberType::SQRT) {
    auto rb = dynamic_cast<const SqrtNumber*>(sb.get());
    auto signa = sa->GetSign();
    auto signb = sb->GetSign();
    auto signx = SignTimes(signa, signb);
    unique_ptr<Number> ans(new SqrtNumber(
        new DivNumber(Square(sa.get()), rb->x()->Simplify()),
	signx != Number::NEGATIVE));
    return ans->Simplify();	
  }
  unique_ptr<Number> ans(new DivNumber(sa->Simplify(), sb->Simplify()));
  return ans->Simplify();
}

DivNumber* Div(const Number* a, const Number* b) {
  return new DivNumber(a,b);
}

SqrtNumber::SqrtNumber(const Number* x, bool sign): x_(x), sign_(sign) {}

Number::SignType SqrtNumber::GetSign() const {
  auto a = x()->GetSign();
  if (a == POSITIVE && !sign_)
    return NEGATIVE;
  return a;
}

const Number* SqrtNumber::Copy() const {
  return new SqrtNumber(x_->Copy(), sign_);
}

string SqrtNumber::ToString() const {
  stringstream out;
  if (!sign_) out << "(-";
  out << "sqrt(" << x_->ToString() << ")";
  if (!sign_) out << ")";
  return out.str();
}

const Number* SqrtNumber::GetSimplify() const {
  unique_ptr<const Number> sx(x()->Simplify());
  //cout << "SQRT " << sx->ToString() << "\n";
  if (sx->type() == NumberType::RATIONAL) {
    auto rx = dynamic_cast<const RationalNumber*>(sx.get());
    if (square(rx->num()) && square(rx->den())) {
      int sign = sign_ ? 1 : -1;
      return new RationalNumber(sign*sqrt(rx->num()),
                                sqrt(rx->den()));
    }
  }
  return new SqrtNumber(sx->Simplify(), sign_);
}

const Number* SqrtNumber::Flip() const {
  return new SqrtNumber(x()->Simplify(), !sign_);
}

SqrtNumber* Sqrt(const Number* x) {
  return new SqrtNumber(x, true);
}

SqrtNumber* nSqrt(const Number* x) {
  return new SqrtNumber(x, false);
}

Comparator::Result Comparator::CompareModulus(const Number* a,
                                              const Number* b) {
  unique_ptr<const Number> a_squared(Square(a));
  unique_ptr<const Number> b_squared(Square(b));
  return ComparePositive(a_squared.get(), b_squared.get());
}

Comparator::Result Comparator::ComparePositive(const Number* a,
                                               const Number* b) {
  vector<const Number*> rationals;
  vector<const Number*> sqrts;
  Collect(a, true, false, rationals, sqrts);
  Collect(b, false, true, rationals, sqrts);
  unique_ptr<const Number> sum_(CollectRationals(rationals));
  if (sqrts.empty()) {
    auto sum = dynamic_cast<const RationalNumber*>(sum_.get());
    if (sum->num() == 0)
      return EQUAL;
    if (sum->num() < 0)
      return LESSER;
    else
      return GREATER;
  }
  unique_ptr<const Number> sqrt_sum_(CollectSqrts(sqrts));
  return Compare(sum_.get(), sqrt_sum_.get());
}

Comparator::Result Comparator::Compare(const Number* a, const Number* b) {
  auto a_sign = a->GetSign();
  auto b_sign = b->GetSign();
  if (a_sign == Number::ZERO)
    a_sign = Number::POSITIVE;
  if (b_sign == Number::ZERO)
    b_sign = Number::POSITIVE;
  if (a_sign == Number::NEGATIVE && b_sign == Number::POSITIVE)
    return LESSER;
  if (a_sign == Number::POSITIVE && b_sign == Number::NEGATIVE)
    return GREATER;
  if (a_sign == Number::POSITIVE && b_sign == Number::POSITIVE)
    return CompareModulus(a, b);
  auto result = CompareModulus(a, b);
  if (result == EQUAL)
    return EQUAL;
  if (result == LESSER)
    return GREATER;
  else
    return LESSER;
}
