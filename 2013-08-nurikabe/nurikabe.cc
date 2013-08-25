#include <cstdio>
#include <vector>
#include <set>
#include <cmath>
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

struct NurikabeSolution {
  vector<vector<int>> pos;
  NurikabeSolution(int rows, int cols) : pos(rows, vector<int>(cols, -1)) {
  }
};

template<typename T>
T abs(T x) {
  return x < 0 ? -x : x;
}

struct NurikabeMIP {
  int rows, cols;
  const vector<Group>& group;
  int groups;
  vector<vector<Variable>> used;
  vector<vector<vector<Variable>>> has_group, hasnt_group;
  vector<vector<vector<Variable>>> edge_h, edge_v;
  vector<vector<Variable>> empty_edge_h, empty_edge_v;
  vector<Variable> empty_group;
  MIPSolver mip;
  const vector<GroupPosition> forbidden;
  const vector<EmptyPosition> empty_forbidden;
 public:
  NurikabeMIP(int rows_, int cols_, const vector<Group>& group_,
      const vector<GroupPosition>& forbidden_, const vector<EmptyPosition> empty_forbidden_) 
      : rows(rows_), cols(cols_), group(group_), groups(group.size()), used(rows),
        has_group(rows, vector<vector<Variable>>(cols)),
        hasnt_group(rows, vector<vector<Variable>>(cols)),
        edge_h(rows, vector<vector<Variable>>(cols - 1)),
        edge_v(rows - 1, vector<vector<Variable>>(cols)),
        empty_edge_h(rows), empty_edge_v(rows - 1),
        forbidden(forbidden_), empty_forbidden(empty_forbidden_) {
    // One variable for each cell, used or not.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        used[i].push_back(mip.binary_variable(0));
      }
    }
    // Two variables for each cell, for each group.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          has_group[i][j].push_back(mip.binary_variable(diff(i, j, k)));
          hasnt_group[i][j].push_back(mip.binary_variable(0));
        }
      }
    }
    // Edge variables for each group.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols - 1; j++) {
        for (int k = 0; k < groups; k++) {
          edge_h[i][j].push_back(mip.binary_variable(0));
        }
      }
    }
    for (int i = 0; i < rows - 1; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          edge_v[i][j].push_back(mip.binary_variable(0));
        }
      }
    }
    // Edge variables for empty cells.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols - 1; j++) {
        empty_edge_h[i].push_back(mip.binary_variable(0));
      }
    }
    for (int i = 0; i < rows - 1; i++) {
      for (int j = 0; j < cols; j++) {
        empty_edge_v[i].push_back(mip.binary_variable(0));
      }
    }
    // Mark each group seed.
    for (int i = 0; i < groups; i++) {
      Constraint used_cons = mip.constraint();
      used_cons.add_variable(used[group[i].row][group[i].col], 1);
      used_cons.commit(1, 1);

      Constraint group_cons = mip.constraint();
      group_cons.add_variable(has_group[group[i].row][group[i].col][i], 1);
      group_cons.commit(1, 1);
    }
    // Each cell is either empty or has exactly one group.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        Constraint cons = mip.constraint();
        for (int k = 0; k < groups; k++) {
          cons.add_variable(has_group[i][j][k], 1);
        }
        cons.add_variable(used[i][j], -1);
        cons.commit(0, 0);
      }
    }
    // Set the length of the group.
    for (int k = 0; k < groups; k++) {
      Constraint cons = mip.constraint();
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          cons.add_variable(has_group[i][j][k], 1);
        }
      }
      cons.commit(group[k].length, group[k].length);
    }
    // No 4x4 block is empty.
    for (int i = 0; i < rows - 1; i++) {
      for (int j = 0; j < cols - 1; j++) {
        Constraint cons = mip.constraint();
        cons.add_variable(used[i][j], 1);
        cons.add_variable(used[i + 1][j], 1);
        cons.add_variable(used[i][j + 1], 1);
        cons.add_variable(used[i + 1][j + 1], 1);
        cons.commit(1, 4);
      }
    }
    // If a cell is used, either it has or hasn't a group.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          Constraint cons = mip.constraint();
          cons.add_variable(used[i][j], 1);
          cons.add_variable(has_group[i][j][k], -1);
          cons.add_variable(hasnt_group[i][j][k], -1);
          cons.commit(0, 0);
        }
      }
    }
    // Groups can't touch on horizontal.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols - 1; j++) {
        for (int k = 0; k < groups; k++) {
          Constraint cons = mip.constraint();
          cons.add_variable(has_group[i][j][k], 1);
          cons.add_variable(hasnt_group[i][j + 1][k], 1);
          cons.commit(0, 1);
        }
      }
    }
    // Groups can't touch on vertical.
    for (int i = 0; i < rows - 1; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          Constraint cons = mip.constraint();
          cons.add_variable(has_group[i][j][k], 1);
          cons.add_variable(hasnt_group[i + 1][j][k], 1);
          cons.commit(0, 1);
        }
      }
    }
    // An h edge is present is both endpoints are from the same group.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols - 1; j++) {
        for (int k = 0; k < groups; k++) {
          Constraint cons = mip.constraint();
          cons.add_variable(has_group[i][j][k], 1);
          cons.add_variable(has_group[i][j + 1][k], 1);
          cons.add_variable(edge_h[i][j][k], -2);
          cons.commit(0, 1);
        }
      }
    }
    // An v edge is present is both endpoints are from the same group.
    for (int i = 0; i < rows - 1; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          Constraint cons = mip.constraint();
          cons.add_variable(has_group[i][j][k], 1);
          cons.add_variable(has_group[i + 1][j][k], 1);
          cons.add_variable(edge_v[i][j][k], -2);
          cons.commit(0, 1);
        }
      }
    }
    // Every cell on a group must be on an edge, if group > 1.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          if (group[k].length == 1) {
            continue;
          }
          Constraint cons = mip.constraint();
          if (j > 0) cons.add_variable(edge_h[i][j - 1][k], -1);
          if (j < cols - 1) cons.add_variable(edge_h[i][j][k], -1);
          if (i > 0) cons.add_variable(edge_v[i - 1][j][k], -1);
          if (i < rows - 1) cons.add_variable(edge_v[i][j][k], -1);
          cons.add_variable(has_group[i][j][k], 1);
          cons.commit(-4, 0);
        }
      }
    }
    // Each group of size n must have at least n-1 edges.
    for (int k = 0; k < groups; k++) {
      Constraint cons = mip.constraint();
      for (int i = 0; i < rows - 1; i++) {
        for (int j = 0; j < cols; j++) {
          cons.add_variable(edge_v[i][j][k], 1);
        }
      }
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols - 1; j++) {
          cons.add_variable(edge_h[i][j][k], 1);
        }
      }
      cons.commit(group[k].length - 1, rows * cols);
    }
    // An empty h edge is present is both endpoints are empty.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols - 1; j++) {
        Constraint cons = mip.constraint();
        cons.add_variable(used[i][j], 1);
        cons.add_variable(used[i][j + 1], 1);
        cons.add_variable(empty_edge_h[i][j], 2);
        cons.commit(1, 2);
      }
    }
    // An empty v edge is present is both endpoints are empty.
    for (int i = 0; i < rows - 1; i++) {
      for (int j = 0; j < cols; j++) {
        Constraint cons = mip.constraint();
        cons.add_variable(used[i][j], 1);
        cons.add_variable(used[i + 1][j], 1);
        cons.add_variable(empty_edge_v[i][j], 2);
        cons.commit(1, 2);
      }
    }
    // Every empty cell must have at least 1 empty edge.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        Constraint cons = mip.constraint();
        if (j > 0) cons.add_variable(empty_edge_h[i][j - 1], 1);
        if (j < cols - 1) cons.add_variable(empty_edge_h[i][j], 1);
        if (i > 0) cons.add_variable(empty_edge_v[i - 1][j], 1);
        if (i < rows - 1) cons.add_variable(empty_edge_v[i][j], 1);
        cons.add_variable(used[i][j], 1);
        cons.commit(1, 5);
      }
    }
    // Mark unreachable cells.
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          if (abs(i - group[k].row) + abs(j - group[k].col) >= group[k].length) {
            Constraint cons = mip.constraint();
            cons.add_variable(hasnt_group[i][j][k], 1);
            cons.add_variable(used[i][j], -1);
            cons.commit(0, 0);
          }
        }
      }
    }
    // Remove forbidden groups.
    for (int i = 0; i < int(forbidden.size()); i++) {
      Constraint cons = mip.constraint();
      auto& g = forbidden[i];
      for (int j = 0; j < int(g.pos.size()); j++) {
        cons.add_variable(has_group[g.pos[j].first][g.pos[j].second][g.group_idx], 1);
      }
      cons.commit(0, group[g.group_idx].length - 1);
    }
    // Add a variable for each forbidden empty group.
    for (int i = 0; i < int(empty_forbidden.size()); i++) {
      empty_group.push_back(mip.binary_variable(0));
      Constraint cons = mip.constraint();
      cons.add_variable(empty_group[i], empty_forbidden[i].empty.size());
      for (int j = 0; j < int(empty_forbidden[i].empty.size()); j++) {
        auto& pos = empty_forbidden[i].empty[j];
        cons.add_variable(used[pos.first][pos.second], 1);
      }
      cons.commit(1, empty_forbidden[i].empty.size());
    }
    // Empty group is only allowed if at least one neighbour is empty.
    for (int i = 0; i < int(empty_forbidden.size()); i++) {
      Constraint cons = mip.constraint();
      cons.add_variable(empty_group[i], 1);
      for (int j = 0; j < int(empty_forbidden[i].border.size()); j++) {
        auto& pos = empty_forbidden[i].border[j];
        cons.add_variable(used[pos.first][pos.second], 1);
      }
      cons.commit(0, empty_forbidden[i].border.size());
    }
  }
  double sqr(double x) {
    return x * x;
  }
  double diff(int row, int col, int idx) {
    return sqrt(sqr(row - group[idx].row) + sqr(col - group[idx].col));
  }
  NurikabeSolution solve() {
    Solution sol = mip.solve();
    NurikabeSolution out(rows, cols);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < groups; k++) {
          if (sol.value(has_group[i][j][k]) > 0.5) {
            out.pos[i][j] = k;
          }
        }
      }
    }
    return out;
  }
};

