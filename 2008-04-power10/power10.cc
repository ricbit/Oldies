#include <cstdio>
#include <cstdlib>
#include <limits>
#include <functional>

using namespace std;

unsigned long long rdtsc (void) {
  unsigned int low, high;
  asm volatile ("rdtsc": "=a"(low), "=d"(high));
  return (static_cast<unsigned long long>(high) << 32) | low;
}

unsigned long long simple_power10(unsigned long long i) {
  unsigned long long current = 10000000000000000000ULL;
  while (true) {
    if (current <= i)
      return current + !current;
    current /= 10;
  }
}

template<class T, const int n>
struct p10 {
  const static T value = T(10) * p10<T, n-1>::value;
};

template<class T>
struct p10<T, 0> {
  const static T value = T(1);
};

template<class T, const int start, const int len>
struct compare10 {
  static T compare(const T x) {
    if (x >= p10<T, start + len/2>::value)
      return compare10<T, start + len/2, len/2>::compare(x);
    else
      return compare10<T, start, len/2>::compare(x);
  }
};

template<class T, const int start>
struct compare10<T, start, 1> {
  static T compare(const T x) {
    return p10<T, start>::value;
  }
};

template<class T>
T template_power10(T x) {
  return compare10<T, 0, numeric_limits<T>::digits10>::compare(x);
}

double old_random(void) {
  return static_cast<double>(rand()) / RAND_MAX;
}

template<class T, class R>
T generic_random(R callback) {
  return static_cast<T>(callback(old_random()) * numeric_limits<T>::max());
}

double identity(double x) {
  return x;
}

template<class T>
unsigned long long test(T callback) {
  unsigned long long start = rdtsc();
  for (int i = 0; i < 1000000; i++)
    callback(generic_random<unsigned long long>(ptr_fun(identity)));
  return rdtsc() - start;
}

int main(void) {
  printf ("naive, uniform %lld\n",
          test(ptr_fun(simple_power10)));
  printf ("template, uniform %lld\n",
          test(ptr_fun(template_power10<unsigned long long>)));
  return 0;
}
