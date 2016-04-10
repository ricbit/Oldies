def fractiles(k, c):
    pos = 0
    ans = []
    for cc in xrange((k + c - 1) / c):
      f = 0
      for kk in xrange(c):
          f = f * k + (pos if pos < k else 0)
          pos += 1
      ans.append(f + 1)
    return ' '.join(map(str, ans))

def main():
    for case in xrange(input()):
        k,c,s = map(int, raw_input().split())
        if s * c < k:
            print "Case #%d: %s" % (case + 1, 'IMPOSSIBLE')
        else:
            print "Case #%d: %s" % (case + 1, fractiles(k, c))
       
main()
