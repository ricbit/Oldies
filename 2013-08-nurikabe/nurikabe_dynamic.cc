#include <cstdio>
#include <vector>
#include <queue>
#include <set>
#include <cmath>
#include <tuple>
#include "easyscip.h"

using namespace std;
using namespace easyscip;

struct Group {
  int length;
  int row, col;
};

struct GroupPosition {
  int group_idx;
  vector<pair<int, int>> pos;
};

struct EmptyPosition {
  vector<pair<int, int>> empty, border;
};

template<typename T>
T abs(T x) {
  return x < 0 ? -x : x;
}

template<typename T>
void cell_iterator(int rows, int cols, T func) {
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      func(i, j);
    }
  }
}

template<typename T>
void full_iterator(int rows, int cols, int groups, T func) {
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      for (int k = 0; k < groups; k++) {
        func(i, j, k);
      }
    }
  }
}

template<typename T>
void group_iterator(int groups, T func) {
  for (int i = 0; i < groups; i++) {
    func(i);
  }
}

template<typename T>
void neighbour_iterator(int rows, int cols, int i, int j, T func) {
  static int dx[] = {1, -1, 0, 0};
  static int dy[] = {0, 0, 1, -1};
  for (int k = 0; k < 4; k++) {
    int ni = i + dx[k];
    int nj = j + dy[k];
    if (ni >= 0 && nj >=0 && ni < rows && nj < cols) {
      func(ni, nj);
    }
  }
}

char bigdigit(int n) {
  if (n < 10) {
    return '0' + n;
  } else {
    return 'A' + n - 10;
  }
}

struct NurikabeVariables {
  vector<vector<Variable>> used;
  vector<vector<vector<Variable>>> has_group, hasnt_group;
  NurikabeVariables(int rows, int cols) 
      : used(rows),
        has_group(rows, vector<vector<Variable>>(cols)),
        hasnt_group(rows, vector<vector<Variable>>(cols)) {
  }
};

struct NurikabeSolution {
  vector<vector<int>> pos;
  int rows_, cols_;
  const vector<Group>& group_;
  NurikabeSolution(int rows, int cols, const vector<Group>& group,
                   NurikabeVariables& var, Solution& sol) 
      : pos(rows, vector<int>(cols, -1)), rows_(rows), cols_(cols), group_(group) {
    full_iterator(rows, cols, group_.size(), [&](int i, int j, int k) {
      if (sol.value(var.has_group[i][j][k]) > 0.5) {
        pos[i][j] = k;
      }
    });
  }
  void print() {
    for (int j = 0; j < cols_; j++) {
      for (int i = 0; i < rows_; i++) {
        char c = '.';
        int k = pos[i][j];
        if (k >= 0) {
          c = bigdigit(group_[k].length);
        }
        printf("%c", c);
      }
      printf("\n");
    }
  }
};

