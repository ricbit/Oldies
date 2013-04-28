# Count how many random mapping of size N have no singleton cycles.

import itertools

def count(n):
  ans = 0
  for p in itertools.product(range(n), repeat=n):
    for i, val in enumerate(p):
      if i == val:
        break
    else:
      ans += 1
  return ans

for n in xrange(1,9):
  print count(n)
