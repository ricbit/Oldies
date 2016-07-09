#include <cassert>
#include <iostream>
#include "bdd.h"

NodeFactory::NodeFactory(int size, int max_level)
    : size_(size),
      max_level_(max_level),
      next_available_(1),
      double_node_(size / 2) {
  assert(size % 2 == 0);
  assert(max_level < 255);
}

// Layout:
// 8: name, 28: high, 28: low
// 1: marked, 28: aux

static inline uint64 mask(int bits) {
  return (1ULL << bits) - 1;
}

uint64& NodeFactory::get_pointer(Node node) {
  assert(node.address < size_);
  DoubleNode& dnode = double_node_[node.address / 2];
  return node.address & 1 ? dnode.pointer1 : dnode.pointer0;
}

uint64& NodeFactory::get_aux(Node node) {
  assert(node.address < size_);
  DoubleNode& dnode = double_node_[node.address / 2];
  return dnode.aux;
}

int NodeFactory::get_bits(uint64& container, int start, int bits) {
  return (container >> start) & mask(bits);
}

void NodeFactory::set_bits(uint64& container, int start, int bits, int value) {
  assert(value < (1 << bits));
  container &= ~(mask(bits) << start);
  container |= static_cast<uint64>(value) << start;
}

Node NodeFactory::low(Node node) {
  return Node(get_bits(get_pointer(node), 0, 28));
}

void NodeFactory::set_low(Node node, Node low) {
  set_low(node, low.address);
}

void NodeFactory::set_low(Node node, int low) {
  set_bits(get_pointer(node), 0, 28, low);
}

Node NodeFactory::high(Node node) {
  return Node(get_bits(get_pointer(node), 28, 28));
}

void NodeFactory::set_high(Node node, Node high) {
  set_high(node, high.address);
}

void NodeFactory::set_high(Node node, int high) {
  set_bits(get_pointer(node), 28, 28, high);
}

bool NodeFactory::value(Node node) {
  assert(is_terminal(node));
  return static_cast<bool>(high(node).address);
}

int NodeFactory::name(Node node) {
  return get_bits(get_pointer(node), 28 * 2, 8);
}

void NodeFactory::set_name(Node node, int name) {
  set_bits(get_pointer(node), 28 * 2, 8, name);
}

int NodeFactory::base_aux(Node node) {
  return node.address & 1 ? 32 : 0;
}

int NodeFactory::aux(Node node) {
  uint64& aux_field = get_aux(node);
  int start = base_aux(node);
  return get_bits(aux_field, start, 28);
}

bool NodeFactory::marked(Node node) {
  uint64& aux_field = get_aux(node);
  int start = base_aux(node) + 28;
  return static_cast<bool>(get_bits(aux_field, start, 1));
}

void NodeFactory::set_aux(Node node, int value) {
  uint64& aux_field = get_aux(node);
  int start = base_aux(node);
  set_bits(aux_field, start, 28, value);
}

void NodeFactory::set_marked(Node node, bool value) {
  uint64& aux_field = get_aux(node);
  int start = base_aux(node) + 28;
  set_bits(aux_field, start, 1, static_cast<int>(value));
}

void NodeFactory::set_terminal(Node node, bool value) {
  set_name(node, max_level_);
  set_low(node, 0);
  set_high(node, static_cast<int>(value));
}

bool NodeFactory::is_terminal(Node node) {
  return low(node).address == 0;
}

Node NodeFactory::create() {
  Node node;
  //cout << "create\n";
  if (available_.empty()) {
    assert(next_available_ <= size_);
    node.address = next_available_++;
  } else {
    node.address = available_.top();
    available_.pop();
  }
  set_name(node, 0);
  set_marked(node, false);
  return node;
}

void NodeFactory::remove(Node node) {
  if (name(node) != 0xFF)
    available_.push(node.address);
  set_name(node, 0xFF);
}

int NodeFactory::max_level() {
  return max_level_;
}

string NodeFactory::dump() {
  ostringstream oss;
  for (int i = 0; i < next_available_; i++) {
    Node n(i);
    if (name(n) != 0xFF) {
      oss << "node "  << i
          << " name: " << name(n)
          << " low: " << low(n).address
          << " high: " << high(n).address
          << " aux: " << aux(n)
          << " marked: " << marked(n)
          << endl;
    }
  }
  return oss.str();
}

