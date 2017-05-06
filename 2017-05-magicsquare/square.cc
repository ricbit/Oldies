// Solves the magic square.
// by Ricardo Bittencourt 2017

#include <iostream>
#include "easyscip.h"

using namespace std;
using namespace easyscip;

// Given the partially completed square below, fill in with numbers in the
// given set in a way each row and column sum to 45. Repeated numbers 
// are allowed.
//
// | .  .  .  . |
// | 5  .  12 . |
// | .  .  .  4 |
// | .  .  6  . |
//
// set = {9, 17, 14, 22, 3, 10, 11, 20, 8, 15, 1, 18, 5, 12, 4, 16}
//
// This code finds the answer with the least repetitions.

bool check(int goal_sum) {
  // Create a MIPSolver using EasySCIP.
  MIPSolver solver;

  // Add one binary variable for each assignment between number and cell.
  int numbers[] = {9, 17, 14, 22, 3, 10, 11, 20, 8, 15, 1, 18, 5, 12, 4, 16};
  vector< vector<Variable> > var(16);
  for (int i = 0; i < 16; i++) {
    for (int j = 0; j < 16; j++) {
      var[i].push_back(solver.binary_variable(0));
    }
  }

  // Here we're creating the constraint for horizontals.
  for (int j = 0; j < 4; j++) {
    Constraint h = solver.constraint();
    // Add all relevant variables to the constraint.
    for (int i = 0; i < 4; i++) {
      for (int k = 0; k < 16; k++) {
        h.add_variable(var[k][j * 4 + i], numbers[k]);
      }
    }
    // Commit the constraint to the solver.
    h.commit(goal_sum, goal_sum);
  }

 // Here we're creating the constraint for verticals.
  for (int j = 0; j < 4; j++) {
    Constraint v = solver.constraint();
    // Add all relevant variables to the constraint.
    for (int i = 0; i < 4; i++) {
      for (int k = 0; k < 16; k++) {
        v.add_variable(var[k][i * 4 + j], numbers[k]);
      }
    }
    // Commit the constraint to the solver.
    v.commit(goal_sum, goal_sum);
  }

  // Integer variable to count repetitions.
  vector<Variable> reps;
  for (int j = 0; j < 16; j++) {
    reps.push_back(solver.binary_variable(1));
  }

  // Count number of repetitions.
  for (int i = 0; i < 16; i++) {
    Constraint h = solver.constraint();
    // Add all relevant variables to the constraint.
    for (int j = 0; j < 16; j++) {
        h.add_variable(var[i][j], 1);
    }
    h.add_variable(reps[i], -17);
    // Commit the constraint to the solver.
    // (Change the interval to (-16, 0) to get the solution with least numbers)
    h.commit(-16, 1);
  }

  // Each cell must have just one number.
  for (int i = 0; i < 16; i++) {
    Constraint number = solver.constraint();
    for (int j = 0; j < 16; j++) {
      number.add_variable(var[j][i], 1);
    }
    number.commit(1, 1);
  }

  // Givens.
  int given_index[] = {12, 13, 14, 15}; // These are indexes of {5, 12, 4, 6}
  int given_pos[] = {4, 6, 11, 13};
  for (int i = 0; i < 4; i++) {
    Constraint g = solver.constraint();
    g.add_variable(var[given_index[i]][given_pos[i]], 1);
    g.commit(1, 1);
  }

  // Solve the MIP model.
  Solution sol = solver.solve();
  if (!sol.is_feasible()) {
    return false;
  }

  // Print solution.
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      for (int k = 0; k < 16; k++) {
        if (sol.value(var[k][i * 4 + j]) > 0.5) {
          cout << numbers[k] << " ";
        }
      }
    }
    cout << "\n";
  }

  return true;
}

int main() {
  check(45);
  return 0;
}
