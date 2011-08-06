# Find all cyclic numbers with length smaller than 100.
# Ricardo Bittencourt 2010

def prime(p):
  return all(p%n!=0 for n in range(2,p))

def order(n, p):
  for i in range(1, p):
    if (n**i)%p == 1:
      return i
  return p-1
  
def cyclic(p):
  rem = 1
  out = ""
  while True:
    out += str(rem*10 / p)
    rem = 10*rem % p
    if rem == 1:
      break
  return out
  
for i in range(7, 100):
  if prime(i) and order(10,i)==i-1:
    print i, cyclic(i)