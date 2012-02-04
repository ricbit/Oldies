template<int M>
class modint {
 public:
  modint() : value_(0) {}
  modint(int v) : value_(v < 0 ? M + v % M : v % M) {}

  modint<M> operator+(const modint<M>& b) const {
    return build((value_ + b.value_) % M);
  }

  modint<M> operator*(const modint<M>& b) const {
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

  modint<M> operator-() const {
    return modint<M>(-value_);
  }

  template<typename T>
  modint<M> power(T n) const {
    if (n == 0) {
      return one_;
    }
    modint<M> half = power(n / 2);
    if (n % 2) {
      return half * half * build(value_);
    } else {
      return half * half;
    }
  }

  modint<M> inverse() const {
    return power(M - 2); // only for M prime!
  }

  int get() const {
    return value_;
  }  

 private:
  int value_;
  static const modint<M> one_;

  modint<M> build(int v) const {
    modint<M> ans;
    ans.value_ = v;
    return ans;
  }
};

template<int M>
const modint<M> modint<M>::one_(1);
