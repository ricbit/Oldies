# Homework 6-3

import random

def getx(a):
  if a:
    return random.random() < 0.1
  else:
    return random.random() < 0.8

total_x0 = 0
total_x0x1 = 0
a0_x0 = 0
a1_x0 = 0
a1_x0x1 = 0
total = 1000000
for i in xrange(total):
  a0 = random.random() < 0.5
  x0 = getx(a0)
  a1 = (not a0) if random.random() < 0.5 else a0
  x1 = getx(a1)
  if x0:
    total_x0 += 1
    if a0:
      a0_x0 += 1
    if a1:
      a1_x0 += 1
  if x0 and x1:
    total_x0x1 += 1
    if a1:
      a1_x0x1 += 1
print "P(a0|x0) = ", a0_x0 / float(total_x0)
print "P(a1|x0) = ", a1_x0 / float(total_x0)
print "P(x1x0) = ", total_x0x1 / float(total)
print "P(a0|x0x1) = ", a1_x0x1 / float(total_x0x1)
