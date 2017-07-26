template = open("calc.html").read()

def dump(m, name):
    f = open(name + ".html", "w")
    f.write(template % m)
    f.close()

# zero
m = {'d%d'%i:str(i)+".html" for i in xrange(10)}
m['v1'] = 'n.png'
m['v0'] = '0.png'
m['dP'] = '0+.html'
m['dE'] = '0.html'
m['dC'] = '0.html'
dump(m, "0")

# one
for x in xrange(1,10):
    m = {'d%d'%i:str(x)+str(i)+".html" for i in xrange(10)}
    m['v1'] = 'n.png'
    m['v0'] = str(x)+'.png'
    m['dP'] = str(x)+'+.html'
    m['dE'] = str(x)+'.html'
    m['dC'] = '0.html'
    dump(m, str(x))

# two
for x in xrange(10,100):
    m = {'d%d'%i:str(x)+".html" for i in xrange(10)}
    m['v1'] = str(x/10)+'.png'
    m['v0'] = str(x%10)+'.png'
    m['dP'] = str(x)+'+.html'
    m['dE'] = str(x)+'.html'
    m['dC'] = '0.html'
    dump(m, str(x))

# one plus
for x in xrange(0,10):
    m = {'d%d'%i:str(x)+"+"+str(i)+".html" for i in xrange(10)}
    m['v1'] = 'n.png'
    m['v0'] = str(x)+'.png'
    m['dP'] = str(x)+'+.html'
    m['dE'] = str(x)+'.html'
    m['dC'] = '0.html'
    dump(m, str(x)+"+")

# two plus
for x in xrange(10,100):
    m = {'d%d'%i:str(x)+"+"+str(i)+".html" for i in xrange(10)}
    m['v1'] = str(x/10)+'.png'
    m['v0'] = str(x%10)+'.png'
    m['dP'] = str(x)+'+.html'
    m['dE'] = str(x)+'.html'
    m['dC'] = '0.html'
    dump(m, str(x)+"+")

# one plus zero
for x in xrange(0, 10):
    m = {'d%d'%i:str(x)+"+"+str(i)+".html" for i in xrange(10)}
    m['v1'] = 'n.png'
    m['v0'] = '0.png'
    m['dP'] = str(x)+'+.html'
    m['dE'] = str(x)+'.html'
    m['dC'] = '0.html'
    dump(m, str(x)+"+0")

# two plus zero
for x in xrange(10,100):
    m = {'d%d'%i:str(x)+"+"+str(i)+".html" for i in xrange(10)}
    m['v1'] = 'n.png'
    m['v0'] = '0.png'
    m['dP'] = str(x)+'+.html'
    m['dE'] = str(x)+'.html'
    m['dC'] = '0.html'
    dump(m, str(x)+"+0")

# one plus one
for x in xrange(0, 10):
    for y in xrange(1, 10):
        m = {'d%d'%i:str(x)+"+"+str(y)+str(i)+".html" for i in xrange(10)}
        m['v1'] = 'n.png'
        m['v0'] = str(y)+'.png'
        m['dP'] = str((x+y)%100)+'+.html'
        m['dE'] = str((x+y)%100)+'.html'
        m['dC'] = '0.html'
        dump(m, str(x)+"+"+str(y))

# two plus one
for x in xrange(10,100):
    for y in xrange(1, 10):
        m = {'d%d'%i:str(x)+"+"+str(y)+str(i)+".html" for i in xrange(10)}
        m['v1'] = 'n.png'
        m['v0'] = str(y)+'.png'
        m['dP'] = str((x+y)%100)+'+.html'
        m['dE'] = str((x+y)%100)+'.html'
        m['dC'] = '0.html'
        dump(m, str(x)+"+"+str(y))

# one plus two
for x in xrange(0, 10):
    for y in xrange(10, 100):
        m = {'d%d'%i:str(x)+"+"+str(y)+".html" for i in xrange(10)}
        m['v1'] = str(y/10)+'.png'
        m['v0'] = str(y%10)+'.png'
        m['dP'] = str((x+y)%100)+'+.html'
        m['dE'] = str((x+y)%100)+'.html'
        m['dC'] = '0.html'
        dump(m, str(x)+"+"+str(y))

# two plus two
for x in xrange(10, 100):
    for y in xrange(10, 100):
        m = {'d%d'%i:str(x)+"+"+str(y)+".html" for i in xrange(10)}
        m['v1'] = str(y/10)+'.png'
        m['v0'] = str(y%10)+'.png'
        m['dP'] = str((x+y)%100)+'+.html'
        m['dE'] = str((x+y)%100)+'.html'
        m['dC'] = '0.html'
        dump(m, str(x)+"+"+str(y))


