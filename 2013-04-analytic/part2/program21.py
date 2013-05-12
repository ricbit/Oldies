import random
import sys

def simulate(steps):
  pos = [True] *  10**3
  for _ in xrange(steps):
    n = random.randrange(0, 10**3)
    pos[n] = not pos[n]
  return sum(pos)

steps, samples = map(int, sys.argv[1:3])
hist = [0] * 10**3
for _ in xrange(samples):
  hist[simulate(steps)] += 1

print " ".join(map(str, hist[::2]))
