import random, sys

def cycles(x):
  for i, v in enumerate(x):
    if v==x[v] or v==x[x[v]]:
      return True
  return False

derang = 0
n = sys.argv[1]
tot = 100000
for _ in xrange(tot):
  x = range(int(n))
  random.shuffle(x)
  if not cycles(x):
    derang += 1

print float(derang) / tot
