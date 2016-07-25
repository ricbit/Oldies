import random

def bozo_search(i, a, b):
  x = random.randint(a, b)
  if x == i:
    return 1
  if x > i:
    return 1 + bozo_search(i, a, x - 1)
  else:
    return 1 + bozo_search(i, x + 1, b)

def binary_search(i, a, b):
  x = (a + b + 1) / 2
  if x == i:
    return 1
  if x > i:
    return 1 + binary_search(i, a, x - 1)
  else:
    return 1 + binary_search(i, x + 1, b)

n = 3000
acc = 0
bacc = 0
M = 50000
for x in xrange(M):
  acc += bozo_search(random.randint(0, n - 1), 0, n - 1)
  bacc += binary_search(random.randint(0, n - 1), 0, n - 1)
print float(acc) / M
print float(bacc) / M
  
