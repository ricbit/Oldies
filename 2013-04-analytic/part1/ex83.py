# Count how many words of N-bits have a run of P-consecutive zeros,
# by performing TRIES random tries.

import random

def sample(p, n):
  count = 0
  for i in xrange(n):
    if random.randint(0,1) == 0:
      count += 1
    else:
      count = 0
    if count == p:
      return True
  return False

def count(p, n, tries):
  ans = 0.0
  for i in xrange(tries):
    ans += sample(p, n)
  return ans / tries

print count(3, 10, 5000)

