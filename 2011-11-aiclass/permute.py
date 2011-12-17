# optional NLP 2
# requires w1.txt from http://www.ngrams.info/ (1-grams non case sensitive).

import string
import math
import heapq

def load_words():
  words = {}
  for line in open('w1.txt'):
    s = line.strip().split('\t')
    if len(s) == 2:
      try:
        value, word = float(s[0]), s[1]
        words[word] = math.log(10 + value) ** len(word)
      except ValueError:
        pass
  return words

def letters(word):
  return "".join((i if i in string.letters or i == '|' else ' ') for i in word)

def load_slices():
  original = """
  |de|  | f|Cl|nf|ed|au| i|ti|  |ma|ha|or|nn|ou| S|on|nd|on|
  |ry|  |is|th|is| b|eo|as|  |  |f |wh| o|ic| t|, |  |he|h |
  |ab|  |la|pr|od|ge|ob| m|an|  |s |is|el|ti|ng|il|d |ua|c |
  |he|  |ea|of|ho| m| t|et|ha|  | t|od|ds|e |ki| c|t |ng|br|
  |wo|m,|to|yo|hi|ve|u | t|ob|  |pr|d |s |us| s|ul|le|ol|e |
  | t|ca| t|wi| M|d |th|"A|ma|l |he| p|at|ap|it|he|ti|le|er|
  |ry|d |un|Th|" |io|eo|n,|is|  |bl|f |pu|Co|ic| o|he|at|mm|
  |hi|  |  |in|  |  | t|  |  |  |  |ye|  |ar|  |s |  |  |. |
  """
  sanitized = [letters(i.strip().lower()).split('|')[1:-1]
               for i in original.split('\n') if i.strip()]
  return zip(*sanitized)

def score(slices, words):
  lines = ["".join(i) for i in zip(*slices)]
  total = 0.0
  for line in lines:
    w = line.strip().split()
    for word in w:
      total += words.get(word, 0.0)
  return total

def search(words, original):
  queue = [(0.0, [])]
  while True:
    current_score, current = heapq.heappop(queue)
    used = set(current)
    for i in range(len(original)):
      if i not in used:
        candidate = [original[j] for j in current]
        candidate.append(original[i])
        new_score = -score(candidate, words) / (len(candidate)**0.5)
        new_current = current[:]
        new_current.append(i)
        heapq.heappush(queue, (new_score, new_current))
        if len(new_current) == len(original):
          return new_current

words = load_words()
original = load_slices()
answer = zip(*[original[i] for i in search(words, original)])
for line in answer:
  print "".join(line)

