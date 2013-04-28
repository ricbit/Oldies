import math
n = 10.0
tot = 500
ans = 0.0
for k in xrange(tot):
  a,b,c= (k*k/n,k/n,k*k/n/n)
  print k, "%f %f %f" % (a,b,c), math.exp(-(a+b+c)/2)
  ans += math.exp(-(a+b+c)/2)
print ans
print (math.pi*n/2)**.5
