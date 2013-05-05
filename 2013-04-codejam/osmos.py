for testcase in xrange(1, 1 + input()):
  init, n = map(int, raw_input().split())
  motes = map(int, raw_input().split())
  motes.sort()
  cur = init + sum(m for m in motes if m < init)
  motes = [m for m in motes if m >= init]
  remain = len(motes)
  movs = 0
  ans = remain
  if init > 1:
    for mote in motes:
      add = 0
      while mote >= cur:
        add += 1
        cur += cur - 1
      if add >= remain:
        movs += remain
        break
      movs += add
      cur += mote
      remain -= 1
    ans = min(ans, movs)
  print "Case #%d: %d" % (testcase, ans)
    
