#include <set>
#include <cassert>
#include <iostream>
#include <algorithm>
#include "bdd.h"

template<typename Processor>
class WordPlacer {
 public:
  WordPlacer(int width, int height, const string& word, Processor processor);
  void place();
 private:
  void place_word(int pos, int sx, int sy);
  int width_;
  int height_;
  const string& word_;
  Processor processor_;
  vector<vector<char>> grid_;
  vector<vector<bool>> block_;
  vector<pair<int, int>> solution_;
  set<vector<vector<char>>> visited_;
};

template<typename Processor>
WordPlacer<Processor>::WordPlacer(
    int width, int height, const string& word, Processor processor)
    : width_(width),
      height_(height),
      word_(word),
      processor_(processor),
      grid_(width_, vector<char>(height_, '.')),
      block_(width_, vector<bool>(height_, false)),
      solution_(word_.size()) {
}

template<typename Processor>
void WordPlacer<Processor>::place_word(int pos, int sx, int sy) {
  if (sx < 0 || sy < 0 || sx >= width_ || sy >= height_)
    return;
  if (grid_[sx][sy] != '.')
    return;
  bool has_diag = false;
  int changex = 0, changey = 0;
  if (pos > 0) {
    int lastx = solution_.rbegin()->first;
    int lasty = solution_.rbegin()->second;
    if (lastx != sx && lasty != sy) { 
      changex = min(lastx, sx);
      changey = min(lasty, sy);
      if (block_[changex][changey])
        return;
      block_[changex][changey] = true;
      has_diag = true;
    }
  }
  grid_[sx][sy] = word_[pos];
  solution_[pos] = make_pair(sx, sy);
  if (pos + 1 == static_cast<int>(word_.size())) {
    if (visited_.find(grid_) == visited_.end()) {
      processor_(solution_);    
      visited_.insert(grid_);
    }
  } else {
    place_word(pos + 1, sx + 1, sy);
    place_word(pos + 1, sx - 1, sy);
    place_word(pos + 1, sx, sy + 1);
    place_word(pos + 1, sx, sy - 1);
    place_word(pos + 1, sx + 1, sy + 1);
    place_word(pos + 1, sx + 1, sy - 1);
    place_word(pos + 1, sx - 1, sy + 1);
    place_word(pos + 1, sx - 1, sy - 1);
  }
  grid_[sx][sy] = '.';
  if (has_diag)
    block_[changex][changey] = false;
}

template<typename Processor>
void WordPlacer<Processor>::place() {
  for (int i = 0; i < width_; i++) {
    for (int j = 0; j < height_; j++)
      place_word(0, i, j);
  }
}

class Solver {
 public: 
  Solver(int width, int height, const vector<string>& words,
         const vector<char>& letters);
  void solve();
 private:
  Node single_cell_minterm(int start, int negated);
  Node single_cell(int start);
  Node unique_cells();
  Node single_word(const string& word);

  int width_;
  int height_;
  const vector<string>& words_;
  vector<char> letters_;
  int num_letters_;
  NodeFactory node_;
  vector<int> inverse_letter_;
};

Solver::Solver(int width, int height, const vector<string>& words,
               const vector<char>& letters)
    : width_(width),
      height_(height),
      words_(words),
      letters_(letters),
      num_letters_(letters_.size()),
      node_(150000000, width_ * height_ * num_letters_),
      inverse_letter_(256, -1) {
}

Node Solver::single_cell_minterm(int start, int negated) {
  BDDMinterm minterm(node_);
  vector<int> name(num_letters_);
  vector<bool> negate(num_letters_);
  for (int i = 0; i < num_letters_; i++) {
    name[i] = start + i;
    negate[i] = i != negated;
  }
  return minterm.build(name, negate);
}

Node Solver::single_cell(int start) {
  Node ans = single_cell_minterm(start, 0);
  for (int i = 1; i < num_letters_; i++) {
    Node next = single_cell_minterm(start, i);
    Node join = apply_or(node_, ans, next);
    swap(ans, join);
    delete_bdd(node_, join);
    delete_bdd(node_, next);
  }
  return ans;
}

template<typename Processor>
void place(int width, int height, const string& word, Processor processor) {
  WordPlacer<Processor> placer(width, height, word, processor);
  placer.place();
}

Node Solver::unique_cells() {
  Node ans = single_cell(0);
  for (int i = 1; i < width_ * height_; i++) {
    Node next = single_cell(i * num_letters_);
    Node join = apply_and(node_, ans, next);
    swap(ans, join);
    delete_bdd(node_, join);
    delete_bdd(node_, next);
  }
  return ans;
}

Node Solver::single_word(const string& word) {
  Node ans = node_.create();
  node_.set_terminal(ans, false);
  int size = word.size();
  place(width_, height_, word, [&](vector<pair<int,int>>& solution) {
    vector<int> name(size);
    vector<bool> negate(size, false);
    for (int i = 0; i < size; i++) {
      int pos = solution[i].first + solution[i].second * width_;
      name[i] = inverse_letter_[word[i]] + pos * num_letters_; 
    }
    sort(name.begin(), name.end());
    BDDMinterm bdd(node_);
    Node next = bdd.build(name, negate);
    Node join = apply_or(node_, ans, next);
    swap(ans, join);
    delete_bdd(node_, next);
    delete_bdd(node_, join);
  });
  return ans;
}

