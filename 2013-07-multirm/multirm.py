import os
import hashlib

def getmd5(name):
  return hashlib.md5(open(name, "rb").read()).hexdigest()

seen = {}
rmlist = []

for basepath, dirs, files in os.walk(os.getcwd()):
  for filename in files:
    name = os.path.join(basepath, filename)
    size = os.path.getsize(name)
    if size in seen:
      allmd5 = set()
      for namelist in seen[size]:
        if namelist[1] is None:
          namelist[1] = getmd5(namelist[0])
        allmd5.add(namelist[1])
      md5 = getmd5(name)
      if md5 in allmd5:
        rmlist.append(name)
        continue
      seen[size].append([name, md5])
    else:
      seen[size] = [[name, None]]

print "\n".join("del %s" % name for name in rmlist) 
