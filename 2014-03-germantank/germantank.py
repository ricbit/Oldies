import random

T = 10000
K = 3
MAX = 10000
for tries in xrange(T):
  n = random.randint(K, MAX)
  s = max(random.sample(range(n), K))
  estim = float(s - 1) * (K - 1) / float(K - 2)
  error = (n - estim) / float(n)
  print error
