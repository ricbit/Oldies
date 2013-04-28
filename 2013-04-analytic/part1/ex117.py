# Check how good is the asymptotic on exercise 1.17

import fractions

def f(a,b):
  return fractions.Fraction(a,b)

def original(n,m):
  x = [f(1,4)*i*(i-1) for i in xrange(0,m+1)]
  for k in xrange(m+1, n+1):
    x.append(k+1+f(1,k)*(sum(x[j-1]+x[k-j] for j in xrange(1,k+1))))
  return x

def h(n):
  return sum(f(1,x) for x in xrange(1,n+1))

def magic(n,m):
  x = [f(1,4)*i*(i-1) for i in xrange(0,m+1)]
  x.append((m+2)+f(m,1)*(m-1)/6)
  for k in xrange(m+2, n+1):
    x.append(f(k+1,1)*(f(1,1)+f(m,1)*(m-1)/6/(m+2) + 2*(h(k+1)-h(m+2))))
  return x

print original(10,3)
print magic(10,3)
