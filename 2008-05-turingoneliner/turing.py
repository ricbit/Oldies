# Script to convert Brainfuck to a Python one-liner.
# Ricardo Bittencourt 2008

# Usage: python turing.py < prog.bf > prog.py
# To run the generated program: python prog.py < input.txt > output.txt

import re, sys

oneliner = """
print ''.join(chr(i) for i in (
  (lambda itertools, sys:
    (lambda change, get, chain, composite:
      (lambda comma, dot, plus, minus, left, right, infinite, predicate, getfirst:
        (lambda bf, loop:
          (lambda run:
            (%s)
            ([0],0,[ord(i) for i in sys.stdin.read()],[])
          )(
            (lambda f: chain([bf[i] for i in f]))
          )
        )(
          ({'+':plus, '-':minus, '.':dot, ',':comma, '<':left, '>':right}),
          (lambda f: lambda *x: getfirst(itertools.dropwhile(lambda x: predicate(*x), infinite(f,x))))
        )
      )(
        (lambda mem,p,stdin,stdout: (lambda now,next: (change(mem,p,now),p,next,stdout))(*get(stdin))),
        (lambda mem,p,stdin,stdout: (mem,p,stdin,stdout+[mem[p]])),
        (lambda mem,p,stdin,stdout: (change(mem,p,mem[p]+1),p,stdin,stdout)),
        (lambda mem,p,stdin,stdout: (change(mem,p,mem[p]-1),p,stdin,stdout)),
        (lambda mem,p,stdin,stdout: ([0]+mem if not p else mem, 0 if not p else p-1, stdin, stdout)),
        (lambda mem,p,stdin,stdout: (mem+[0] if p==len(mem)-1 else mem, p+1, stdin, stdout)),
        (lambda f,x: itertools.imap(lambda n: composite(f,n)(x), itertools.count(0))),
        (lambda mem,p,stdin,stdout: mem[p] != 0),
        (lambda it: [i for i in itertools.islice(it, 1)][0])
      )
    )(
      (lambda mem,pos,value: [value if i==pos else a for i,a in enumerate(mem)]),
      (lambda s: (s[0],s[1:]) if len(s) else (0,[])),
      (lambda f: lambda *x: reduce(lambda y,g: g(*y), f, x)),
      (lambda f,n: lambda x: reduce(lambda a,b:b(*a),[f]*n,x))
    )
  )(__import__("itertools"), __import__("sys"))
)[3])
"""

def chain(out):
 if len(out) == 1:
   return out[0]
 else:
   return "chain([%s])" % ",".join(out)

def run(cur, out):
  if cur:
   out.append('run("%s")' % cur)

def parse(start, code):
  i = start
  out = []
  cur = ""
  while i < len(code):
    if code[i] not in "+-<>[],.":
      i += 1
      continue
    if code[i] == "[":
      run(cur, out)
      cur = ""
      loop, i = parse(i+1, code)
      out.append("loop(%s)" % loop)
    elif code[i] == "]":
      run(cur, out)
      return chain(out), i+1
    else:
      cur += code[i]
      i += 1
  run(cur, out)
  return chain(out) , i

code = oneliner % parse(0, sys.stdin.read())[0]
print re.sub("[ \n]+"," ",code).strip()
