# Orbits in parallel universes.
# Ricardo Bittencourt 2010

import math
import Tkinter

def solve(f, u0, ul0, t, dt, iter):
  u = [u0]
  ul = [ul0]
  for i in xrange(iter):
    yl = ul[-1]+dt*(f(t)-u[-1])
    y = u[-1]+dt*yl
    t += dt
    u.append(y)
    ul.append(yl)
  return u

def normalize(x):
 xmax = max(x)
 xmin = min(x)
 return [int((i-xmin)/(xmax-xmin)*120) for i in x]

Tkinter.Tk()
image = Tkinter.PhotoImage(w=128,h=128)
iter = 10000
t = 1
dt = 0.01
u = solve(lambda x:1./math.sin(x), 1, 0.1, t, dt, iter)
#u = solve(lambda x:1, 1, 0.1, t, dt, iter)
#u = solve(lambda x:1./x, 1, 0.1, t, dt, iter)
#u = solve(lambda x:1./x/x, 1, 0.1, t, dt, iter)
#u = solve(lambda x:x, 1, 0.1, t, dt, iter)
theta = [t+i*dt for i in xrange(iter)]
x = []
y = []
for a,b in zip(u,theta):
  x.append(a*math.cos(b))
  y.append(a*math.sin(b))
xn = normalize(x)
yn = normalize(y)
for a,b in zip(xn,yn):
  image.put("#ff0000",(a+4,b+4))
image.write("orbit.gif",format='GIF')
Tkinter.Label(i=image,bg="black").grid()
Tkinter.mainloop()

