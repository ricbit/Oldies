#include <vector>
#include <algorithm>
#include "gtest/gtest.h"
#include "bintree.h"

using namespace std;

struct Accumulate {
  vector<int> values;
  void operator()(const int& value) {
    values.push_back(value);
  }
};

TEST(BinarytreeTest, InsertAndTraverse) {
  BinaryTree<int> tree;
  int values[] = {3, 6, 2, 0, 8, 1, 9, 7, 4, 5};
  int sorted[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
  for (int i = 0; i < 10; i++)
    tree.insert(values[i]);
  Accumulate acc;
  tree.traverse(acc);
  EXPECT_TRUE(equal(acc.values.begin(), acc.values.end(), sorted));
}


