#include <ext/numeric>
#include <functional>
#include <cmath>
#include <vector>

//reserve sieve getprimes factorize sum_of_divisors gcd totient

template<typename PrimeCallback>
std::vector<bool> sieve(int maxprime, PrimeCallback callback) {
  std::vector<bool> primes(maxprime, true);
  primes[0] = primes[1] = false;
  int i = 2;
  int maxp = static_cast<int>(sqrt(maxprime));
  for (; i <= maxp; i++) {
    if (primes[i]) {
      callback(i);
      for (int j = i * i; j < maxprime; j += i) {
        primes[j] = false;
      }
    }
  }
  if (i % 2 == 0) i++;
  for (; i < maxprime; i += 2) {
    if (primes[i]) {
      callback(i);
    }
  }
  return primes;
}

std::vector<bool> sieve(int maxprime) {
  return sieve(maxprime, __gnu_cxx::identity<int>());
}

class CapturePrimes {
 public:
  CapturePrimes(std::vector<int>& primes) : primes_(primes) {}

  void operator()(int p) {
    primes_.push_back(p);
  }

 private:
  std::vector<int>& primes_;
};

std::vector<int> getprimes(int maxprime) {
  std::vector<int> p;
  sieve(maxprime, CapturePrimes(p));
  return p;
}


void divmod(int a, int b, int& div, int& mod) {
  asm (
    "idivl %%esi\n\t"
    : "=d" (mod), "=a" (div)
    : "d" (0), "a" (a), "S" (b)
    : "cc"
  );
}

template <typename FactorCallback, typename T>
void factorize(T number, const std::vector<int>& primes,
               FactorCallback factor) {
  int maxp = static_cast<int>(sqrt(number));
  for (int i = 0; primes[i] <= maxp; i++) {
    if (number % primes[i] == 0) {
      int fac = 1;
      number /= primes[i];
      while (number % primes[i] == 0) {
        fac++;
        number /= primes[i];
      }
      factor(primes[i], fac);
    } else {
      if (number / primes[i] < primes[i]) {
        break;
      }
    }
  }
  if (number > 1) {
    factor(number, 1);
  }
}

template<typename T>
class DivisorSum {
 public:
  DivisorSum(T& acc) : acc_(acc) {
    acc_ = 1;
  }
  void operator()(int prime, int n) {
    T p(prime);
    acc_ *= (__gnu_cxx::power(p, n + 1) - 1) / (p - 1);
  }
 private:
  T& acc_;
};

template<typename T>
T sum_of_divisors(int n, const std::vector<int>& primes) {
  T ans;
  DivisorSum<T> sum(ans);
  factorize(n, primes, sum);
  return ans;
}

template<typename T>
class Totient {
 public:
  Totient(T& acc) : acc_(acc) {
    acc_ = 1;
  }
  void operator()(int prime, int n) {
    T p(prime);
    T exp = __gnu_cxx::power(p, n);
    acc_ *= exp - exp / prime;
  }
 private:
  T& acc_;
};

template<typename T>
T totient(int n, const std::vector<int>& primes) {
  T ans;
  Totient<T> tot(ans);
  factorize(n, primes, tot);
  return ans;
}

template<typename T>
T gcd(T a, T b) {
  if (b == 0) {
    return a;
  } else {
    return gcd(b, a % b);
  }
}
