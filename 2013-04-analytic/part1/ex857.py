# Calculate the first terms of the recurrence 
# p_n = sum(binomial(n,k)*p_k)/2^n

from fractions import Fraction as f

def factorial(n):
  return f(1,1) if n <= 1 else n * factorial(n-1)

def binomial(a, b):
  return factorial(a) / factorial(b) / factorial (a-b)

p = [0,1]
for n in xrange(2, 10):
  s = f(0,1)
  for k in xrange(0, n):
    s += f(1, 2**n) * binomial(n, k) * p[k]
  s /= f(1,1)-f(1,2**n)
  p.append(s)


for a in enumerate(p):
  print a
