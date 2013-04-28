# Calculate the first terms of the recurrence
# a_n=3*a_(floor(n/3))

import math

def original():
  a=[0,1,1,1]
  for n in xrange(4,10000):
    a.append(3*a[n/3]+n)
  return a

ori = original()
print "a=[%s];" % ',\n'.join(map(str,[i*(-2/3.+math.log(i,3))-x for i,x in enumerate(ori[:973]) if i > 0]))
#for i in xrange(1,7):
#  print 3**i, ori[3**i], 3**i * (i-2/3.)
  
