k = 1.0

def read_msg():
  n = input()
  return [raw_input() for i in xrange(n)]

def eval_dict(msg):
  d = {}
  words = 0
  for m in msg:
    for w in m.split():
      d[w] = d.setdefault(w, 0) + 1
      words += 1
  return words, d

spam_msg = read_msg()
ham_msg = read_msg()
test_msg = read_msg()

spam_words, spam_dict = eval_dict(spam_msg)
ham_words, ham_dict = eval_dict(ham_msg)
all_words = len(set(spam_dict.keys()).union(set(ham_dict.keys())))

def mul(x):
  return reduce(lambda a,b: a*b, x, 1)

def prob(word, words, adict):
  return float(adict.get(word, 0) + k) / float(words + all_words * k)

pspam = float(len(spam_msg) + k) / float(len(spam_msg) + len(ham_msg) + 2*k)
pham= 1.0 - pspam
for msg in test_msg:
  words = msg.split()
  pmsg_spam = mul([prob(word, spam_words, spam_dict) for word in words])
  pmsg_ham = mul([prob(word, ham_words, ham_dict) for word in words])
  print msg, pmsg_spam*pspam/(pmsg_spam*pspam+pmsg_ham*pham)

