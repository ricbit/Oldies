# Count how many permutations of size N have only cycles of odd length.

import itertools, fractions

def no_even(p):
  for start in p:
    if start == p[start]:
      continue

    count, cur = 1, p[start]
    while cur != start:
       count += 1
       cur = p[cur]
    if count % 2 == 0:
      return False
  return True

def count_odd_perms(n):
  ans = 0
  for p in itertools.permutations(range(n)):
    if no_even(p):
      ans += 1
  return ans

def fact(i):
  return 1 if i == 0 else i * fact(i - 1)

for i in range(1,8):
  a = count_odd_perms(i)
  print fractions.Fraction(a, fact(i))
