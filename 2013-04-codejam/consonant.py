vowels = "aeiou"

for tc in xrange(1, 1 + input()):
  name, n = raw_input().split()
  n = int(n)
  start = [False] * len(name)
  cons = 0
  for i, c in enumerate(name):
    if c in vowels:
      cons = 0
    else:
      cons += 1
    if cons >= n:
      start[i - n + 1] = True

  last = [-1] * len(name)
  cur = -1
  for i, has in enumerate(start):
    last[i] = cur
    if has:
      cur = i

  ans = 0
  for i, begin in enumerate(last):
    if start[i]:
      a = begin + 1
      b = len(last) - n
      # FullSimplify[
      # Sum[Min[i, bb - j] - Max[i - j, aa] + 1, {j, 0, bb - aa}], 
      # Assumptions -> bb >= i >= aa >= 0 && Element[aa | bb | i, Integers]]
      if a < b and a >= i:
        ans += (a - b - 1) * (a - i - 1)
      elif (a == b and a + b >= 2 * i) or (a + b < 2 * i and b == i):
        ans += 1 - a + i
      elif a + b == 2 * i and a < i and b > i:
        ans += (1 + b - i) ** 2
      else:
        ans += (a - i - 1) * (i - b - 1)
  print "Case #%d: %d" % (tc, ans)
