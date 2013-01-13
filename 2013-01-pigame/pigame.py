import math

def pi(n):
  return int(math.floor(math.pi * n))

sequence = []
period = 1
current = 0
while True:
  value = pi(current + 2) - pi(current + 1) 
  sequence.append(value)
  if value != sequence[current % period]:
    period = current + 1
    print "p >=", period
  current += 1
