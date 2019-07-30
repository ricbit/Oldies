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
	wife2 = ["2"] * N
	wife3 = ["3"] * N
	wife4 = ["4"] * N
	myself = mix(mother, father)
	brother1 = mix(mother, father)
	brother2 = mix(mother, father)
	brother3 = mix(mother, father)
	brother4 = mix(mother, father)
	cousin1 = mix(brother1, wife1)
	cousin2 = mix(brother1, wife1)
	cousin3 = mix(brother2, wife2)
	cousin4 = mix(brother2, wife2)
	cousin5 = mix(brother3, wife3)
	cousin6 = mix(brother3, wife3)
	cousin7 = mix(brother4, wife4)
	cousin8 = mix(brother4, wife4)
	ans += correlation(myself, [cousin1, cousin2, cousin3, cousin4, cousin5, cousin6, cousin7, cousin8])
print float(ans) / M
