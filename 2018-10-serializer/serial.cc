#include <iostream>
#include <fstream>
void stuff::serialize(std::string f) {
  std::ofstream of(f);
  of << a;
  of << b;
  of << c;
  of << d;
  of << e;
  of.close();
}