struct Nurikabe {
  int rows, cols;
  const vector<Group>& group;
  int groups;
  vector<vector<bool>> visited;
  vector<GroupPosition> forbidden;
  vector<EmptyPosition> empty_forbidden;
 public:
  Nurikabe(int rows_, int cols_, const vector<Group>& group_) 
      : rows(rows_), cols(cols_), group(group_), groups(group.size()),
        visited(rows, vector<bool>(cols)) {
  }
  void solve() {
    while (true) {
      clear_visited();
      vector<bool> visited_group(groups, false);
      NurikabeMIP mip(rows, cols, group, forbidden, empty_forbidden);
      NurikabeSolution sol = mip.solve();
      int failures = 0;
      int empties = count_empties(sol);
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          int value = sol.pos[i][j];
          if (!visited[i][j] && value == -1) {
            int length = grow(sol, i, j, -1, true);
            if (length != empties) {
              add_empties(sol);
              failures++;
            }
          }
          if (!visited[i][j] && value >= 0 && !visited_group[value]) {
            visited_group[value] = true;
            int length = grow(sol, i, j, value);
            if (length != group[value].length) {
              add_group(sol, value);
              failures++;
            }
          }
        }
      }
      //failures = 0;
      if (!failures) {
        print(sol);
        break;
      }
    }
  }
  template<typename T>
  void visit_neighbour(int i, int j, T func) {
    int dx[] = {1, -1, 0, 0};
    int dy[] = {0, 0, 1, -1};
    for (int k = 0; k < 4; k++) {
      int ni = i + dx[k];
      int nj = j + dy[k];
      if (ni >= 0 && nj >=0 && ni < rows && nj < cols) {
        func(ni, nj);
      }
    }
  }
  void add_empties(NurikabeSolution& sol) {
    EmptyPosition position;
    set<pair<int, int>> border;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (sol.pos[i][j] == -2) {
          position.empty.push_back(make_pair(i, j));
          visit_neighbour(i, j, [&](int ni, int nj) {
            if (sol.pos[ni][nj] != -2) {
              border.insert(make_pair(ni, nj));
            }
          });
        }
      }
    }
    position.border = vector<pair<int, int>>(border.begin(), border.end());
    empty_forbidden.push_back(position);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (sol.pos[i][j] == -2) {
          sol.pos[i][j] = -3;
        }
      }
    }
    printf("Empty group: ");
    for (int i = 0 ; i < int(position.empty.size()); i++) {
      printf("%d-%d ", position.empty[i].first, position.empty[i].second);
    }
    printf("\nBorder group: ");
    for (int i = 0 ; i < int(position.border.size()); i++) {
      printf("%d-%d ", position.border[i].first, position.border[i].second);
    }
    printf("\n");
  }
  int count_empties(const NurikabeSolution& sol) {
    int ans = 0;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (sol.pos[i][j] < 0) {
          ans++;
        }
      }
    }
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
    visit_neighbour(i, j, [&](int ni, int nj) {
      ans += grow(sol, ni, nj, group_idx, mark);
    });
    return ans;
  }
  void add_group(const NurikabeSolution& sol, int group_idx) {
    GroupPosition group_pos;
    group_pos.group_idx = group_idx;
    printf("group %d: ", group_idx);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (sol.pos[i][j] == group_idx) {
          printf("%d %d, ", i, j);
          group_pos.pos.push_back(make_pair(i, j));
        }
      }
    }
    printf("\n");
    forbidden.push_back(group_pos);
  }
  void clear_visited() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        visited[i][j] = false;
      }
    }
  }
  void print(const NurikabeSolution& sol) {
    for (int j = 0; j < cols; j++) {
      for (int i = 0; i < rows; i++) {
        char c = '.';
        int k = sol.pos[i][j];
        if (k >= 0) {
          if (group[k].length >= 10) {
            c = 'A' + group[k].length - 10;
          } else {
            c = '0' + group[k].length;
          }
        }
        printf("%c", c);
      }
      printf("\n");
    }
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
  Nurikabe nurikabe(rows, cols, group);
  nurikabe.solve();
}
