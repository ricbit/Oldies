# Check if a given age is palindrome in base b while the year is palindrome in base b**2

def to_base(n, base):
  ans = []
  while n > 0:
    ans.append(n % base)
    n //= base
  return ans

def is_palin(n):
  return n == n[::-1]

for age in range(1, 120):
  for base in range(2, age):
    ageb = to_base(age, base)
    yearb = to_base(age + 1976, base ** 2)
    if is_palin(ageb) and is_palin(yearb) and len(yearb) > 1:
      print(age, base, ageb, yearb)
    
