# Cayley-Polya number
# O(n^2 log n) implementation

h = [0, 1]
for n in xrange(2, 1000):
  ans = 0
  for m in xrange(1, n):
    for j in xrange(1, n / m + 1):
      ans += m * h[m] * h[n - m * j]
  h.append(ans / (n - 1))
print h
