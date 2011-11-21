# Loaded coin, midterm 5

import random

single_p2 = 0
single_total = 0
double_p2 = 0
double_total = 0
for _ in xrange(1000000):
  p1 = random.random() < 0.5
  head1 = True
  if p1:
    head1 = random.random() < 0.5
  head2 = False
  if head1:
    head2 = True
    if p1:
      head2 = random.random() < 0.5
  if head1:
    single_total += 1
    if not p1:
      single_p2 += 1
  if head2:
    double_total += 1
    if not p1:
      double_p2 += 1
print float(single_p2) / single_total
print float(double_p2) / double_total
