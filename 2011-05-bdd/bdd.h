#include <iostream>
#include <vector>
#include <stack>
#include <sstream>
#include <string>
#include <unordered_map>
#include <map>

using namespace std;

typedef unsigned long long int uint64;

struct DoubleNode {
  uint64 pointer0;
  uint64 pointer1;
  uint64 aux;
};

struct Node {
  Node() : address(0) {}
  explicit Node(int x) : address(x) {}
  int address;
};

class NodeFactory {
 public:
  NodeFactory(int size, int max_level);
  Node low(Node node);
  Node high(Node node);
  int aux(Node node);
  bool marked(Node node);
  int name(Node node);
  bool value(Node node);
  int max_level();
  void set_low(Node node, Node low);
  void set_high(Node node, Node high);
  void set_name(Node node, int name);
  void set_aux(Node node, int value);
  void set_marked(Node node, bool value);
  void set_terminal(Node node, bool value);
  bool is_terminal(Node node);
  Node create();
  void remove(Node node);
  int active_nodes();
  string dump();
 private:
  uint64& get_pointer(Node node);
  uint64& get_aux(Node node);
  int get_bits(uint64& container, int start, int bits);
  void set_bits(uint64& container, int start, int bits, int value);
  void set_low(Node node, int low);
  void set_high(Node node, int high);
  int base_aux(Node node);

  int size_;
  int max_level_;
  int next_available_;
  vector<DoubleNode> double_node_;
  stack<int> available_;
};

template<class Equation>
class BDDExaustive {
 public:
  BDDExaustive(NodeFactory& node, Equation equation);
  Node build();
 private:
  Node build_node(int level, bool value);

  NodeFactory& node_;
  vector<bool> params_;
  Equation equation_;
};

template<typename Labeler>
class BDDPrinter {
 public:
  BDDPrinter(NodeFactory& node, Labeler labeler);
  string print(Node n);
 private:
  NodeFactory& node_;
  Labeler labeler_;
  ostringstream oss_;
};

class Reducer {
 public:
  Reducer(NodeFactory& node);
  Node reduce(Node root);
 private:
  uint64 key(int name, int low, int high);

  NodeFactory& node_;
  vector<vector<Node>> level_;
  int current_;
  unordered_map<uint64, Node> unique_;
  vector<Node> index_;
  vector<Node> delete_list_;
};

template<class Operation>
class Apply {
 public:
  Apply(NodeFactory& node, Operation operation); 
  Node apply(Node a, Node b);
 private:
  Node apply_node(Node a, Node b);
  uint64 key(Node a, Node b);

  NodeFactory& node_;
  Operation operation_;
  unordered_map<uint64, Node> cache_;
};

class BDDMinterm {
 public:
  BDDMinterm(NodeFactory& node);
  Node build(const vector<int>& name, const vector<bool>& negate);
 private:
  Node next(const vector<int>& name, const vector<bool>& negate, int i);

  NodeFactory& node_;
  vector<Node> terminal_;
};

class ZDDCache {
 public:
  ZDDCache(NodeFactory& node);
  Node get_empty();
  Node get_base();
  Node get_node(int name, Node a, Node b);
  NodeFactory& node();
 private:
  uint64 key(int name, Node a, Node b);

  NodeFactory& node_;
  Node empty_, base_;
  unordered_map<uint64, Node> cache_;
};

class ZDDUnion {
 public:
  ZDDUnion(ZDDCache& cache);
  Node get_union(Node a, Node b);
 private:
  ZDDCache& cache_;
  NodeFactory& node_;
  map<uint64, Node> memo_;
};

class ZDDInter {
 public:
  ZDDInter(ZDDCache& cache);
  Node get_inter(Node a, Node b);
 private:
  ZDDCache& cache_;
  NodeFactory& node_;
  unordered_map<uint64, Node> memo_;
};

Node zdd_change(ZDDCache& cache, Node root, int name);
Node zdd_union(ZDDCache& cache, Node a, Node b);
Node zdd_inter(ZDDCache& cache, Node a, Node b);

template<typename Processor>
void traverse_preorder(NodeFactory& node, Node n, Processor processor) {
  node.set_marked(n, !node.marked(n));
  processor(node, n);
  if (!node.is_terminal(n)) {
    if (node.marked(n) != node.marked(node.low(n)))
      traverse_preorder<Processor>(node, node.low(n), processor);
    if (node.marked(n) != node.marked(node.high(n)))
      traverse_preorder<Processor>(node, node.high(n), processor);
  }
}

template<typename Processor>
void traverse_postorder(NodeFactory& node, Node n, Processor processor) {
  node.set_marked(n, !node.marked(n));
  if (!node.is_terminal(n)) {
    if (node.marked(n) != node.marked(node.low(n)))
      traverse_postorder<Processor>(node, node.low(n), processor);
    if (node.marked(n) != node.marked(node.high(n)))
      traverse_postorder<Processor>(node, node.high(n), processor);
  }
  processor(node, n);
}

template<class Equation>
BDDExaustive<Equation>::BDDExaustive(
    NodeFactory& node, Equation equation)
    : node_(node),
      params_(node.max_level()),
      equation_(equation) {
}