struct NurikabeDynamicConstraint : public DynamicConstraint {
  int rows, cols, groups;
  const vector<Group>& group;
  NurikabeVariables& var;
  vector<vector<bool>> visited;
  NurikabeDynamicConstraint(int rows_, int cols_, const vector<Group>& group_, NurikabeVariables& var_)
      : rows(rows_), cols(cols_), groups(group_.size()), group(group_), var(var_),
        visited(rows, vector<bool>(cols)) {
  }
  virtual bool check_solution(Solution& solution) {
    bool feasible = true;
    // Check if a group with length N has exactly N cells.
    for (int k = 0; k < groups; k++) {
      int ans = 0;
      cell_iterator(rows, cols, [&](int i, int j) {
        if (solution.value(var.has_group[i][j][k]) > 0.5) {
          ans++;
        }
      });
      if (ans != group[k].length) {
        //NurikabeSolution sol(rows, cols, group, var, solution);
        //sol.print();
        return false;
      }
    };

    // Check for connected paths.
    NurikabeSolution sol(rows, cols, group, var, solution);
    clear_visited();
    int empties = count_empties();
    vector<bool> visited_group(groups, false);
    cell_iterator(rows, cols, [&](int i, int j) {
      int value = sol.pos[i][j];
      // Check for connected empties.
      if (!visited[i][j] && value == -1) {
        int length = grow(sol, i, j, -1, true);
        if (length < empties) {
          //add_empties(sol);
          feasible = false;
        }
      }
      // Check for connected groups.
      if (!visited[i][j] && value >= 0 && !visited_group[value]) {
        visited_group[value] = true;
        int length = grow(sol, i, j, value);
        if (length != group[value].length) {
          //add_group(sol, value);
          feasible = false;
        }
      }
    });
    return feasible;
  }
  void add_empties(NurikabeSolution& sol) {
    EmptyPosition position;
    set<pair<int, int>> border;
    cell_iterator(rows, cols, [&](int i, int j) {
      if (sol.pos[i][j] == -2) {
        position.empty.push_back(make_pair(i, j));
        neighbour_iterator(rows, cols, i, j, [&](int ni, int nj) {
          if (sol.pos[ni][nj] != -2) {
            border.insert(make_pair(ni, nj));
          }
        });
      }
    });
    position.border = vector<pair<int, int>>(border.begin(), border.end());
    cell_iterator(rows, cols, [&](int i, int j) {
      if (sol.pos[i][j] == -2) {
        sol.pos[i][j] = -3;
      }
    });
    Constraint cons = constraint();
    for (auto pos : position.empty) {
      cons.add_variable(var.used[pos.first][pos.second], -1);
    }
    for (auto pos : position.border) {
      cons.add_variable(var.used[pos.first][pos.second], 1);
    }
    cons.commit(-rows * cols, position.border.size() - 1);
  }
  int count_empties() {    
    int ans = rows * cols;
    group_iterator(groups, [&](int k) {
      ans -= group[k].length;
    });
    return ans;
  }
  int grow(NurikabeSolution& sol, int i, int j, int group_idx, bool mark=false) {
    if (sol.pos[i][j] != group_idx || visited[i][j]) {
      return 0;
    }
    if (mark) {
      sol.pos[i][j] = -2;
    }
    int ans = 1;
    visited[i][j] = true;
    neighbour_iterator(rows, cols, i, j, [&](int ni, int nj) {
      ans += grow(sol, ni, nj, group_idx, mark);
    });
    return ans;
  }
  void clear_visited() {
    cell_iterator(rows, cols, [&](int i, int j) {
      visited[i][j] = false;
    });
  }
  void add_group(const NurikabeSolution& sol, int group_idx) {
    Constraint cons = constraint();
    GroupPosition group_pos;
    group_pos.group_idx = group_idx;
    cell_iterator(rows, cols, [&](int i, int j) {
      if (sol.pos[i][j] == group_idx) {
        group_pos.pos.push_back(make_pair(i, j));
        cons.add_variable(var.has_group[i][j][group_idx], 1);
      }
    });
    cons.commit(0, group[group_idx].length - 1);
  }
};

