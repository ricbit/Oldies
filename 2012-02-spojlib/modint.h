//reserve modint inverse

#ifdef VARMOD
unsigned M = 2;
#else
template<unsigned M> // works only for 1 <= M <= 0x7FFFFFFF
#endif
class modint {
 public:
  modint(unsigned v) : value_(v % M) {}
  modint(int v) : value_(v < 0 ? M + v % int(M) : v % M) {}
  modint() : value_(0) {}

  modint operator+(const modint& b) const {
    unsigned ans = value_ + b.value_;
    return ans < M ? build(ans) : build(ans - M);
  }

  modint& operator+=(const modint& b) {
    value_ += b.value_;
    if (value_ >= M) {
      value_ -= M;
    }
    return *this;
  }

  modint operator-(const modint& b) const {
    unsigned ans = value_ - b.value_;
    return ans > value_ ? build(ans + M) : build(ans);
  }

  modint operator*(const modint& b) const {
    unsigned ans,dummy;
    asm (
      "imull %%ebx\n\t"
      "idivl %%esi\n\t"
      : "=d" (ans), "=a" (dummy)
      : "1" (value_), "b" (b.value_), "S" (M)
      : "cc" 
    );
    return build(ans);
  }

  modint operator-() const {
    return modint(M - value_);
  }

  template<typename T>
  modint power(T n) const {
    if (n == 0) {
      return one_;
    }
    modint half = power(n / 2);
    if (n % 2) {
      return half * half * build(value_);
    } else {
      return half * half;
    }
  }

  modint inverse() const {
    return power(M - 2); // only for M prime!
  }

  operator int() const {
    return value_;
  }

 private:
  unsigned value_;
  static const modint one_;

  modint build(int v) const {
    modint ans;
    ans.value_ = v;
    return ans;
  }
};

#ifdef VARMOD
const modint modint::one_(1);
#else
template<unsigned M>
const modint<M> modint<M>::one_(1);
#endif

