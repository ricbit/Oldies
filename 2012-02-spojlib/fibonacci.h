#include <vector>

template<typename T>
class fibonacci {
 public:
  template<typename Q>
  fibonacci(Q maxn) {
    mat4 b(1, 1, 1, 0);
    for (Q exp = maxn - 2; exp; exp >>= 1) {
      base_.push_back(b);
      T bc = b.b * b.c;
      b.assign(b.a * b.a + bc, 
               b.b * (b.a + b.d),
               b.c * (b.a + b.d),
               b.d * b.d + bc);
    }
  }
  template<typename Q>
  T nth(Q n) {
    if (n < 2) return T(n);
    mat4 r(1, 0, 0, 1);
    int i = 0;
    for (Q exp = n - 2; exp; exp >>= 1) {
      const mat4& b = base_[i++];
      if (exp & 1) {
        r.assign(r.a * b.a + r.b * b.c,
                 r.a * b.b + r.b * b.d,
                 r.c * b.a + r.d * b.c,
                 r.c * b.b + r.d * b.d);
      }
    }
    return r.a + r.b;
  }
 private:
  struct mat4 {
    mat4(T a_, T b_, T c_, T d_) : a(a_), b(b_), c(c_), d(d_) {}

    void assign(T a_, T b_, T c_, T d_) {
      a = a_; b = b_; c = c_; d = d_;
    }

    T a, b, c, d;
  };

  std::vector<mat4> base_;
};


