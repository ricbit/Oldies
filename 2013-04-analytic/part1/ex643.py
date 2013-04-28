# Count the amount of interal nodes in all binary trees of size N,
# grouping by number of external children.

import itertools

def insert(p, elem):
  if elem < p[0]:
    if p[1] is None:
      p[1] = [elem, None, None]
    else:
      insert(p[1], elem)
  else:
    if p[2] is None:
      p[2] = [elem, None, None]
    else:
      insert(p[2], elem)

def build_tree(p):
  root = [p[0], None, None]
  for elem in p[1:]:
    insert(root, elem)
  return root  

def count(p, two, one, zero):
  if p[1] is None and p[2] is None:
    return two, one, zero + 1
  if p[1] is not None and p[2] is not None:
    return count(p[1], *count(p[2], two + 1, one, zero))
  if p[1] is None:
    return count(p[2], two, one + 1, zero)
  else:
    return count(p[1], two, one + 1, zero)

def generate(n):
  two, one, zero = 0, 0, 0
  for p in itertools.permutations(xrange(n)):
    tree = build_tree(p)
    two, one, zero = count(tree, two, one, zero)
  print n, two, one, zero

for n in xrange(1, 11):
  generate(n)