int NodeFactory::active_nodes() {
  return next_available_ - available_.size();
}

Reducer::Reducer(NodeFactory& node)
    : node_(node),
      level_(node.max_level() + 1),
      current_(2) {
}

static uint64 gen_key(int name, int low, int high) {
  uint64 key = static_cast<uint64>(name) << (28 * 2);
  key |= static_cast<uint64>(low) << 28;
  key |= static_cast<uint64>(high);
  return key;
}

uint64 Reducer::key(int name, int low, int high) {
  return gen_key(name, low, high);
}

Node Reducer::reduce(Node root) {
  // Fill level.
  bool marked;
  traverse_preorder(node_, root, [&](NodeFactory& node, Node n) {
    level_[node.name(n)].push_back(n);
    marked = node.marked(n);
  });

  // Terminals.
  vector<Node> terminal(2);
  for (int i = 0; i < 2; i++) {
    terminal[i] = node_.create();
    node_.set_terminal(terminal[i], static_cast<bool>(i));
    node_.set_aux(terminal[i], i);
    node_.set_marked(terminal[i], marked);
    index_.push_back(terminal[i]);
    unique_[key(node_.max_level(), i, i)] = terminal[i];
  }
  vector<bool> used(2, false);
  for (auto &n : level_[node_.max_level()]) {
    int value = static_cast<int>(node_.value(n));
    node_.set_aux(n, value);
    used[value] = true;
    delete_list_.push_back(n);
  }
  for (int i = 0; i < 2; i++) {
    if (!used[i])
      delete_list_.push_back(terminal[i]);
  }

  // Non-terminals.
  for (int i = node_.max_level() - 1; i >= 0; i--) {
    //cout << " index " << i << endl;
    for (auto &n : level_[i]) {
      Node low = node_.low(n);
      Node high = node_.high(n);
      node_.set_marked(n, marked);
      if (node_.aux(low) == node_.aux(high)) {
        node_.set_aux(n, node_.aux(low));
        delete_list_.push_back(n);
        continue;
      } 
      uint64 k = key(node_.name(n), node_.aux(low), node_.aux(high));
      auto cached = unique_.find(k);
      if (cached == unique_.end()) {
        /*cout << "node " << n.address << " name " << node_.name(n) 
             << " auxlow " << node_.aux(low)
             << " auxhigh " << node_.aux(high)
 	     << endl;*/
        node_.set_aux(n, current_++);
        unique_[k] = n;
        index_.push_back(n);
      } else {
        delete_list_.push_back(n);
        node_.set_aux(n, node_.aux(cached->second));
      }
      node_.set_low(n, index_[node_.aux(low)]);
      node_.set_high(n, index_[node_.aux(high)]);
    }
  }

  // Find new root.
  Node out = root;
  while (!node_.is_terminal(out) &&
         node_.aux(node_.low(out)) == node_.aux(node_.high(out))) {
    out = node_.low(out);
  }

  // Remove unused nodes.
  for (auto &n : delete_list_) {
    node_.remove(n);
  }
  return out;
}

Node reduce(NodeFactory& node, Node n) {
  Reducer r(node);
  return r.reduce(n);
}

void delete_bdd(NodeFactory& node, Node root) {
  traverse_postorder(node, root, [&](NodeFactory& node, Node n) {
    node.remove(n);
  });
}

BDDMinterm::BDDMinterm(NodeFactory& node)
    : node_(node),
      terminal_(2) {
}

Node BDDMinterm::build(const vector<int>& name, const vector<bool>& negate) {
  for (int i = 0; i < 2; i++) {
    terminal_[i] = node_.create();
    node_.set_terminal(terminal_[i], static_cast<bool>(i));
  }
  return next(name, negate, 0);
}

Node BDDMinterm::next(const vector<int>& name,
                      const vector<bool>& negate,
                      int i) {
  if (i == static_cast<int>(name.size()))
    return terminal_[1];
  Node n = node_.create();
  node_.set_name(n, name[i]);
  node_.set_low(n, terminal_[0]);
  node_.set_high(n, terminal_[0]);
  Node x = next(name, negate, i + 1);
  if (negate[i])
    node_.set_low(n, x);
  else
    node_.set_high(n, x);
  return n;
}

