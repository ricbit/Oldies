from Tkinter import*
Tk();k=256;p=PhotoImage(w=k)
m=lambda z,i,n:(abs(z)>2or n>1)*(i,n)or m(z*z+i/k/1e2-2+(128-i%k)/1e2j,i,n+.03)
[p.put("#%04x00"%(n**.7*k),(i/k,i%k))for(i,n)in[m(0,i,0)for i in range(k*k)]if n<1]
Label(i=p,bg="#fff").grid();mainloop()
