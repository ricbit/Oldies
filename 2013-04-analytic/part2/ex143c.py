# Cayley-Polya number
# O(n^2) implementation
# O(n sqrt n) preprocessing

def factorize(n):
  s = int(n ** 0.5) + 2
  for f in xrange(2, s):
    if n == 1:
      break
    if n % f == 0:
      count = 0
      while n % f == 0:
        count += 1
        n /= f
      yield (f, count)
  if n != 1:
    yield (n, 1)

def divisors(n):
  def gendivisors(x, remaining):
    if not remaining:
      yield x
    else:
      base, exp = remaining[0]
      for e in xrange(exp + 1):
        for elem in gendivisors(x * (base ** e), remaining[1:]):
          yield elem
  return gendivisors(1, list(factorize(n)))

def proper_divisors(n):
  for d in divisors(n):
    if d != n:
      yield d

h = [0, 1]
acc = [0, 1]
for n in xrange(2, 4000):
  acc.append(sum(d * h[d] for d in proper_divisors(n)))
  h.append(sum(acc[j] * h[n - j] for j in xrange(1, n)) / (n - 1))
  acc[-1] += n * h[-1]
print h

