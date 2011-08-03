// Solver for the 6x6 Irregular Sudoku
// Ricardo Bittencourt 2008

#include <cstdio>
#include <vector>

using namespace std;

#include "exactcover.h"

// callback to print the solutions found.
struct print_solution {
  void operator()(const vector<int>& solution) {
    char tab[6][7];
    memset(tab, 0, sizeof tab);
    typedef typeof(solution.begin()) iterator;
    for (iterator it = solution.begin(); it != solution.end(); ++it)
      tab[*it / 36][*it / 6 % 6] = '1' + *it%6;
    for (int i = 0; i < 6; i++)
      puts(tab[i]);
    puts("");
  }
};

int main(void) {
  // read the grid from stdin.
  char grid[6][7], given[6][7];
  for (int i = 0; i < 6; i++)
    scanf("%s", grid[i]);
  for (int i = 0; i < 6; i++)
    scanf("%s", given[i]);

  // build the exact cover matrix.
  vvb mat(6*6*6, vb(36*4, false));
  for (int digit = 0; digit < 6; digit++)
    for (int row = 0; row < 6; row++)
      for (int col = 0; col < 6; col++) {
        if (given[row][col] != '-' && given[row][col]-'1' != digit)
          continue;
        int i = digit + col*6 + row*6*6;
        mat[i][col + row*6] = true;
        mat[i][36 + row*6 + digit] = true;
        mat[i][36*2 + col*6 + digit] = true;
        int box = grid[row][col] - 'a';
        mat[i][36*3 + box*6 + digit]=true;
      }

  // print the solution.
  print_solution out;
  exactcover<print_solution> cover(mat, out);
  cover.solve();

  return 0;
}