void Solver::solve() {
  for (int i = 0; i < num_letters_; i++)
    inverse_letter_[letters_[i]] = i;
  Node ans = unique_cells();
  for (const string &word : words_) {
    Node next = single_word(word);
    Node join = apply_and(node_, ans, next);
    swap(ans, join);
    delete_bdd(node_, join);
    delete_bdd(node_, next);
  }
  cout << print(node_, ans, [&](NodeFactory& node, Node n) {
    int name = node.name(n);
    char letter = letters_[name % num_letters_];
    name /= num_letters_;
    int x = name % width_;
    int y = name / width_;
    ostringstream oss;
    oss << letter << x << y;
    return oss.str();
  });
}

class ZDDSolver {
 public: 
  ZDDSolver(int width, int height, const vector<string>& words,
            const vector<char>& letters);
  void solve();
 private:
  Node create_word_zdd(string word);
  void valid_grid();
  Node valid_cell(int x, int y);

  int width_;
  int height_;
  const vector<string>& words_;
  vector<char> letters_;
  int num_letters_;
  NodeFactory node_;
  ZDDCache cache_;
  vector<int> inverse_letter_;
  Node valid_grid_;
};

ZDDSolver::ZDDSolver(int width, int height, const vector<string>& words,
                     const vector<char>& letters)
    : width_(width),
      height_(height),
      words_(words),
      letters_(letters),
      num_letters_(letters_.size()),
      node_(150000000, width_ * height_ * num_letters_),
      cache_(node_),
      inverse_letter_(256, -1) {
  for (int i = 0; i < num_letters_; i++)
    inverse_letter_[letters_[i]] = i;
}

vector<char> eval_letters(const vector<string>& words) {
  vector<bool> letter_present(26, false);
  for (const string &word : words) {
    for (char letter : word)
      letter_present[letter - 'a'] = true;
  }
  vector<char> letters;
  for (int i = 0; i < 26; i++) {
    if (letter_present[i]) {
      letters.push_back('a' + i);
    }
  }
  return letters;
}

Node zdd_dontcare(ZDDCache cache, Node root, int name) {
  Node root1 = zdd_change(cache, root, name);
  return zdd_union(cache, root, root1);
}

Node ZDDSolver::create_word_zdd(string word) {
  Node zdd_word = cache_.get_empty();
  place(width_, height_, word, [&](vector<pair<int,int>>& solution) {
    vector<vector<char>> grid(width_, vector<char>(height_, '.'));
    for (int i = 0; i < static_cast<int>(word.size()); i++)
      grid[solution[i].first][solution[i].second] = word[i];
    /*for (int j = 0; j < height_; j++) {
      for (int i = 0; i < width_; i++) {
        cerr << grid[i][j];
      }
      cerr << endl;
    }
    cerr << endl;*/
    
    Node minterm = cache_.get_base();
    for (int i = 0; i < width_; i++) {
      for (int j = 0; j < height_; j++) {
        int pos = (i + j * width_) * num_letters_;
        if (grid[i][j] == '.') {
          for (int k = 0; k < num_letters_; k++) 
            minterm = zdd_dontcare(cache_, minterm, pos + k);
        } else {
          minterm = zdd_change(
            cache_, minterm, pos + inverse_letter_[grid[i][j]]);
        }
      }
    }
    zdd_word = zdd_union(cache_, zdd_word, minterm);
  });
  return zdd_word;
}

Node ZDDSolver::valid_cell(int x, int y) {
  Node single_cell = cache_.get_empty();
  int pos = (x + y * width_) * num_letters_;
  for (int k = 0; k < num_letters_; k++) {
    Node single_letter = cache_.get_base();
    single_letter = zdd_change(cache_, single_letter, pos + k);
    single_cell = zdd_union(cache_, single_cell, single_letter);
  }

  for (int i = 0; i < width_; i++) {
    for (int j = 0; j < height_; j++) {
      pos = (i + j * width_) * num_letters_;
      if (i != x || j != y) {
        for (int k = 0; k < num_letters_; k++) {
          single_cell = zdd_dontcare(cache_, single_cell, pos + k);
        }
      }
    }
  }
  return single_cell;
}

void ZDDSolver::valid_grid() {
  valid_grid_ = valid_cell(0, 0);
  for (int i = 0; i < width_; i++) {
    for (int j = 0; j < height_; j++) {
      valid_grid_ = zdd_inter(cache_, valid_grid_, valid_cell(i, j));
    }
  }
}

void ZDDSolver::solve() {
  Node zdd;
  for (int i = 0; i < static_cast<int>(words_.size()); i++)
    zdd = create_word_zdd(words_[i]);
/*  valid_grid();
  Node zdd = valid_grid_;
  for (int i = 0; i < static_cast<int>(words_.size()); i++)
    zdd = zdd_inter(cache_, zdd, create_word_zdd(words_[i]));*/
  cout << print(node_, zdd, [&](NodeFactory& node, Node n) {
    int name = node.name(n);
    char letter = letters_[name % num_letters_];
    name /= num_letters_;
    int x = name % width_;
    int y = name / width_;
    ostringstream oss;
    oss << letter << x << y;
    return oss.str();
  });
  
  cerr << node_.active_nodes();
}

int main() {
  int width, height;
  cin >> width >> height;
  vector<string> words;
  string word;
  while (cin >> word) {
    words.push_back(word);
  }
  vector<char> letters = eval_letters(words);
  ZDDSolver s(width, height, words, letters);
  s.solve();
  return 0;
}