struct NurikabeMIP {
  int rows, cols, groups;
  const vector<Group>& group;
  vector<vector<vector<bool>>> seeds;
  NurikabeVariables var;
  NurikabeDynamicConstraint dynamic_constraint;
  MIPSolver mip;
 public:
  NurikabeMIP(int rows_, int cols_, const vector<Group>& group_)
      : rows(rows_), cols(cols_), groups(group_.size()), 
        group(group_),
        seeds(rows, vector<vector<bool>>(cols, vector<bool>(groups, false))),
        var(rows, cols),
        dynamic_constraint(rows, cols, group, var) {
    printf("Set up variables\n");
    // One variable for each cell, used or not.
    cell_iterator(rows, cols, [&](int i, int j) {
      var.used[i].push_back(mip.binary_variable(1));
    });
    // Two variables for each cell, for each group.
    full_iterator(rows, cols, groups, [&](int i, int j, int k) {
      var.has_group[i][j].push_back(mip.binary_variable(1));
      var.hasnt_group[i][j].push_back(mip.binary_variable(0));
    });
    // Mark each group seed.
    group_iterator(groups, [&](int k) {
      Constraint used_cons = mip.constraint();
      used_cons.add_variable(var.used[group[k].row][group[k].col], 1);
      used_cons.commit(1, 1);

      Constraint group_cons = mip.constraint();
      group_cons.add_variable(var.has_group[group[k].row][group[k].col][k], 1);
      group_cons.commit(1, 1);
    });
    // Each cell is either empty or has exactly one group.
    cell_iterator(rows, cols, [&](int i, int j) {
      Constraint cons = mip.constraint();
      group_iterator(groups, [&](int k) {
        cons.add_variable(var.has_group[i][j][k], 1);
      });
      cons.add_variable(var.used[i][j], -1);
      cons.commit(0, 0);
    });
    // Set the length of the group.
    group_iterator(groups, [&](int k) {
      Constraint cons = mip.constraint();
      cell_iterator(rows, cols, [&](int i, int j) {
        cons.add_variable(var.has_group[i][j][k], 1);
      });
      cons.commit(group[k].length, group[k].length);
    });
    // No 2x2 block is empty.
    cell_iterator(rows - 1, cols - 1, [&](int i, int j) {
      Constraint cons = mip.constraint();
      cons.add_variable(var.used[i][j], 1);
      cons.add_variable(var.used[i + 1][j], 1);
      cons.add_variable(var.used[i][j + 1], 1);
      cons.add_variable(var.used[i + 1][j + 1], 1);
      cons.commit(1, 4);
    });
    // If a cell is used, either it has or hasn't a group.
    full_iterator(rows, cols, groups, [&](int i, int j, int k) {
      Constraint cons = mip.constraint();
      cons.add_variable(var.used[i][j], 1);
      cons.add_variable(var.has_group[i][j][k], -1);
      cons.add_variable(var.hasnt_group[i][j][k], -1);
      cons.commit(0, 0);
    });
    // Groups can't touch on horizontal.
    full_iterator(rows, cols - 1, groups, [&](int i, int j, int k) {
      Constraint cons = mip.constraint();
      cons.add_variable(var.has_group[i][j][k], 1);
      cons.add_variable(var.hasnt_group[i][j + 1][k], 1);
      cons.commit(0, 1);
    });
    // Groups can't touch on vertical.
    full_iterator(rows - 1, cols, groups, [&](int i, int j, int k) {
      Constraint cons = mip.constraint();
      cons.add_variable(var.has_group[i][j][k], 1);
      cons.add_variable(var.hasnt_group[i + 1][j][k], 1);
      cons.commit(0, 1);
    });
    // Create a map with seeds to be avoided.
    full_iterator(rows, cols, groups, [&](int i, int j, int k) {
      if (near(i, j, k)) {
        seeds[i][j][k] = true;
      }
    });
    // Pseudo-continuity based on relative unreachables.
    full_iterator(rows, cols, groups, [&](int i, int j, int k) {
      if (!(i == group[k].row && j == group[k].col)) {
        int unreachables = 0;
        Constraint reach_cons = mip.constraint();
        Constraint unreach_cons = mip.constraint();
        bool success = unreachable_iterator(
            rows, cols, i, j, k, [&](int ii, int jj, bool reachable) {
          if (reachable) {
            reach_cons.add_variable(var.has_group[ii][jj][k], 1);          
          } else {
            unreachables++;
            unreach_cons.add_variable(var.has_group[ii][jj][k], 1);          
          }
        });
        if (success) {
          unreach_cons.add_variable(var.has_group[i][j][k], unreachables);
          unreach_cons.commit(0, unreachables);
          reach_cons.add_variable(var.has_group[i][j][k], -(group[k].length - 2));
          reach_cons.commit(0, rows * cols);
        } else {
          Constraint cons = mip.constraint();
          cons.add_variable(var.hasnt_group[i][j][k], 1);
          cons.add_variable(var.used[i][j], -1);
          cons.commit(0, 0);
        }
      }
    });
    // Add the dynamic constraint to make groups continuous.
    //mip.add_dynamic_constraint(dynamic_constraint);
    printf("Variables loaded.\n");
  }
  int manhattan(int i, int j, int ii, int jj) {
    return abs(i - ii) + abs(j - jj);
  }
  bool near(int i, int j, int k) {
    for (int kk = 0; kk < groups; kk++) {
      if (k == kk) continue;
      static int dx[] = {0, 0, 0, 1, -1};
      static int dy[] = {0, 1, -1, 0, 0};
      for (int n = 0; n < 5; n++) {
        if (i == group[kk].row + dx[n] && j == group[kk].col + dy[n]) {
          return true;
        }
      }      
    }
    return false;
  }
  template<typename T>
  bool unreachable_iterator(int rows, int cols, int i, int j, int k, T func) {
    // Check early unreachable cells.
    if (manhattan(i, j, group[k].row, group[k].col) >= group[k].length) {
      return false;
    }
    vector<vector<int> > value(rows, vector<int>(cols, -1));
    priority_queue<tuple<int, int, int>> next;

    // Grow a distance map from the seed.
    next.push(make_tuple(0, group[k].row, group[k].col));
    value[group[k].row][group[k].col] = 0;
    while (!next.empty()) {
      auto current = next.top();
      next.pop();
      int pos = -get<0>(current);
      int ii = get<1>(current);
      int jj = get<2>(current);
      if (i == ii && j == jj) break;
      neighbour_iterator(rows, cols, ii, jj, [&](int i3, int j3) {
        if (value[i3][j3] < 0 && !seeds[i3][j3][k]) {
          value[i3][j3] = pos + 1;
          next.push(make_tuple(-value[i3][j3], i3, j3));
        }
      });
    }

    // Check late unreachable cells.
    int minlen = value[i][j];
    if (minlen < 0 || minlen >= group[k].length) return false;    
    int marker = -rows * cols * 2;
    while (!next.empty()) {
      next.pop();
    }

    // Traverse the distance map backwards looking for all shortest paths
    // from goal to seed.
    next.push(make_tuple(minlen, i, j));
    while (!next.empty()) {
      auto current = next.top();
      next.pop();
      int pos = get<0>(current);
      int ii = get<1>(current);
      int jj = get<2>(current);
      if (pos != value[ii][jj]) continue;
      neighbour_iterator(rows, cols, ii, jj, [&](int i3, int j3) {
        if (value[i3][j3] == value[ii][jj] - 1 && value[i3][j3] >= 0) {
          next.push(make_tuple(value[i3][j3], i3, j3));
        }
      });
      value[ii][jj] = marker;
    }

    // Mark all reachable cells in the shortest path.
    cell_iterator(rows, cols, [&](int ii, int jj) {
      if (value[ii][jj] == marker) {
        value[ii][jj] = minlen + 1;
        next.push(make_tuple(-value[ii][jj], ii, jj));
      } else if (value[ii][jj] >= 0) {
        value[ii][jj] = -1;
      }
    });

    // Grow a region of reachable cells from the shortest path.
    while (!next.empty()) {
      auto current = next.top();
      next.pop();
      int pos = -get<0>(current);
      if (pos >= group[k].length) break;
      neighbour_iterator(rows, cols, get<1>(current), get<2>(current), [&](int ii, int jj) {
        if (value[ii][jj] < 0 && !seeds[ii][jj][k]) {
          value[ii][jj] = pos + 1;
          next.push(make_tuple(-value[ii][jj], ii, jj));
        }
      });
    }

    // Callback on every cell, marking if reachable or not.
    cell_iterator(rows, cols, [&](int ii, int jj) {
      if (!(i == ii && j == jj) ||
          !(ii == group[k].row && jj == group[k].col)) {
        func(ii, jj, value[ii][jj] >= 0);
      }
    });
    return true;
  }
  NurikabeSolution solve() {
    Solution sol = mip.solve();
    return NurikabeSolution(rows, cols, group, var, sol);
  }
};

int main() {
  int rows, cols;
  scanf("%d %d", &rows, &cols);
  int groups;
  scanf("%d", &groups);
  vector<Group> group(groups);
  for (int i = 0; i < groups; i++) {
    scanf("%d %d %d", &group[i].row, &group[i].col, &group[i].length);
  }
  NurikabeMIP mip(rows, cols, group);
  NurikabeSolution sol = mip.solve();
  sol.print();
}
