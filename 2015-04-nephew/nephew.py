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
	wife1 = ["1"] * N
	wife2a = ["A"] * N
	wife2b = ["B"] * N
	myself = mix(mother, father)
	brother1 = mix(mother, father)
	brother2 = mix(mother, father)
	nephew1 = mix(brother2, wife2a)
	nephew2 = mix(brother1, wife1)
	nephew3 = mix(brother1, wife1)
	nephew4 = mix(brother2, wife2b)
	ans += correlation(myself, [nephew2, nephew3, nephew1, nephew4])
print float(ans) / M
