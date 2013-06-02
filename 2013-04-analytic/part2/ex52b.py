import itertools, sys

def surjection(seq):
  hist = {}
  for i in seq:
    hist[i] = 1 + hist.get(i, 0)
  m = max(hist.iterkeys())
  for i in xrange(1, 1 + m):
    if hist.get(i, 0) < 3:
      return False
  return True

def triple_surjections(n):
  for seq in itertools.product(xrange(1, 1 + n / 3), repeat=n):
    if surjection(seq):
      yield seq

def tabular(seq):
  size = 7
  print "\\begin{tabular}{ %s }" % " ".join(["r"]*size)
  for i in xrange((len(seq)+size-1)/size):
    print "%s \\\\" % "&".join("".join(map(str,i)) 
      for i in seq[i*size:i*size+size])
  print "\\end{tabular}"

tabular(list(triple_surjections(int(sys.argv[1]))))
