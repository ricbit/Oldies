import math

def s(n):
  k0 = n**(2/3.)
  ans = 0
  for k in xrange(0,int(k0)):
    ans += k/float(n)*math.exp(-k*k/2.0/n)
  return ans

for i in xrange(6):
  print s(10**i)
