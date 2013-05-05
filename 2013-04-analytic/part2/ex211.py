# Count how many words of size n, over an alphabet of size alpha,
# have exactly let letters appearing an even number of times.

import itertools

alpha = 5
let = 2
for n in xrange(8):
  ans = 0
  for word in itertools.product(range(alpha), repeat=n):
    hist = {i:0 for i in range(alpha)}
    for w in word:
      hist[w] += 1
    count = sum(1 for k,v in hist.iteritems() if v % 2 == 0)
    if count == let:
      ans += 1
  print n, ans
