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
        grandfatherM = ["f"] * N
        grandmotherM = ["m"] * N
        grandfatherF = ["F"] * N
        grandmotherF = ["M"] * N
	mother = mix(grandfatherM, grandmotherM)
	brother1M = mix(grandfatherM, grandmotherM)
	brother2M = mix(grandfatherM, grandmotherM)
	father = mix(grandfatherF, grandmotherF)
	brother1F = mix(grandfatherF, grandmotherF)
	brother2F = mix(grandfatherF, grandmotherF)
	wife1M = ["1"] * N
	wife2M = ["2"] * N
	wife1F = ["3"] * N
	wife2F = ["4"] * N
        myself = mix(father, mother)
	cousin1 = mix(brother1M, wife1M)
	cousin2 = mix(brother1M, wife1M)
	cousin3 = mix(brother2M, wife2M)
	cousin4 = mix(brother2M, wife2M)
	cousin5 = mix(brother1F, wife1F)
	cousin6 = mix(brother1F, wife1F)
	cousin7 = mix(brother2F, wife2F)
	cousin8 = mix(brother2F, wife2F)
	ans += correlation(myself, [cousin1, cousin2, cousin3, cousin4, cousin5, cousin6, cousin7, cousin8])
print float(ans) / M
