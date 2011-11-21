# Midterm question 7

import random
pbc = 0
p_bc = 0
pcb = 0
p_cb = 0
for _ in xrange(1000000):
  if random.random() < 0.5:
    b = random.random() < 0.2
    c = random.random() < 0.8
  else:
    b = random.random() < 0.2
    c = random.random() < 0.4
  if c:
    if b:
      pbc += 1
    else:
      p_bc += 1
  if b:
    if c:
      pcb += 1
    else:
      p_cb += 1
print float(pbc) / (pbc + p_bc)
print float(pcb) / (pcb + p_cb)
