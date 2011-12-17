# optional NLP 1

import string

# From wikipedia
bigram = {
     'en': '0.55', 've': '0.04', 'ed': '0.53', 'is': '0.46', 'ea': '0.47',
     'al': '0.09', 'an': '0.82', 'as': '0.33', 'ar': '0.04', 'at': '0.59',
     'in': '0.94', 'et': '0.19', 'ur': '0.02', 'es': '0.56', 'er': '0.94',
     'ld': '0.02', 'le': '0.08', 'to': '0.52', 'nd': '0.63', 'ng': '0.18',
     're': '0.68', 'ra': '0.04', 'th': '1.52', 'ti': '0.34', 'te': '0.27',
     'nt': '0.56', 'de': '0.09', 'it': '0.50', 'hi': '0.46', 'ha': '0.56',
     'sa': '0.06', 'he': '1.28', 'on': '0.57', 'of': '0.16', 'st': '0.55',
     'si': '0.05', 'ou': '0.50', 'or': '0.43', 'se': '0.08'
    }

cypher = "Esp qtcde nzyqpcpynp zy esp ezatn zq Lcetqtntlw Tyepwwtrpynp hld spwo le Olcexzfes Nzwwprp ty estd jplc."

def rotate(text, n):
  new = []
  for c in text:
    new += (chr((ord(c) - ord('a') + n) % 26 + ord('a'))
            if c in string.letters else c)
  total = 0
  for a,b in zip(new, new[1:]):
    total += float(bigram.get(a+b, 0))
  return total, "".join(new)

solutions = [rotate(cypher.lower(), i) for i in range(26)]
print max(solutions)
