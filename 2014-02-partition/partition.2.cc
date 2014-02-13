// Solves the graph partition problem using EasySCIP.
// by Ricardo Bittencourt 2014

// This model uses less memory, but it's slower than the other.

#include <iostream>
#include <string>
#include <sstream>
#include "easyscip.h"

using namespace std;
using namespace easyscip;

int main() {
  // Create a MIPSolver using EasySCIP.
  MIPSolver solver;

  const int colors = 3;
  const double equal_partition_weight = 2.0;
  const double violation_weight = 1.0;

  int nodes, edges;
  string line;
  getline(cin, line);
  istringstream iss(line);
  iss >> nodes >> edges;

  // Read edge list.
  vector<pair<int, int>> edge;
  for (int i = 0; i < nodes; i++) {
    string line;
    getline(cin, line);
    istringstream iss(line);
    int value;
    while (iss >> value) {
      value--;
      if (i < value) {
        edge.push_back(make_pair(i, value));
      }
    }
  }

  // The node has this color.
  vector<vector<Variable>> has(nodes);
  for (int i = 0; i < nodes; i++) {
    for (int j = 0; j < colors; j++) {
      has[i].push_back(solver.binary_variable(0));
    }
  }

  // This edge links nodes of different colors.
  vector<Variable> violationpos, violationneg, violation;
  for (int i = 0; i < edges; i++) {
    violationpos.push_back(solver.integer_variable(0, 2 * colors, 0));
    violationneg.push_back(solver.integer_variable(0, 2 * colors, 0));
    violation.push_back(solver.binary_variable(violation_weight));
  }

  // Count abs(nodes with color n - (total nodes / colors)).
  vector<Variable> sizepos, sizeneg;
  for (int i = 0; i < colors; i++) {
    sizepos.push_back(solver.integer_variable(0, nodes, equal_partition_weight));
    sizeneg.push_back(solver.integer_variable(0, nodes, equal_partition_weight));
  }

  // A node can have only one color
  for (int i = 0; i < nodes; i++) {
    Constraint cons = solver.constraint();
    for (int j = 0; j < colors; j++) {
      cons.add_variable(has[i][j], 1);
    }
    cons.commit(1, 1);
  }

  // Minimize the difference between size of partitions.
  for (int i = 0; i < colors; i++) {
    Constraint cons = solver.constraint();
    for (int j = 0; j < nodes; j++) {
      cons.add_variable(has[j][i], 1);
    }
    cons.add_variable(sizepos[i], -1);
    cons.add_variable(sizeneg[i], 1);
    cons.commit(nodes / colors, nodes / colors);
  }

  // Minimize the number of edges connecting nodes of different colors.
  for (int i = 0; i < edges; i++) {
    Constraint cons = solver.constraint();
    for (int j = 0; j < colors; j++) {
      cons.add_variable(has[edge[i].first][j], 1 + j);
      cons.add_variable(has[edge[i].second][j], -1 - j);
    }
    cons.add_variable(violationpos[i], -1);
    cons.add_variable(violationneg[i], 1);
    cons.commit(0, 0);
  }

  // Give equal weight to all edges.
  for (int i = 0; i < edges; i++) {
    Constraint cons = solver.constraint();
    cons.add_variable(violationpos[i], 1);
    cons.add_variable(violationneg[i], 1);
    cons.add_variable(violation[i], -2 * colors);
    cons.commit(1 - 2 * colors, 0);
  }

  // The first node must have color 0 to break the symmetry.
  Constraint zero = solver.constraint();
  zero.add_variable(has[0][0], 1);
  zero.commit(1, 1);

  // Node n can only have color c if there is at least
  // one node m where m < n and color(m) == c - 1.
  for (int i = 1; i < nodes; i++) {
    for (int j = 1; j < colors; j++) {
      Constraint cons = solver.constraint();
      for (int k = 0; k < i; k++) {
        cons.add_variable(has[k][j - 1], 1);
      }
      cons.add_variable(has[i][j], -1);      
      cons.commit(0, nodes);
    }
  }

  // Solve the MIP model.
  solver.set_time_limit(6 * 60 * 60);
  Solution sol = solver.solve();

  // Print solution.
  cout << "start\n";
  cout << nodes << " " << edges << "\n";
  for (int i = 0; i < nodes; i++) {
    for (int j = 0; j < colors; j++) {
      if (sol.value(has[i][j]) > 0.5) {
        cout << j;
      }
    }
    for (int j = 0; j < edges; j++) {
      if (edge[j].first == i) {
        cout << " " << 1 + edge[j].second;
      }
      if (edge[j].second == i) {
        cout << " " << 1 + edge[j].first;
      }
    }
    cout << "\n";
  }

  return 0;
}
