import sys
inc = set()
for line in sys.stdin:
  bah, includfile = line.split()
  inc.add(includfile)
for i in sorted(list(inc)):
  print i

