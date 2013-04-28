# Solve the recurrence
# a(n)=a(n-1)-2a(n-1)/n+2(1-2a(n-1)/n)

import fractions as f

a=[f.Fraction(0,1)]
for i in xrange(1,20):
  a.append(a[-1]-2*a[-1]/i+2*(1-2*a[-1]/i))
b=[]
for i in xrange(0,20):
  b.append(f.Fraction(2,1)*(i+1)/7)
print zip(a,b)
