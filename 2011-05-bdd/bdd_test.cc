#include "bdd.h"
#include <gtest/gtest.h>

using namespace std;

class BDDTest : public ::testing::Test {
 protected:
  void expectNode(int address, Node node) {
    EXPECT_EQ(address, node.address);
  }

  void deleteNode(int address, NodeFactory& factory) {
    Node node(address);
    factory.remove(node);
  }
};

TEST_F(BDDTest, CreateAndDelete) {
  NodeFactory node(20, 5);
  expectNode(1, node.create());
  expectNode(2, node.create());
  expectNode(3, node.create());
  expectNode(4, node.create());
  expectNode(5, node.create());
  deleteNode(2, node);
  deleteNode(4, node);
  expectNode(4, node.create());
  expectNode(2, node.create());
  expectNode(6, node.create());
  expectNode(7, node.create());
}

TEST_F(BDDTest, LowHighAndName) {
  NodeFactory node(20, 5);
  vector<Node> n(10);
  for (int i = 1; i < 10; i++) {
    n[i] = node.create();
    node.set_name(n[i], i);
    node.set_low(n[i], Node(i*i));
    node.set_high(n[i], Node(i*i*i));
  }
  for (int i = 1; i < 10; i++) {
    EXPECT_EQ(i, node.name(n[i]));
    EXPECT_EQ(i*i, node.low(n[i]).address);
    EXPECT_EQ(i*i*i, node.high(n[i]).address);
  }
}

TEST_F(BDDTest, AuxAndMarked) {
  NodeFactory node(20, 5);
  vector<Node> n(10);
  for (int i = 1; i < 10; i++) {
    n[i] = node.create();
    node.set_name(n[i], i);
    node.set_aux(n[i], i*i);
    node.set_marked(n[i], static_cast<bool>(i & 1));
  }
  for (int i = 1; i < 10; i++) {
    EXPECT_EQ(i, node.name(n[i]));
    EXPECT_EQ(i*i, node.aux(n[i]));
    EXPECT_EQ(static_cast<bool>(i & 1), node.marked(n[i]));
  }
}

TEST_F(BDDTest, ReduceEqualArgs) {
  NodeFactory node(80, 4);
  Node root = build_exaustive(node, [](const vector<bool>& args) {
    return args[0] == args[1] &&
           args[1] == args[2] && 
           args[2] == args[3];
  });
  Reducer r(node);
  r.reduce(root);
  EXPECT_EQ(10, node.active_nodes());
}

TEST_F(BDDTest, ReduceConstantZero) {
  NodeFactory node(80, 4);
  Node root = build_exaustive(node, [](const vector<bool>& args) {
    return false && args[0];
  });
  Reducer r(node);
  Node reduced = r.reduce(root);
  EXPECT_EQ(2, node.active_nodes());
  ASSERT_TRUE(node.is_terminal(reduced));
  EXPECT_FALSE(node.value(reduced));
}

TEST_F(BDDTest, ReduceConstantOne) {
  NodeFactory node(80, 4);
  Node root = build_exaustive(node, [](const vector<bool>& args) {
    return true || args[0];
  });
  Reducer r(node);
  Node reduced = r.reduce(root);
  EXPECT_EQ(2, node.active_nodes());
  ASSERT_TRUE(node.is_terminal(reduced));
  EXPECT_TRUE(node.value(reduced));
}

TEST_F(BDDTest, Apply) {
  NodeFactory node(80, 4);
  Node a = build_exaustive(node, [](const vector<bool>& args) {
    return args[0] == args[1];
  });
  Node b = build_exaustive(node, [](const vector<bool>& args) {
    return args[2] == args[3];
  });
  a = reduce(node, a);
  b = reduce(node, b);
  apply_or(node, a, b);
  delete_bdd(node, a);
  delete_bdd(node, b);
  EXPECT_EQ(9, node.active_nodes());
}

TEST_F(BDDTest, BDDMinterm) {
  NodeFactory node(80, 4);
  BDDMinterm bdd(node);
  vector<int> name{1, 2};
  vector<bool> negate{false, true};
  bdd.build(name, negate);
  EXPECT_EQ(5, node.active_nodes());
}
