import json
import random

pokemons = json.loads(open("pokemon.json").read())
norm = sum(p[1] for p in pokemons)
probs = [float(p[1])/norm for p in pokemons]
probs.sort()
accprobs = [sum(probs[i] for i in xrange(0,j)) for j in xrange(1+len(probs))]

def choose():
    x = random.random()
    i = 0
    while x > accprobs[i]:
        i += 1
    return i - 1

N = 100
acc = 0
elems = []
for i in xrange(N):
    s = set()
    n = 0
    while len(s) < 145:
        k = choose()
        s.add(k)
        n += 1
    elems.append(n)
    acc += n
avg = float(acc) / N
stddev = (sum((x-avg)**2 for x in elems) / (N-1)) ** 0.5
print avg,stddev
