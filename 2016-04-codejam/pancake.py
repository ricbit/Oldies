def count(s):
    ans = 0
    for next, prev in zip(s[1:], s):
        if next != prev:
            ans += 1
    if s[-1] == '-':
        ans += 1
    return ans

for case in xrange(input()):
    s = raw_input().strip()
    print "Case #%d: %d" % (case + 1, count(s))
