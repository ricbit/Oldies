#include <vector>
#include <numeric>

template<typename T>
class ChineseRemainder {
 public:
  ChineseRemainder(const std::vector<T>& modules) : ei_(modules.size()) {
    T p = std::accumulate(modules.begin(), modules.end(),
                          T(1), std::multiplies<T>());
    for (unsigned i = 0; i < modules.size(); i++) {
      T si = p / modules[i];
      pii r = egcd(modules[i], si);
      ei_[i] = r.second * si;
    }
  }

  T eval(const std::vector<T>& ai) {
    return std::inner_product(ai.begin(), ai.end(), ei_.begin(), T(0));
  }

 private:
  typedef std::pair<T, T> pii;

  pii egcd(T a, T b) {
    if (b == T(0)) {
      return std::make_pair(T(1), T(0));
    } else {
      T q = a / b;
      T r = a % b;
      pii ans = egcd(b, r);
      return std::make_pair(ans.second, ans.first - q * ans.second);
    }
  }

  std::vector<T> ei_;
};

