def search(a, b, r, t):
  while b - a > 1:
    m = (b + a) / 2
    if (1 + m) * (1 + 2 * (r + m)) <= t:
      a = m
    else:
      b = m
  return a + 1

for testcase in xrange(1, 1 + input()):
  r, t = map(int, raw_input().split())
  circles = search(0, t, r, t)
  print "Case #%d: %d" % (testcase, circles)
