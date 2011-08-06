import itertools

def factor(n):
 solutions = []
 for f in itertools.product(range(1,1+n),repeat=n):
   if reduce(lambda x,y: x*y, f) == n:
     solutions.append(filter(lambda x:x>1, list(f)))
 solutions.sort(key=len, reverse=True)
 return solutions[0]
