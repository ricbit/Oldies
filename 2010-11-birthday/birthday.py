# Birthday paradox: exact value, poisson approximation and monte carlo
# Ricardo Bittencourt 2010

import math
import random

def fact(x):
  if x == 0: return 1
  return reduce(lambda x,y:x*y, range(1, x+1))

def bin(n, p):
  return fact(n)/fact(p)/fact(n-p)

def exact(m, n, r):
  return n*bin(m, r)*((1.0/n)**r)*((1.0-1.0/n)**(m-r))

def poisson(m, n, r):
  mn = float(m)/float(n)
  return n*math.exp(-mn)*(mn**r)/fact(r)

def collisions(m ,n, r):
  a = [random.randrange(0, n) for i in range(0, m)]
  d = {}
  for i in a:
    if i not in d:
      d[i] = 1
    else:
      d[i] += 1
  s = 0
  for x in d.itervalues():
    if x==r: s += 1
  return s

def montecarlo(m, n, r):
  s = 0
  for t in range(0, 10000):
    k = collisions(m, n, r)
    s += k
  return s / 10000.0

print exact(70, 700, 2)
print poisson(70, 700, 2)
print montecarlo(70, 700, 2)
