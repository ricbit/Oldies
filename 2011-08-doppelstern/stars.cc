// Solution to Doppelstern using exact cover.
// Ricardo Bittencourt 2011

// Please see the link below for rules and examples.
// http://www.puzzlephil.com/index.php/en/puzzles/stars

#include <iostream>
#include <vector>
#include <set>

using namespace std;

#include "exactcover.h"

struct print_solutions {
  int y, x;
  print_solutions(int y_, int x_): y(y_), x(x_) {}
  void operator()(const vector<int>& solution) {
    vector<vector<bool> > mat(y, vector<bool>(x, false));
    for (int i = 0; i < solution.size(); i++) {
      if (solution[i] < x * y)
        mat[solution[i] / y][solution[i] % y] = true;
    }
    for (int j = 0; j < y; j++) {
      for (int i = 0; i < x; i++) {
        cout << (mat[j][i] ? "*" : ".");
      }
      cout << "\n";
    }
    cout << "\n";
  }
};

int main() {
  int stars, x, y;
  cin >> stars >> y >> x;
  // stars must be 1 in this version.
  vector<string> input(y);
  for (int i = 0; i < y; i++) {
    cin >> input[i];
  }
  set<char> groups;
  for (int j = 0; j < y; j++) {
    for (int i = 0; i < x; i++) {
      groups.insert(input[j][i]);
    }
  }
  int corners = (x - 1) * (y - 1);
  int lines = x * y + corners;
  int columns = y + x + groups.size() + corners;
  vector<vector<bool> > mat(lines, vector<bool>(columns, false));
  const int slines = 0;
  const int scolumns = y;
  const int sgroups = y + x;
  const int scorners = y + x + groups.size();
  for (int j = 0; j < y; j++) {
    for (int i = 0; i < x; i++) {
      int line = j * x + i;
      mat[line][slines + i] = true;
      mat[line][scolumns + j] = true;
      mat[line][sgroups + (input[j][i] - 'a')] = true;
    }
  }
  for (int j = 0; j < y - 1; j++) {
    for (int i = 0; i < x - 1; i++) {
      int dummyline = x * y + (j * (x - 1) + i);
      int dummycolumn = scorners + j * (x - 1) + i;
      mat[dummyline][dummycolumn] = true;
      for (int jj = 0; jj < 2; jj++) {
        for (int ii = 0; ii < 2; ii++) {
          int line = (j+jj) * x + (i + ii);
	  mat[line][scorners + j * (x - 1) + i] = true;
	}
      }
    }
  }
  print_solutions print(y, x);
  exactcover(mat, print);
}
