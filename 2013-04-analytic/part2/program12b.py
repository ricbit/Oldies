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

def smart_div(a, b):
  sa, sb = str(a), str(b)
  m = min(len(sa), len(sb))
  if m < 15:
    return float(a)/b
  x = m - 10
  na, nb = float(sa[:-x]), float(sb[:-x])
  return na/nb

p = [1, 1]
sigma = [0, 1]
for n in xrange(2, 4000):
  sigma.append(sum(divisors(n)))
  p.append(sum(sigma[j] * p[n - j] for j in xrange(1, 1 + n)) / n)

for b,a in zip(p[1:], p[2:]):
  print smart_div(a, b)

