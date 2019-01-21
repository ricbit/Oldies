#ifndef __SAVE_H
#define __SAVE_H

#include <iostream>
#include <string>
#include <vector>
#include <type_traits>

template<class T>
class save {
  T a;
  public:
  save() : a() {
  }
  save(T &&x) : a(std::move(x)) {
  }
  operator T&() {
    return a;
  }
  template<typename X>
  friend std::ostream& operator<<(
      std::ostream& os, const save<X>& dt);
  template<typename X>
  friend std::istream& operator>>(
      std::istream& is, save<X>& dt);
};

template<class X>
std::ostream& operator<<(std::ostream& os, const save<X>& dt) {
  os << dt.a;
  return os;
}

template<class X>
std::istream& operator>>(std::istream& is, save<X>& dt) {
  is >> dt.a;
  return is;
}

template<>
class save<int> {
  int a;
  public:
  save() : a() {
  }
  save(int &&x) : a(std::move(x)) {
  }
  operator int&() {
    return a;
  }
  template<typename T>
  friend std::ostream& operator<<(
      std::ostream& os, const save<T>& dt);
  template<typename X>
  friend std::istream& operator>>(
      std::istream& is, save<X>& dt);
};

template<typename T>
std::ostream& operator<<(std::ostream& os,
  typename std::enable_if<
    std::is_arithmetic<T>::value, const save<T>&>::type dt) {
  os << dt.a;
  return os;
}

template<typename T>
std::istream& operator<<(std::istream& is,
  typename std::enable_if<
    std::is_arithmetic<T>::value, save<T>&>::type dt) {
  is >> dt.a;
  return is;
}

template<>
class save<double> {
  double a;
  public:
  save() : a() {
  }
  save(double &&x) : a(std::move(x)) {
  }
  operator double&() {
    return a;
  }
  template<typename T>
  friend std::ostream& operator<<(
      std::ostream& os, const save<T>& dt);
  template<typename X>
  friend std::istream& operator>>(
      std::istream& is, save<X>& dt);
};

template<typename T>
class save<std::vector<T>> {
  std::vector<T> a;
  public:
  save() : a() {
  }
  save(std::vector<T> &&x) : a(std::move(x)) {
  }
  operator std::vector<T>&() {
    return a;
  }
  auto size() const -> decltype(a.size()) {
    return a.size();
  }
  auto begin() const -> decltype(a.begin()) {
    return a.begin();
  }
  auto end() const -> decltype(a.end()) {
    return a.end();
  }
  template<typename X>
  friend std::ostream& operator<<(
      std::ostream& os, const save<std::vector<X>>& dt);
  template<typename X>
  friend std::istream& operator>>(
      std::istream& is, save<std::vector<X>>& dt);
};

template<typename T>
std::ostream& operator<<(std::ostream& os, const save<std::vector<T>>& v) {
  os << v.a.size() << ' ';
  for (const T &e : v.a) {
    os << e << ' ';
  }
  return os;
}

template<typename T>
std::istream& operator>>(std::istream& is, save<std::vector<T>>& v) {
  int size;
  is >> size;
  v.a.resize(size);
  for (T &e : v.a) {
    is >> e;
  }
  return is;
}

template<typename T>
class save<T*> {
  T* a;
  public:
  save() : a() {
  }
  save(T* &&x) : a(std::move(x)) {
  }
  operator T*() {
    return a;
  }
  template<typename X>
  friend std::ostream& operator<<(
      std::ostream& os, const save<X*>& dt);
  template<typename X>
  friend std::istream& operator>>(
      std::istream& is, save<X*>& dt);
};

template<typename X>
std::ostream& operator<<(std::ostream& os, const save<X*>& dt) {
  os << *dt.a;
  return os;
}

template<typename X>
std::istream& operator>>(std::istream& is, save<X*>& dt) {
  dt.a = new X();
  is >> *dt.a;
  return is;
}

class serializer {
 public:
  virtual void serialize(std::string filename) = 0;
  virtual void deserialize(std::string filename) = 0;
};

#endif
