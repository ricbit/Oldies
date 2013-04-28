# Solve the recurrence a(n)=3a(n-1)-3a(n-2)+a(n-3)

import math

def original():
  a=[0,1,1]
  for x in xrange(20):
    a.append(3*a[-1]-3*a[-2]+a[-3])
  return a

a = original()
for i in xrange(20):
  print i,a[i],i*(3-i)/2
