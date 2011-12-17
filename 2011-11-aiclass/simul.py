# homework 8-7

import math
t,x,y,theta = 0,0,0,0
dt,v,omega=4,10,math.pi/8
for i in range(4):
  x = x + v*dt*math.cos(theta)
  y = y + v*dt*math.sin(theta)
  theta = theta + omega*dt
  print x,y,theta
