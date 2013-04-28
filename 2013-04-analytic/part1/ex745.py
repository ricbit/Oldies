# Count how many inversions there are in an all involutions of size N.

import itertools

def is_involution(p):
  for x in p:
    if not (p[x] == x or p[p[x]] == x):
      return False
  return True

def inversions(p):
  ans = 0
  for i, x in enumerate(p):
    ans += sum(1 for y in p[:i] if y > x)
  return ans

def generate(n):
  ans = 0
  for p in itertools.permutations(xrange(n)):
    if is_involution(p):
      ans += inversions(p)
  return ans

for i in xrange(1,7):
  print i, generate(i)
