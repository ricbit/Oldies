// Exact Cover solution using Dancing Links
// Ricardo Bittencourt 2008

#include <limits>
#include <vector>

struct node {
  int size, name;
  node *left, *right, *up, *down, *top;
  node(): size(0) {}
};

typedef vector<bool> vb;
typedef vector<vb> vvb;

struct count_solutions {
  int total;
  count_solutions(): total(0) {}
  void operator()(const vector<int>& solution) {
    total++;
  }
};

template<typename T>
struct _exactcover {
  int w, h;
  T& callback;
  vector<int> solution;
  node *root;

  _exactcover(const vvb& mat, T& callback_)
      : w(mat[0].size()), h(mat.size()), callback(callback_)
  {
    root = getnode();
    root->left = root;
    root->right = root;
    root->name = -1000000;
    vector<node*> head(w);
    for (int i = 0; i < w; i++) {
      node* next = head[i] = getnode();
      next->right = root;
      next->left = root->left;
      root->left = next;
      next->left->right = next;
      next->up = next;
      next->down = next;
      next->name = -i-1;
    }
    for (int i = 0; i < h; i++) {
      node* root = NULL;
      for (int j = 0; j < w; j++) {
        if (mat[i][j]) {
          node* current;
          if (root == NULL) {
            current = root = getnode();
            root->left = root;
            root->right = root;
          } else {
            node* next = current = getnode();
            next->right = root;
            next->left = root->left;
            root->left = next;
            next->left->right = next;
          }
          current->down = head[j];
          current->up = head[j]->up;
          head[j]->up = current;
          current->up->down = current;
          current->top = head[j];
          current->name = i;
          head[j]->size++;
        }
      }
    }
  }

  node* getnode() {
    return new node;
  }

  void cover(node* col) {
    col->right->left = col->left;
    col->left->right = col->right;
    for (node* i = col->down; i != col; i = i->down) {
      for (node* j = i->right; j != i; j = j->right) {
        j->down->up = j->up;
        j->up->down = j->down;
        j->top->size--;
      }
    }
  }

  void uncover(node* col) {
    for (node* i = col->up; i != col; i = i->up) {
      for (node* j = i->left; j != i; j = j->left) {
        j->top->size++;
        j->up->down = j;
        j->down->up = j;
      }
    }
    col->right->left = col;
    col->left->right = col;
  }

  void solve(void) {
    if (root->right == root) {
      callback(solution);
      return;
    }

    int minvalue = numeric_limits<int>::max();
    node* mincol = root;
    for (node* n = root->right; n != root; n = n->right) {
      if (n->size < minvalue) {
        minvalue = n->size;
        mincol = n;
      }
    }
    if (minvalue == 0)
      return;

    cover(mincol);
    for (node* r = mincol->down; r != mincol; r = r->down) {
      for (node* j = r->right; j != r; j = j->right)
        cover(j->top);
      solution.push_back(r->name);
      solve();
      solution.pop_back();
      for (node* j = r->left; j != r; j = j->left)
        uncover(j->top);
    }
    uncover(mincol);
  }

};

template<class T>
void exactcover(const vvb& mat, T& callback) {
  _exactcover<T> cover(mat, callback);
  cover.solve();
}
