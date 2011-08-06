# Evaluate the nth prime using a formula based on Wilson's theorem.
# Due to the limited precision of python's float implementation,
# it's only reliable up to n=6.

# Ricardo Bittencourt 2008

import math

def factorial(j, memo={}):
  if j not in memo:
    memo[j] = 1.0 if j < 2 else j * factorial(j-1)
  return memo[j]

def F(j, memo={}):
  if j not in memo:
    arg = math.pi * (factorial(j-1) + 1.0) / j
    memo[j] = math.floor(math.cos(arg)**2)
  return memo[j]

def nth_prime(n):
  sumF = lambda m: sum(F(j) for j in range(1, 1+m))
  return 1 + sum(math.floor(math.floor(n / sumF(m))**(1.0 / n))
                 for m in range(1, 1 + 2**n))

print [nth_prime(i) for i in range(1, 7)]
