import itertools

for x in xrange(input()):
  s = [c for c in raw_input().lower() if c.isalpha()]
  s.sort()
  s = [len(list(g)) for k,g in itertools.groupby(s)]
  s.sort(reverse=True)
  ans = sum(i * q for i,q in zip(xrange(26,0,-1), s))
  print "Case #%d: %d" % (x + 1, ans)

