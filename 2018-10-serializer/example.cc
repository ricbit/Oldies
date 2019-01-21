#include <iostream>
#include <string>
#include <vector>
#include "save.h"
#include "stuff.h"

using namespace std;

int main() {
  int a = 2;
  stuff s;
  s.a = 3;
  s.b = 2.0;
  s.c = string("foo");
  s.d = &a;
  s.e = vector<int>{1, 2, 3};
  s.serialize("out.txt");
  
  stuff x;
  x.deserialize("out.txt");
  cout << x.a << "\n";
  cout << x.b << "\n";
  cout << x.c << "\n";
  cout << x.d << "\n";
  cout << x.e.size() << "\n";
  for (int y : x.e) {
    cout << y << "\n";
  }
  return 0;
}
