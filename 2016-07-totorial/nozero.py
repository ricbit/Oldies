import random

def simulate(n):
    t = 100000
    ans = 0
    for _ in xrange(t):
        s = ''.join(random.choice("01") for _ in xrange(n))
        if "00" not in s:
            ans += 1
    return float(ans) / t, 1.171 * (0.809) ** n

print simulate(5)
print simulate(10)
print simulate(15)
