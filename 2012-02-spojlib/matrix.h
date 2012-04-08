#include <vector>
#include <algorithm>
#include <functional>
#include <memory>

//reserve matrix rows cols id

template<typename T>
class matrix {
 public:
  typedef std::vector<T> vt;
  typedef std::vector<vt> vvt;

  matrix(int rows, int cols)
      : mat_(rows, vt(cols)),
        rows_(rows),
        cols_(cols),
        id_cache_(NULL) {
  }

  template<typename Iterator>
  matrix(int rows, int cols, Iterator data)
      : mat_(rows, vt(cols)),
        rows_(rows),
        cols_(cols),
        id_cache_(NULL) {
    for (int j = 0; j < rows; j++) {
      for (int i = 0; i < cols; i++) {
        mat_[j][i] = *data;
        ++data;
      }
    }
  }

  virtual ~matrix() {
    if (id_cache_ != NULL) {
      delete id_cache_;
    }
  }

  vt& operator[](int row) {
    return mat_[row];
  }

  const vt& operator[](int row) const {
    return mat_[row];
  }

  int rows() const {
    return rows_;
  }

  int cols() const {
    return cols_;
  }

  matrix<T> operator+(const matrix<T>& b) const {
    matrix<T> ans(rows_, cols_);
    for (int j = 0; j < rows_; j++) {
      std::transform(mat_[j].begin(), mat_[j].end(), b[j].begin(),
                     ans[j].begin(), std::plus<T>());
    }
    return ans;
  }

  matrix<T> operator*(const matrix<T>& b) const {    
    matrix<T> ans(rows_, b.cols());
    for (int j = 0; j < rows_; j++) {
      for (int i = 0; i < b.cols(); i++) {
        ans[j][i] = 0;
        for (int k = 0; k < cols_; k++) {
          ans[j][i] = ans[j][i] + mat_[j][k] * b[k][i];
        }
      }
    }
    return ans;
  }

  matrix<T> id() const {
    if (id_cache_ != NULL) {
      return *id_cache_;
    }
    id_cache_ = new matrix<T>(rows_, cols_);
    for (int i = 0; i <rows_; i++)
      (*id_cache_)[i][i] = 1;
    return *id_cache_;
  }

  template <typename S>
  matrix<T> power(S n) const {
    if (n == 0) return id();
    if (n == 1) return *this;
    matrix<T> half = power(n / 2);
    return n % 2 ? *this * half * half : half * half;
  }
  
  bool operator==(const matrix<T>& b) const {
    for (int j = 0; j < rows_; j++) {
      if (!std::equal(mat_[j].begin(), mat_[j].end(), b[j].begin())) {
        return false;
      }
    }
    return true;
  }

  bool operator!=(const matrix<T>& b) const {
    return !(*this == b);
  }

 private:
  vvt mat_;
  int rows_, cols_;
  mutable matrix<T>* id_cache_;
};
