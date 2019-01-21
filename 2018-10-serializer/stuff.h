#ifndef __STUFF_H
#define __STUFF_H

#include <iostream>
#include <string>
#include <vector>
#include "save.h"
#include "stuff.h"

struct stuff : public serializer {
  save<int> a;
  save<double> b;
  save<std::string> c;
  save<int*> d;
  save<std::vector<int>> e;

  void serialize(std::string filename);
  void deserialize(std::string filename);
};

#endif
