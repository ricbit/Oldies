#include <iostream>
#include "easyscip.h"

using namespace std;
using namespace easyscip;

int main() {
  int w,h;
  cin >> w >> h;
  vector<string> board(h);
  for (int i = 0; i < h; i++) {
    cin >> board[i];
  }
  MIPSolver mip;
  vector<vector<Variable>> red(h), blue(h);
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      red[j].push_back(mip.binary_variable(0));
      blue[j].push_back(mip.binary_variable(0));
    }
  }
  // Add the givens.
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      if (board[j][i] == 'r') {
        auto cons = mip.constraint();
        cons.add_variable(red[j][i], 1);
        cons.commit(1, 1);
      }
      if (board[j][i] == 'b') {
        auto cons = mip.constraint();
        cons.add_variable(red[j][i], 1);
        cons.commit(0, 0);
      }
    }
  }
  // Either a position is red or blue.
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      auto cons = mip.constraint();
      cons.add_variable(red[j][i], 1);
      cons.add_variable(blue[j][i], 1);
      cons.commit(1, 1);
    }
  }
  // Exactly w/2 reds per line.
  for (int j = 0; j < h; j++) {
    auto cons = mip.constraint();
    for (int i = 0; i < w; i++) {
      cons.add_variable(red[j][i], 1);
    }
    cons.commit(w / 2, w / 2);
  }
  // Exactly h/2 reds per line.
  for (int i = 0; i < w; i++) {
    auto cons = mip.constraint();
    for (int j = 0; j < h; j++) {
      cons.add_variable(red[j][i], 1);
    }
    cons.commit(h / 2, h / 2);
  }
  // No three h-adjacents should be equal.
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w - 2; i++) {
      auto cons = mip.constraint();
      cons.add_variable(red[j][i], 1);
      cons.add_variable(red[j][i + 1], 1);
      cons.add_variable(red[j][i + 2], 1);
      cons.commit(1, 2);
    }
  }
  // No three v-adjacents should be equal.
  for (int i = 0; i < w; i++) {
    for (int j = 0; j < h - 2; j++) {
      auto cons = mip.constraint();
      cons.add_variable(red[j][i], 1);
      cons.add_variable(red[j + 1][i], 1);
      cons.add_variable(red[j + 2][i], 1);
      cons.commit(1, 2);
    }
  }
  vector<Variable> pn;
  int current = 0;
  // No two columns should be equal.
  for (int i = 0; i < w; i++) {
    for (int ii = i + 1; ii < w; ii++) {
      auto cons_pn = mip.constraint();
      pn.push_back(mip.integer_variable(-(2 << h), 2 << h, 1));
      auto excess = current++;
      pn.push_back(mip.binary_variable(0));
      auto p = current++;
      pn.push_back(mip.binary_variable(0));
      auto n = current++;
      for (int j = 0; j < h; j++) {
        cons_pn.add_variable(red[j][i], 1 << j);
        cons_pn.add_variable(blue[j][ii], 1 << j);
      }
      cons_pn.add_variable(pn[excess], 1);
      cons_pn.commit((1 << h) - 1, (1 << h) - 1);
      int MAX = 2000000;
      auto cons_p = mip.constraint();
      cons_p.add_variable(pn[excess], 1);
      cons_p.add_variable(pn[p], -MAX);
      cons_p.commit(-MAX + 1, 0);
      auto cons_n = mip.constraint();
      cons_n.add_variable(pn[excess], -1);
      cons_n.add_variable(pn[n], -MAX);
      cons_n.commit(-MAX + 1, 0);
      auto cons = mip.constraint();
      cons.add_variable(pn[p], 1);
      cons.add_variable(pn[n], 1);
      cons.commit(1, 2);
    }
  }
  // No two rows should be equal.
  for (int j = 0; j < h; j++) {
    for (int jj = j + 1; jj < h; jj++) {
      auto cons_pn = mip.constraint();
      pn.push_back(mip.integer_variable(-(2 << w), 2 << w, 1));
      auto excess = current++;
      pn.push_back(mip.binary_variable(0));
      auto p = current++;
      pn.push_back(mip.binary_variable(0));
      auto n = current++;
      for (int i = 0; i < w; i++) {
        cons_pn.add_variable(red[j][i], 1 << i);
        cons_pn.add_variable(blue[jj][i], 1 << i);
      }
      cons_pn.add_variable(pn[excess], 1);
      cons_pn.commit((1 << w) - 1, (1 << w) - 1);
      int MAX = 2000000;
      auto cons_p = mip.constraint();
      cons_p.add_variable(pn[excess], 1);
      cons_p.add_variable(pn[p], -MAX);
      cons_p.commit(-MAX + 1, 0);
      auto cons_n = mip.constraint();
      cons_n.add_variable(pn[excess], -1);
      cons_n.add_variable(pn[n], -MAX);
      cons_n.commit(-MAX + 1, 0);
      auto cons = mip.constraint();
      cons.add_variable(pn[p], 1);
      cons.add_variable(pn[n], 1);
      cons.commit(1, 2);
    }
  }
  // Solve and print.
  auto sol = mip.solve();
  for (int j = 0; j < h; j++) {
    cout << board[j] << "\n";
  }
  cout << "--\n";
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      if (sol.value(red[j][i]) > 0.5) {
        cout << 'r';
      } else {
        cout << 'b';
      }
    }
    cout << "\n";
  }
  cout << "\n";
}
