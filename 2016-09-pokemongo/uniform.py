import random

N = 30000
acc = 0
elems = []
for i in xrange(N):
    s = set()
    n = 0
    while len(s) < 145:
        k = random.randint(1, 145)
        s.add(k)
        n += 1
    elems.append(n)
    acc += n
avg = float(acc) / N
stddev = (sum((x-avg)**2 for x in elems) / (N-1)) ** 0.5
print avg,stddev
