import math, operator, fractions

S = math.factorial(45)
S /= reduce(operator.mul, map(math.factorial, range(1,10)))
S *= sum(i**2 for i in range(1,10))
S /= 45

d = [0]
c = [0]
for i in xrange(46):
  print d[-1], c[-1]
  x = S + c[-1]
  d.append(x % 10)
  c.append(x / 10)
print c[-1]
print int(sum(fractions.Fraction(S, 10**i) for i in xrange(1,70)))
print S
