# Cayley-Polya number
# O(n^2) implementation
# O(n^2) preprocessing

h = [0, 1]
acc = [0, 1]
for n in xrange(2, 1000):
  acc.append(sum(d * h[d] for d in xrange(1,n) if n % d == 0))
  h.append(sum(acc[j] * h[n - j] for j in xrange(1, n)) / (n - 1))
  acc[-1] += n * h[-1]
print h
