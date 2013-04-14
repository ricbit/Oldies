forward = range(4)
backward = forward[::-1]
run = [forward, backward]
pos = [[i]*4 for i in xrange(4)]
pos.extend(run)

attempt = []
for r in run:
  for p in pos:
    attempt.extend([zip(r,p),zip(p,r)])

def check(board):
  dot = 0
  for a in attempt:
    hist = {'X': 0, 'O': 0, '.': 0, 'T': 0}
    for x,y in a:
      hist[board[x][y]] = 1 + hist[board[x][y]]
    if hist['X'] + hist['T'] == 4:
      return "X won"
    if hist['O'] + hist['T'] == 4:
      return "O won"
    dot += hist['.']
  if not dot:
    return "Draw"
  else:
    return "Game has not completed"

for testcase in xrange(input()):
  board=[raw_input().strip() for _ in xrange(4)]
  print "Case #%d: %s" % (1+testcase, check(board))
  raw_input()
