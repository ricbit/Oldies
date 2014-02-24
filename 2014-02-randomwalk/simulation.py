import math, random

n = 1000
samples = 100000
average_position = 0.0
average_distance = 0.0
occurrences_zero = 0.0
for i in xrange(samples):
  pos = 0
  for j in xrange(n):
    if random.random() > 0.5:
      pos += 1
    else:
      pos -= 1
  average_position += pos
  average_distance += abs(pos)
  if pos == 0:
    occurrences_zero += 1
print "average position: %.2f" % (average_position / samples)
print "expected value of position: %.2f" % 0
print "average distance: %.2f" % (average_distance / samples)
print "expected value of distance: %.2f" % ((2 * n / math.pi) ** 0.5)
print "actual occurrences of zero: %.2f%%" % (100.0 * occurrences_zero / samples)
print "estimated probability of zero: %.2f%%" % (100.0 * (2.0 / n / math.pi) ** 0.5)


