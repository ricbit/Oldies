# Check how long a word of N symbols must be to have a sequence "123".

import random

def search(n):
  pos = 1
  cur = 0
  while True:
    a = random.randint(1, n)
    if a == 1:
      cur = 1
    elif cur == 1 and a == 2:
      cur = 2
      return pos
    elif cur == 2 and a == 3:
      return pos
    else:
      cur = 0
    pos += 1

ans = 0.0
tries = 10000
for x in xrange(tries):
  ans += search(32)
print ans / tries
