import random, sys

def cycles(x):
  ans = 0
  visited = [False] * len(x)
  for i in xrange(len(x)):
    if visited[i]:
      continue
    j = i
    while not visited[j]:
      visited[j] = True
      j = x[j]
    ans += 1
  return ans

hist = {}
n = sys.argv[1]
for _ in xrange(1000):
  x = range(10**int(n))
  random.shuffle(x)
  c = cycles(x)
  if c not in hist:
    hist[c] = 0
  hist[c] += 1

out = [str(hist.get(i, 0)) for i in xrange(1+max(hist.keys()))]
print " ".join(out)
