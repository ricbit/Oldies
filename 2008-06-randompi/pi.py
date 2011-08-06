# Script to evaluate Pi using random numbers
# Ricardo Bittencourt 2008

import random

size = 100000000
dump = 100000
acc = 0
for i in xrange(size):
  x = random.random()
  y = random.random()
  if x*x + y*y <= 1.0:
    acc += 1
  if i % dump == dump - 1:
    print 4.0 * acc / i
