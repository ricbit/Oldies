#include <vector>
#include <cstring>
#include <string>

template<int B>
struct P10 { static const int P = 10 * P10<B-1>::P; };

template<>
struct P10<0> { static const int P = 1; };

template <int B>
class bigint {
 public:
  static const int B10 = P10<B>::P;
  bigint(const char* p) {
    int n = strlen(p);
    size_ = (n + B - 1) / B;
    digits_.resize(size_);
    int left = n % B ? n % B : B;
    for (int index = size_ - 1; n; index--) {
      int acc = 0;
      for (n -= left; left; left--) {
        acc = acc * 10 + *p++ - '0';        
      }
      digits_[index] = acc;
      left = B;
    }
    trim();
  }
  operator std::string() const {
    if (size_ == 1 && digits_[0] == 0) {
      return "0";
    }
    std::string out;
    char str[B + 1];
    sprintf(str, "%d", digits_[size_ - 1]);
    out += str;
    char fmt[10];
    sprintf(fmt, "%%0%dd", B);
    for (int i = size_ - 2; i >= 0; i--) {
      sprintf(str, fmt, digits_[i]);
      out += str;
    }
    return out;
  }
  bool operator==(const bigint<B>& b) const {
    if (size_ != b.size_)
      return false;
    return std::equal(
        digits_.begin(), digits_.begin() + size_, b.digits_.begin());
  }
  bigint<B> operator+(const bigint<B>& b) const {
    bigint<B> ans = slice(0, 1 + std::max(size_, b.size_));
    ans.add(b, 0);
    return ans.trim();
  }
  bigint<B> operator*(const bigint<B>& b) const {
    // TODO: fix this.
    //if (std::max(size_, b.size_) > 50) {
    //  return karatsuba(b);
    //}
    bigint<B> ans;
    ans.size_ = 1 + size_ + b.size_;
    ans.digits_.resize(ans.size_);
    for (int i = 0; i < b.size_; i++) {
      int carry = 0;
      for (int j = 0; j < size_ + 1; j++) {
        carry += ans.digits_[j + i];
        divmul(get(j), b.get(i), carry, ans.digits_[j + i], carry);
     }
    }
    ans.trim();
    return ans;
  }
 private:
  bigint() {}
  int get(int i) const {
    return i >= size_ ? 0 : digits_[i];
  }
  void add(const bigint<B>& b, int shift) {
    int carry = 0;
    for (int i = 0; i + shift < size_; i++) {
      int val = get(i + shift) + b.get(i) + carry;
      digits_[i + shift] = val % B10;
      carry = val / B10;
    }
  }
  bigint<B> trim() {
    while (size_ && digits_[size_ - 1] == 0) {
      size_--;
    }
    return *this;
  }
  void divmul(int a, int b, int carry, int& outlow, int& outhigh) const {
    asm volatile (
      "imull %%ebx \n\t"
      "addl %%ecx,%%eax \n\t"
      "adcl $0, %%edx \n\t"
      "idivl %%esi \n\t"
      : "=d"(outlow), "=a"(outhigh)
      : "c"(carry), "a"(a), "b"(b), "S"(B10)
      :
    );
  }
  bigint<B> karatsuba(const bigint<B>& b) const {
    int n = std::max(size_, b.size_) / 2;
    bigint<B> a0 = slice(0, n - 1);
    bigint<B> b0 = b.slice(0, n - 1);
    bigint<B> a1 = slice(n, 2 * n);
    bigint<B> b1 = b.slice(n, 2 * n);
    bigint<B> z2 = a1 * b1;
    bigint<B> z1 = a0 * b0;
    bigint<B> z0 = a1 * b0 + a0 * b1;
    z0.add(z1, n);
    z0.add(z2, 2 * n);
    return z0.trim();
  }
  bigint<B> slice(int a, int b) const {
    bigint<B> ans;
    ans.size_ = b - a + 1;
    ans.digits_.resize(ans.size_);
    for (int i = a; i <= b; i++)
      ans.digits_[i - a] = get(i);
    return ans;
  }
  std::vector<int> digits_;
  int size_;
};

