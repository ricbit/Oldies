//reserve modint inverse

template<int M>
class modint {
 public:
  modint(int v) : value_(v < 0 ? M + v % M : v % M) {}
  modint() : value_(0) {}

  modint operator+(const modint& b) const {
    int ans = value_ + b.value_;
    return ans < M ? build(ans) : build(ans - M);
  }

  modint operator-(const modint& b) const {
    int ans = value_ - b.value_;
    return ans < 0 ? build(ans + M) : build(ans);
  }

  modint operator*(const modint& b) const {
   int ans;
   asm (
     "imull %%ebx\n\t"
     "idivl %%esi\n\t"
     : "=d" (ans)
     : "a" (value_), "b" (b.value_), "S" (M)
     :
   );
   return build(ans);
  }

  modint operator-() const {
    return modint(-value_);
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
  int value_;
  static const modint one_;

  modint build(int v) const {
    modint ans;
    ans.value_ = v;
    return ans;
  }
};

template<int M>
const modint<M> modint<M>::one_(1);
