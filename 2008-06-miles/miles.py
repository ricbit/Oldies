# Script to plot the error of the approximation when
# converting miles to km using Fibonacci shifts.

# Ricardo Bittencourt 2008

import pylab

def fib(n, memo={}):
  if n < 2:
    return 1   
  if n not in memo:
    memo[n] = fib(n-1) + fib(n-2)
  return memo[n]

fibonacci = [fib(i) for i in range(20)]

def convert(n, temp=None):
  current = temp if temp is not None else []
  if n == 0:
    return current
  a = max(i for i in fibonacci if i <= n)
  return convert(n-a, current+[a])

def shift(n):
  return sum(fibonacci[fibonacci.index(i)+1] for i in n)

a = [shift(convert(i)) for i in range(1,100)]
b = [i*1.609344 for i in range(1,100)]
pylab.plot([(ia-ib)/ib*100 for ia,ib in zip(a,b)])
pylab.show()
