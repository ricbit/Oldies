# Count how many binary trees of size N are balanced.
# This will be non-zero only when N=2^k-1.

import itertools
 
def is_balanced(x):
  if len(x) == 1:
    return True
  less = [i for i in x[1:] if i < x[0]]
  more = [i for i in x[1:] if i > x[0]]
  if len(less) != len(more):
    return False
  return is_balanced(less) and is_balanced(more)
 
def count_balanced(n):
  ans = 0
  for p in itertools.permutations(xrange(n)):
    if is_balanced(p):
      ans += 1
  return ans
 
def fact(i):
  return 1 if i == 0 else i*fact(i-1)

for i in xrange(1, 8):
  print i, count_balanced(i), 4*i*(0.388386)**(i+1)*fact(i)
