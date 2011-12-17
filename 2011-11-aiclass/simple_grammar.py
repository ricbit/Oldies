# Quiz 22-2

n = ["interest", "fed", "rates", "raises"]
v = ["interest", "rates", "raises"]
d = ["the", "a"]

def np(s):
  if len(s) == 1 and s[0] in n:
    return 1
  if len(s) == 2 and s[0] in d and s[1] in n:
    return 1
  if len(s) == 2 and s[0] in n and s[1] in n:
    return 1
  if len(s) == 3 and all(x in n for x in s):
    return 1
  return 0

def vp(s):
  if not s:
    return 0
  if s[0] not in v:
    return 0
  if len(s) == 1:
    return 1
  s = s[1:]
  return np(s) + sum(np(s[:i]) * np(s[i:]) for i in range(len(s)))

def sentence(s):
  return sum(np(s[:i]) * vp(s[i:]) for i in range(len(s)))

for _ in range(input()):
  s = raw_input().split()
  print sentence(s), s
