import itertools

def gen_palin():
  for i in xrange(1, 10):
    yield i
  for n in itertools.count(2):
    if n % 2 == 0:
      half = n / 2
      for i in xrange(10**(half-1), 10**half):
        s = str(i)
        yield int(s + s[::-1])
    else:
      half = int(n / 2)
      for i in xrange(10**(half-1), 10**half):
        s = str(i)
        for j in xrange(10):
          yield int(s+str(j)+s[::-1])


def is_palin(p):
  s = str(p)
  return s==s[::-1]

def count(a,b):
  ans = 0
  for p in gen_palin():
    p2 = p**2
    if p2 < a:
      continue
    if p2 > b:
      break
    if is_palin(p2):
      ans += 1
      print p,p2
  return ans


for testcase in xrange(input()):
  a,b = map(int, raw_input().split())
  print "Case #%d: %d" % (1 + testcase, count(a,b))
