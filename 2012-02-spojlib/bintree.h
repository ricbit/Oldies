// reserve BinaryTree insert traverse root left right Node

template<class T>
class BinaryTree {
 public:
  struct Node {
    T value;
    Node *left, *right;
    Node(const T& v) : value(v), left(NULL), right(NULL) {}
  };
  Node *root;
  BinaryTree() : root(NULL) {}
  void insert(const T& value) {
    Node **current = &root;
    while (*current != NULL) {
      if (value < (*current)->value)
        current = &(*current)->left;
      else
        current = &(*current)->right;
    }
    *current = new Node(value);
  }
  template<typename Q>
  void traverse(Q callback) {
    traverse_(root, callback);
  }
 private:
  template<typename Q>
  void traverse_(Node* node, Q callback) {
    if (node == NULL) return;
    callback(node->value);
    traverse_(node->left, callback);
    traverse_(node->right, callback);
  }
};


