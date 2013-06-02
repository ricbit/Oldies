# Supernecklaces of type 3
# usage: python ex428.py 1 | dot  -Kcirco -Tpng -oi428a1.png

import itertools, sys

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

def count_cycles(x):
  ans = 0
  visited = [False] * len(x)
  for i in xrange(len(x)):
    if visited[i]:
      continue
    j = i
    while not visited[j]:
      visited[j] = True
      j = x[j]
    ans += 1
  return ans

def cycles(n):
  for p in itertools.permutations(range(n)):
    if count_cycles(p) == 1:
      ans = []
      cur = 0
      for i in xrange(len(p)):
        ans.append(cur)
        cur = p[cur]
      yield ans

def subcycle(original):
  def recurse(source):
    if not source:
      yield []
    else:
      for i in cycles(len(source[0])):
        cycle = [source[0][j] for j in i]
        for ans in recurse(source[1:]):
          yield [cycle] + ans
  return recurse(original)

n = int(sys.argv[1])
code = 0
print "digraph supernecklaces {"
for partition in set_partitions(n):
  for cycle in cycles(len(partition)):
    for outer in subcycle([partition[i] for i in cycle]):
      for i, inner in enumerate(outer):
        for j, node in enumerate(inner):
          print 'n%d_%d [label="%d"]' % (code, node, node)
          if len(inner) > 1:
            print 'n%d_%d -> n%d_%d [color=blue]' % (code, node, code, inner[(j+1)%len(inner)])

        if len(outer) > 1:
          print 'n%d_%d -> n%d_%d [color=red]' % (code, inner[0], code, outer[(i+1)%len(outer)][0])
      code += 1

print "}"
