# render with python ex231b.py 4 | dot -Kfdp -Tpng -oimg.png
# elements of F(z)=tan(tan(z))

import sys
import itertools

def set_partitions(n):
  def gen(pos, m, cur):
    if pos == n:
      yield cur
    else:
      for i in xrange(0, 1 + m):
        updated = cur + [i]
        for elem in gen(pos + 1, max(updated) + 1, updated):
          yield elem
  def convert(partition):
    for encoded in partition:
      ans = [[] for i in xrange(n)]
      for i, j in enumerate(encoded):
        ans[j].append(i + 1)
      yield [x for x in ans if x]
  return convert(gen(1, 1, [0]))

def find_min(partitions):
  index = 0
  m = min(partitions[0])
  for i, p in enumerate(partitions):
    new_m = min(p)
    if new_m < m:
      index = i
      m = new_m
  return index

def is_zigzag(p):
  cur = p[0]
  zig = True
  for i in p[1:]:
    if zig != (cur > i):
      return False
    cur = i
    zig = not zig
  return True
    
def odd_zigzag(permutation):
  for p in itertools.permutations(permutation):
    if len(p) % 2 == 1 and is_zigzag(p):
      yield p

def recurse(partitions):
  if len(partitions) == 1:
    ans = []
    for p in odd_zigzag(partitions[0]):
      ans.append((' '.join(map(str,p)),(),()))
    return ans
  root_index = find_min(partitions)
  root = partitions[root_index]
  leaves = [i for i in xrange(len(partitions)) if i != root_index]
  ans = []
  for p in odd_zigzag(partitions[0]):
    for i in xrange(1, len(partitions), 2):
      for left_idx in itertools.combinations(leaves, i):
        left = recurse([partitions[j] for j in left_idx])
        right = recurse([partitions[j] for j in leaves if j not in left_idx])
        for tl,tr in itertools.product(left, right):
          ans.append((' '.join(map(str,p)),tl,tr))
  return ans

def gen_trees(n):
  for p in set_partitions(n):
    if len(p) % 2 == 1:
      for t in recurse(p):
        yield t

def traverse(tree, i, parent):
  if not tree:
    return
  label = tree[0].replace(' ', '_')
  print 'n%d_%s [label="%s"]' % (i, label, tree[0])
  if parent:
    print 'n%d_%s -> n%d_%s' % (i, parent, i, label)
  traverse(tree[1], i, label)
  traverse(tree[2], i, label)

def dump_trees(n):
  count = 0
  for i, tree in enumerate(gen_trees(n)):
    traverse(tree, i, "")
    count += 1
  print "// size = ", count

print "digraph tree {"
dump_trees(int(sys.argv[1]))
print "}"