Node apply_and(NodeFactory& node, Node a, Node b) {
  return apply(node, a, b, [](bool a, bool b) {
    return a && b;
  });
}

Node apply_or(NodeFactory& node, Node a, Node b) {
  return apply(node, a, b, [](bool a, bool b) {
    return a || b;
  });
}

ZDDCache::ZDDCache(NodeFactory& node)
    : node_(node) {
  base_ = node_.create();
  node_.set_terminal(base_, true);
  empty_ = node_.create();
  node_.set_terminal(empty_, false);
}

Node ZDDCache::get_base() {
  return base_;
}

Node ZDDCache::get_empty() {
  return empty_;
}

uint64 ZDDCache::key(int name, Node low, Node high) {
  return gen_key(name, low.address, high.address);
}

Node ZDDCache::get_node(int name, Node a, Node b) {
  if (b.address == empty_.address)
    return a;
  auto k = key(name, a, b);
  auto cached = cache_.find(k);
  if (cached != cache_.end())
    return cached->second;
  Node n = node_.create();
  node_.set_name(n, name);
  node_.set_low(n, a);
  node_.set_high(n, b);
  cache_[k] = n;
  return n;
}

NodeFactory& ZDDCache::node() {
  return node_;
}

Node zdd_change(ZDDCache& cache, Node root, int name) {
  int root_name = cache.node().name(root);
  Node low = cache.node().low(root);
  Node high = cache.node().high(root);
  if (root_name > name)
    return cache.get_node(name, cache.get_empty(), root);
    //return root;
  if (root_name == name)
    return cache.get_node(name, high, low);
  return cache.get_node(root_name, 
                        zdd_change(cache, low, name),
                        zdd_change(cache, high, name));
}

ZDDUnion::ZDDUnion(ZDDCache& cache)
    : cache_(cache),
      node_(cache_.node()) {
}

Node ZDDUnion::get_union(Node a, Node b) {
  if (a.address == cache_.get_empty().address)
    return b;
  if (b.address == cache_.get_empty().address)
    return a;
  if (a.address == b.address)
    return a;
  int k = gen_key(0, a.address, b.address);
  //auto cached = memo_.find(k);
  //if (cached != memo_.end())
  //  return cached->second;
  int a_name = node_.name(a);
  int b_name = node_.name(b);
  Node ans;
  if (a_name < b_name) {
    ans = cache_.get_node(a_name,
                          get_union(node_.low(a), b),
                          node_.high(a));
  } else if (a_name > b_name) {
    ans = cache_.get_node(b_name,
                          get_union(a, node_.low(b)),
                          node_.high(b));
  } else {
    ans = cache_.get_node(
        a_name, 
        get_union(node_.low(a), node_.low(b)),
        get_union(node_.high(a), node_.high(b)));
  }
  cerr << k << ":" << ans.address << endl;
  memo_[k] = ans;
  return ans;
}

Node zdd_union(ZDDCache& cache, Node a, Node b) {
  ZDDUnion zdd(cache);
  return zdd.get_union(a, b);
}

ZDDInter::ZDDInter(ZDDCache& cache)
    : cache_(cache),
      node_(cache_.node()) {
}

Node ZDDInter::get_inter(Node a, Node b) {
  if (a.address == cache_.get_empty().address)
    return cache_.get_empty();
  if (b.address == cache_.get_empty().address)
    return cache_.get_empty();
  if (a.address == b.address)
    return a;
  int k = gen_key(0, a.address, b.address);
  if (memo_.find(k) != memo_.end())
    return memo_[k];
  int a_name = node_.name(a);
  int b_name = node_.name(b);
  Node ans;
  if (a_name < b_name) {
    ans = get_inter(node_.low(a), b);
  } else if (a_name > b_name) {
    ans = get_inter(a, node_.low(b));
  } else {
    ans = cache_.get_node(
        a_name, 
        get_inter(node_.low(a), node_.low(b)),
        get_inter(node_.high(a), node_.high(b)));
  }
  memo_[k] = ans;
  return ans;
}

Node zdd_inter(ZDDCache& cache, Node a, Node b) {
  ZDDInter zdd(cache);
  return zdd.get_inter(a, b);
}
