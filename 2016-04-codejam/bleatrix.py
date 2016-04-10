def extract(n):
    return set(c for c in str(n))

def count(n):
    if n == 0:
        return "INSOMNIA"
    i = 1
    digits = extract(n)
    while len(digits) < 10:
        i += 1
        digits = digits.union(extract(i * n))
    return str(i * n)

def main():
    tot = input()
    for case in xrange(tot):
        print "Case #%d: %s" % (case + 1, count(input()))

main()
