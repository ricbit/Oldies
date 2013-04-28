# Finds the combination of four coins that maximizes the number
# of ways to change a dollar.

import itertools

def polya(coins):
  change = [1] + [0] * 100
  for coin in coins:
    for m in xrange(coin, 101):
      change[m] = change[m - coin] + change[m]
  return change[100]

best = (0,[])
for coins in itertools.combinations(xrange(1,101), 4):
  ways = polya(coins)
  if ways > best[0]:
    best = (ways, coins)
print best
