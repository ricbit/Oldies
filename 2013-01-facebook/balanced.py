for t in xrange(input()):
  prev = set([0])
  last = False
  for c in raw_input():
    old = prev
    if c == '(':
      prev = set([i + 1 for i in prev])
    elif c == ')':
      prev = set([i - 1 for i in prev])
    if last:
      prev = prev.union(old)
    last = c == ':'
    prev = set([i for i in prev if i >= 0])
  if 0 in prev:
    print 'Case #%d: YES' % (t + 1)
  else:
    print 'Case #%d: NO' % (t + 1)
      
