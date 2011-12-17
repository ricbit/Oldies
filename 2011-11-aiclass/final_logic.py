# Logic, final 5

import sys

def imp(a,b):
  return not(a and not b)

def eqv(a,b):
  return a == b

def tautology(exp):
  trues = 0
  falses = 0
  for i in range(4):
    pink = (i & 1) > 0
    green = (i & 2) > 0
    if eval(exp):
      trues += 1
    else:
      falses += 1
  return trues and not falses

expressions = ["pink",
               "pink or green",
               "pink and green",
               "imp(not pink, green)"]

for row in expressions:
  for col in expressions:
    exp = "imp(%s, %s)" % (row, col)
    print exp, tautology(exp)