template<class Equation>
Node BDDExaustive<Equation>::build() {
  Node root = node_.create();
  node_.set_name(root, 0);
  node_.set_low(root, build_node(0, false));
  node_.set_high(root, build_node(0, true));
  return root;
}

template<class Equation>
Node BDDExaustive<Equation>::build_node(int level, bool value) {
  params_[level] = value;
  Node n = node_.create();
  if (level == node_.max_level() - 1) {
    node_.set_terminal(n, equation_(params_));
    node_.set_name(n, level + 1);
  } else {
    node_.set_low(n, build_node(level + 1, false));
    node_.set_high(n, build_node(level + 1, true));
    node_.set_name(n, level + 1);
  }
  return n;
}

template<class Equation>
Node build_exaustive(NodeFactory& node, Equation equation) {
  BDDExaustive<Equation> bdd(node, equation);
  return bdd.build();
}

template<class Operation>
Apply<Operation>::Apply(NodeFactory& node, Operation operation)
    : node_(node),
      operation_(operation) {
}

template<class Operation>
Node Apply<Operation>::apply(Node a, Node b) {
  Node n = apply_node(a, b);
  //cout << "bug\n";
  Reducer r(node_);
  return r.reduce(n);
}

template<class Operation>
uint64 Apply<Operation>::key(Node a, Node b) {
  return (static_cast<uint64>(a.address) << 28) |
         static_cast<uint64>(b.address);
}

template<class Operation>
Node Apply<Operation>::apply_node(Node a, Node b) {
  //cout << "a: " << a.address << " b: " << b.address << endl;
  uint64 k = key(a, b);
  auto cached = cache_.find(k);
  if (cached != cache_.end()) {
    //cout << "cached\n";
    return cached->second;
  }
  Node n = node_.create();
  if (node_.is_terminal(a) && node_.is_terminal(b)) {
    //cout << "terminal a: " << a.address << " b: " << b.address << endl;
    node_.set_terminal(n, operation_(node_.value(a), node_.value(b)));
    cache_[k] = n;
    return n;
  }
  if (node_.name(a) == node_.name(b)) {
    //cout << "equal name a: " << a.address << " b: " << b.address << endl;
    node_.set_name(n, node_.name(a));
    node_.set_low(n, apply_node(node_.low(a), node_.low(b)));
    node_.set_high(n, apply_node(node_.high(a), node_.high(b)));
    cache_[k] = n;
    return n;
  }
  int name;
  Node al, ah, bl, bh;
  if (node_.name(a) > node_.name(b)) {
    al = a; ah = a;
    bl = node_.low(b); bh = node_.high(b);
    name = node_.name(b);
  } else {
    al = node_.low(a); ah = node_.high(a);
    bl = b; bh = b;
    name = node_.name(a);
  }
  node_.set_name(n, name);
  node_.set_low(n, apply_node(al, bl));
  node_.set_high(n, apply_node(ah, bh));
  cache_[k] = n;
  return n;
}

template<class Operation>
Node apply(NodeFactory& node, Node a, Node b, Operation operation) {
  //cout << node.dump();
  Apply<Operation> apply(node, operation);
  return apply.apply(a, b);
}

template<typename Labeler>
BDDPrinter<Labeler>::BDDPrinter(NodeFactory& node, Labeler labeler)
    : node_(node),
      labeler_(labeler) {
}

template<typename Labeler>
string BDDPrinter<Labeler>::print(Node n) {
  oss_ << "digraph name {\n";
  // This is a hack.
  ostringstream& oss = oss_;
  Labeler& labeler = labeler_;
  // Nodes.
  traverse_preorder(node_, n, [&](NodeFactory& node, Node n) {
    if (node.is_terminal(n))
      return;
    oss << "a" << n.address << "[label=\"";
    oss << labeler(node, n) << "\"];\n";
    if (node.is_terminal(node.low(n))) {
      oss << "b" << n.address << "a0 [label=\""
          << node.value(node.low(n)) << "\", shape=box];\n";
    }
    if (node.is_terminal(node.high(n))) {
      oss << "b" << n.address << "a1 [label=\""
           << node.value(node.high(n)) << "\", shape=box];\n";
    }
  });

  // Edges.
  traverse_preorder(node_, n, [&](NodeFactory& node, Node n) {
    if (!node.is_terminal(n)) {
      if (node.is_terminal(node.low(n))) {
        oss << "a" << n.address << " -> b" << n.address
	    << "a0 [style=dotted];\n";
      } else {
        oss << "a" << n.address << " -> a" << node.low(n).address
	    << " [style=dotted];\n";
      }
      if (node.is_terminal(node.high(n))) {
        oss << "a" << n.address << " -> b" << n.address 
            << "a1;\n";
      } else {
        oss << "a" << n.address << " -> a" << node.high(n).address  << ";\n";
      }
    }
  });
  oss_ << "}\n";
  return oss_.str();
}                                                                      

Node reduce(NodeFactory& node, Node n);

void delete_bdd(NodeFactory& node, Node root);

Node apply_and(NodeFactory& node, Node a, Node b);

Node apply_or(NodeFactory& node, Node a, Node b);

template<typename Labeler>
string print(NodeFactory& node, Node root, Labeler labeler) {
  BDDPrinter<Labeler> printer(node, labeler);
  return printer.print(root);
}
