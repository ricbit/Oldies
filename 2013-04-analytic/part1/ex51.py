# Count how many bitstrings of size N have no "000".

for n in xrange(1,20):
  ans = 0
  for x in xrange(2**n):
    b = ("0"*n+bin(x)[2:])[-n:] 
    if "000" not in b:
      ans += 1
  asy = 1.13745 * 1.83929**n 
  print n, ans, asy, (asy-ans)/ans
