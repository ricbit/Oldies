for testcase in xrange(input()):
  row, col = map(int, raw_input().split())
  lawn = [map(int, raw_input().split()) for _ in xrange(row)]
  maxrow = [max(r) for r in lawn]
  maxcol = [max(c) for c in zip(*lawn)]
  ans = True
  for r in xrange(row):
    for c in xrange(col):
      if lawn[r][c] != min(maxrow[r], maxcol[c]):
        ans = False
  print "Case #%d: %s" % (1+testcase, "YES" if ans else "NO")
