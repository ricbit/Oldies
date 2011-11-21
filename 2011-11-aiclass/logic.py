# Logic, midterm 12

import sys

def imp(a,b):
  return not(a and not b)

def eqv(a,b):
  return a == b

for exp in sys.stdin:
  trues = 0
  falses = 0
  for i in range(8):
    a = (i & 1) > 0
    b = (i & 2) > 0
    c = (i & 4) > 0
    if eval(exp.strip()):
      trues += 1
    else:
      falses += 1
  if trues and not falses:
    print "valid"
  elif falses and not trues:
    print "unsat"
  else:
    print "sat"
