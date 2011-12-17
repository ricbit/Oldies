# Homework 6-1

n = input()
observations = [raw_input().strip() for i in xrange(n)]
states = set()
for obs in observations:
  for state in obs:
    states.add(state)
states = list(states)
states.sort()
s = len(states)
first = dict(zip(states, [0]*s))
transition = dict(zip(states, [dict(zip(states, [0]*s)) for i in xrange(s)]))
for obs in observations:
  first[obs[0]] += 1
  for sprev, snext in zip(obs, obs[1:]):
    transition[sprev][snext] += 1
for state in states:
  print "P(%s0) = %f" % (state, first[state]/float(sum(first.values())))
for sprev in states:
  for snext in states:
    print "P(%s->%s) = %f" % (sprev, snext,
        transition[sprev][snext] / float(sum(transition[sprev].values())))
