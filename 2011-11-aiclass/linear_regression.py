m = input()
x = []
y = []
for _ in xrange(m):
  a,b = map(float, raw_input().split())
  x.append(a)
  y.append(b)
xiyi = sum(a*b for a,b in zip(x,y))
xi = sum(x)
yi = sum(y)
xi2 = sum(i*i for i in x)
w1 = float(m*xiyi - xi*yi) / float(m*xi2 - xi*xi)
w0 = float(yi)/float(m) - float(w1 * xi)/float(m)
print w1,w0
