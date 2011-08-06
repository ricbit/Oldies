// Monte Carlo simulation for password reconstruction.
// Ricardo Bittencourt 2008

#include <cstdio>
#include <vector>
#include <limits>
#include <algorithm>
#include <functional>
#include <ext/functional>
#include <ext/numeric>

using namespace std;
using namespace __gnu_cxx;

#include "exactcover.h"

int random10() {
  static subtractive_rng random;
  return random(10);
}

int solve(vector<int>& password, vector< vector<int> >& shuffle) {
  int size = shuffle.size();
  vvb mat(40, vb(4+size*4, false));

  for (int j = 0; j < size; j++)
    for (int i = 0; i < 4; i++)
      for (int k = 0; k < 10; k++)
        if (shuffle[j][k] == password[i]) {
          int pos = k & (~1);
          mat[i*10 + shuffle[j][pos]][i + j*4] = true;
          mat[i*10 + shuffle[j][pos + 1]][i + j*4] = true;
        }

  for (int j = 0; j < 4; j++)
    for (int i = 0; i < 10; i++)
      mat[j*10 + i][size*4 + j] = true;

  count_solutions out;
  exactcover<count_solutions> cover(mat, out);
  cover.solve();
  return out.total;
}

int main(void) {
  const int experiment_size = 100000;
  double len1 = 0.0, len3 = 0.0;

  for (int t = 0; t < experiment_size; t++) {
    vector<int> password(4);
    generate_n(password.begin(), 4, random10);

    int current = numeric_limits<int>::max();
    vector< vector<int> > shuffle;
    bool reached = false;
    do {
      vector<int> range(10);
      iota(range.begin(), range.end(), 0);
      random_shuffle(range.begin(), range.end());
      shuffle.push_back(range);
      current = solve(password, shuffle);
      len1 += 1.0;
      if (!reached) {
        len3 += 1.0;
        if (current <= 3)
          reached = true;
      }
    } while (current > 1);
  } 

  printf ("Expected length in 1 try: %lf\n", len1 / experiment_size);
  printf ("Expected length in 3 tries: %lf\n", len3 / experiment_size);
  return 0;
}
