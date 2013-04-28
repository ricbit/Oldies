# Count how many inversions there are in all involution of size N,
# breaking by cases.

import itertools

def is_involution(p):
  for x in p:
    if not (p[x] == x or p[p[x]] == x):
      return False
  return True

def inversions(p):
  ans = 0
  for i, x in enumerate(p):
    ans += sum(1 for y in p[:i] if y > x)
  return ans

def generate1(n, a, b):
  ans = 0
  for p in itertools.permutations(xrange(n)):
    if is_involution(p) and p[a]==b and p[b]==a:
      ans += 1
      #print p
  return ans

def generate2(n, a, b):
  ans = 0
  for p in itertools.permutations(xrange(n)):
    if is_involution(p):
      ai, bi = p.index(a), p.index(b)
      if bi < ai:
        if p[a]==a and p[b]!=b and p[p[b]]==b:
          ans += 1
        if p[b]==b and p[a]!=a and p[p[a]]==a:
          ans += 1
  return ans

def generate3(n, a, b):
  ans = 0
  for p in itertools.permutations(xrange(n)):
    if is_involution(p):
      ai, bi = p.index(a), p.index(b)
      if bi < ai:
        if p[p[a]]==a and p[p[b]]==b and p[a]!=a and p[b]!=b and p[a]!=b:
          ans += 1
  return ans

def involutions(n):
  ans = 0
  for p in itertools.permutations(xrange(n)):
    if is_involution(p):
      ans += 1
  return ans

def invinv(n):
  ans = 0
  for p in itertools.permutations(xrange(n)):
    if is_involution(p):
      ans += inversions(p)
  return ans

def count(n, gen):
  ans = 0
  for a in xrange(1, n + 1):
    for b in xrange(a + 1, n + 1):
      ans += gen(n, a-1, b-1)
  return ans

invol = [involutions(i) for i in xrange(0,8)]
iinvol = [invinv(i) for i in xrange(0,8)]
invol[0]=iinvol[0]=0

def show(n):
  a = count(n, generate1)
  b = count(n, generate2)
  c = count(n, generate3)
  print n, iinvol[n], a+b+c
  print "a -- ", a, n*(n-1)*invol[n-2]/2
  print "b -- ", b, (n**3-3*n*n+2*n)*invol[n-3]/3
  print "c -- ", c, n*(n-1)*(n*n-5*n+6)*invol[n-4]/4

for i in xrange(1,8):
  show(i)
