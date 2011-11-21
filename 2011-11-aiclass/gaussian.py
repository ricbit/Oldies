m = input()
x = [int(raw_input()) for i in xrange(m)]
mu = float(sum(x)) / float(m)
sigma2 = float(sum((i - mu)**2 for i in x)) / float(m)
print mu,sigma2
