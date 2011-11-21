#include <iostream>
#include <string>
#include <vector>
#include <cstdio>

using namespace std;

void print_grid(const vector<vector<double> >& grid) {
  for (int j = 0; j < grid.size(); j++) {
    for (int i = 0; i < grid[j].size(); i++)
      printf("% 7.2lf ", grid[j][i]);
    printf("\n");
  }
}

struct action {
  string name;
  vector<pair<double, pair<int, int> > > dir;
};

void eval(vector<vector<double> >& grid, const vector<action>& actions,
          int j, int i, double cost) {
  double maxval = -1000;
  int action_taken = 0;
  for (int a = 0; a < actions.size(); a++) {
    double value = 0.0;
    for (int p = 0; p < actions[a].dir.size(); p++) {
      int y = j + actions[a].dir[p].second.first;
      int x = i + actions[a].dir[p].second.second;
      if (x < 0 || y < 0 || y >= grid.size() || x >= grid[0].size()) {
        x = i; y = j;
      }
      value += actions[a].dir[p].first * grid[y][x];
    }
    if (value > maxval) {
      maxval = value;
      action_taken = a;
    }
  }
  grid[j][i] = maxval + cost;
  printf ("grid %c%d : action %s\n",
          j + 'a', i + 1, actions[action_taken].name.c_str());
}

int main() {
  int x, y;
  cin >> y >> x;
  vector<vector<double> > grid(y, vector<double>(x, 0.0));
  vector<vector<bool> > fixed(y, vector<bool>(x, false));
  double cost;
  cin >> cost;
  int fixed_size;
  cin >> fixed_size;
  for (int k = 0; k < fixed_size; k++) {
    char line;
    int col, value;
    cin >> line >> col >> value;
    int i = col - 1;
    int j = line - 'a';
    fixed[j][i] = true;
    grid[j][i] = value;
  }
  int action_size;
  cin >> action_size;
  vector<action> actions(action_size);
  for (int k = 0; k < action_size; k++) {
    int dirs;
    cin >> dirs >> actions[k].name;
    actions[k].dir.resize(dirs);
    for (int j = 0; j < dirs; j++) {
      cin >> actions[k].dir[j].first
          >> actions[k].dir[j].second.first
          >> actions[k].dir[j].second.second;
    }
  }
  for (int iter = 0; iter < 100; iter++) {
    printf("iteration %d\n", iter);
    for (int j = 0; j < grid.size(); j++) {
      for (int i = 0; i < grid[j].size(); i++) {
        if (fixed[j][i]) continue;
        eval(grid, actions, j, i, cost);
      }
    }
    print_grid(grid);
  }
}
