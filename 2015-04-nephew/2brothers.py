import random
 
def mix(a, b):
  ans = []
  for i, j in zip(a, b):
    if random.randrange(0, 2) == 0:
      ans.append(i)
    else:
      ans.append(j)
  return ans
 
def correlation(a, nephews):
  ans = 0
  for i in xrange(len(a)):
    if a[i] in [x[i] for x in nephews]:
      ans += 1
  return float(ans) / len(a)
 
ans = 0
M = 400
N = 1000
for i in xrange(M):
	mother = ["M"] * N
	father = ["F"] * N
	myself = mix(mother, father)
	brother1 = mix(mother, father)
	brother2 = mix(mother, father)
	ans += correlation(myself, [brother1, brother2])
print float(ans) / M
