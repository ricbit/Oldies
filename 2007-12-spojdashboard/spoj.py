#!/usr/bin/python           

import binascii
import cgi
import re
import sys
import time
import urllib2

def html_header():
  print "Content-Type: text/html\n"

def html_hash(url):
  return "spoj%d.txt" % binascii.crc32(url)

def load_and_write_url(url):
  f=urllib2.urlopen(url)
  page=f.read()
  f=open(html_hash(url),"w")
  f.write("%lf\n" % time.time())
  f.write(page)
  f.close()
  return page

def cache_load(url):
  try:
    f=open(html_hash(url),"rt")
    t=float(f.readline())
    if time.time() - t < 60*60*24:
      return f.read()
    else:
      return load_and_write_url(url)
  except IOError:
    return load_and_write_url(url)

def get_languages(original):
  page = original.split("\n")
  found = set([])
  lang = {}
  for line in page:
    w = line.split("|")
    if len(w)==9 and w[4].strip()=="AC":
      found.add((w[3].strip(),w[7].strip()))
      lang[w[7].strip()]=0
  for x in list(found):
    lang[x[1]]+=1
  return lang.items()

def pie_languages(original):
  lang = dict(get_languages(original))
  pie = ('<img src="http://chart.apis.google.com/chart?chs=500x150&chd=t:%s'+
         '&cht=p3&chl=%s">')
  value = ','.join(str(i) for i in lang.values())
  keys = '|'.join(i.replace('+','p') for i in lang.keys())
  return pie % (value,keys)

def proburl(prob):
  return '<a href="http://www.spoj.pl/problems/%s/">%s</a>' % (prob,prob)

def load_points():
  allp = "".join(cache_load("http://www.spoj.pl/problems/classical/sort=0,start=%d"
                 % i) for i in range(0,1700,50))
  return dict([(a,int(b)) for (a,b) in
          re.findall('\/ranks\/([^\"]+)"[^>]+>([0-9]+)',allp)])

def tricky_probs(original):
  page = original.split("\n")
  acc=set([])
  probs={}
  tricky=[]
  for line in reversed(page):
    w=line.split("|")
    if len(w)==9:
      name=w[3].strip()
      if w[4].strip()!="AC":
        if name not in probs:
          probs[name]=1
        else:
          probs[name]+=1
      elif name not in acc:
        acc.add(name)
        if name in probs:
          tricky.append((probs[name],name))
  tricky.sort()
  tricky=[(proburl(a),b) for (b,a) in reversed(tricky)]
  return tricky[:5]
  
def difficult(original, points):
  page = original.split("\n")
  diff = []
  for line in page:
    w=line.split("|")
    if len(w)==9:
      name=w[3].strip()
      if w[4].strip()=="AC" and name in points:
        diff.append((points[name],name))
  diff=list(set(diff))
  diff.sort()
  return [(proburl(a),b) for (b,a) in diff[:5]]

def easiest(original, points):
  page = original.split("\n")
  solved = set([])
  for line in page:
    w=line.split("|")
    if len(w)==9:
      name=w[3].strip()
      if w[4].strip()=="AC":
        solved.add(name)
  easy = [(b,a) for (a,b) in points.iteritems() if a not in solved]
  easy.sort()
  return [(proburl(a),b) for (b,a) in reversed(easy)][:15]

def firstplace(user,top10):
  ans = []
  for name,top in top10.iteritems():
    if top[0][0]==user:
      ans.append(proburl(name))
  return ans

def almost(user,top10):
  ans = []
  for name,top in top10.iteritems():
    if top[0][1]=='0.00':
      continue
    for item in top[1:5]:
      if item[0]==user and item[1]!='0.00':
        ans.append(proburl(name))
  return ans

def print_table(table):
  print "<table>"
  for line in table:
    print "<tr>"
    for item in list(line):
      print "<td>%s</td>" % str(item)
    print "</tr>"
  print "</table>"

def load_top10(name):
  page=cache_load("http://www.spoj.pl/ranks/%s/" % name).replace("\n"," ")
  return re.findall('\/users\/([^\/]+)\/.+?statustext\">\s*(\S+)\s*<',page)

def load_all_top10(original):
  page = original.split("\n")
  solved = set([])
  for line in page:
    w=line.split("|")
    if len(w)==9:
      name=w[3].strip()
      if w[4].strip()=="AC":
        solved.add(name)
  top10={}
  for name in solved:
    top10[name]=load_top10(name)
  return top10

def print_line(items):
  print "<P>%s</P>" % " ".join(items)

def render_page(user):
  history = cache_load("http://www.spoj.pl/status/%s/signedlist/" % user)
  points = load_points()
  top10 = load_all_top10(history)
  print "<html><body>"
  print "<h1>Statistics for %s</h1>" % user
  print "<h2>Languages used</h2>"
  print pie_languages(history)
  print "<h2>Top 5 tricky problems</h2>"
  print "<p>(max number of tries before AC)</p>"
  print_table(tricky_probs(history))
  print "<h2>Most difficult problems solved</h2>"
  print_table(difficult(history,points))
  print "<h2>Easiest problems not solved</h2>"
  print_table(easiest(history,points))
  print "<h2>Problems with first place achieved</h2>"
  print_line(firstplace(user,top10))
  print "<h2>Problems with almost first place achieved</h2>"
  print_line(almost(user,top10))
  print "</body></html>"

def main():
  render_page(raw_input().strip())

def main_cgi():
  form = cgi.FieldStorage()
  user = cgi.escape(form.getfirst('spojid','ricbit'))
  render_page(user)

if __name__=="__main__":
  html_header()
  sys.stderr = sys.stdout
  main_cgi()
  #main()
