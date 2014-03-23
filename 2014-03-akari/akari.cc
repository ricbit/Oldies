#include <iostream>
#include "easyscip.h"

using namespace std;
using namespace easyscip;

bool valid(int i, int j, int w, int h) {
  return i >= 0 && i < w && j >= 0 && j < h;
}

int main() {
  int w,h;
  cin >> w >> h;
  vector<string> board(h);
  for (int i = 0; i < h; i++) {
    cin >> board[i];
  }
  MIPSolver mip;
  vector<vector<Variable>> lamp(h);
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      lamp[j].push_back(mip.binary_variable(1));
    }
  }
  // Enforce restriction around numbers.
  static int dx[] = {1, -1, 0, 0};
  static int dy[] = {0, 0, 1, -1};
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      if (board[j][i] >= '0' && board[j][i] <= '4') {
        auto cons = mip.constraint();
        for (int k = 0; k < 4; k++) {
          int jj = j + dy[k], ii = i + dx[k]; 
          if (valid(ii, jj, w, h) && board[jj][ii] == '.') {
            cons.add_variable(lamp[jj][ii], 1);
          }
        }
        int value = board[j][i] - '0';
        cons.commit(value, value);
      }
    }
  }
  // Every free position must be illuminated,
  // but no lamp can be illuminated by another lamp.
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      if (board[j][i] == '.') {
        auto cons = mip.constraint();
        for (int k = 0; k < 4; k++) {
          int jj = j + dy[k], ii = i + dx[k]; 
          while (valid(ii, jj, w, h) && board[jj][ii] == '.') {
            cons.add_variable(lamp[jj][ii], 1);
            ii += dx[k];
            jj += dy[k];
          }
        }
        cons.add_variable(lamp[j][i], w * h);
        cons.commit(1, w * h);
      }
    }
  }
  // Solve and print.
  auto sol = mip.solve();
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      if (sol.value(lamp[j][i]) > 0.5) {
        cout << '*';
      } else {
        cout << board[j][i];
      }
    }
    cout << "\n";
  }
}
