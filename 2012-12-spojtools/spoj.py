#!/usr/bin/python

import argparse
import cookielib
import datetime
import itertools
import os
import re
import time
import urllib
import urllib2

langcodes = {
  "asm": "13",
  "cc": "41",
  "py": "4",
  "c": "11",
  "java": "10",
  "rb": "17",
  "hs": "21",
  "bf": "12",
  "txt": "62",
  "pl": "3",
  "go": "114"
}

langext = {
  'C++': 'cc',
  'C': 'c',
  'PYT': 'py',
  'BAS': 'sh',
  'GO': 'go',
  'HAS': 'hs',
  'JS': 'js',
  'ASM': 'asm',
  'BF': 'bf',
  'PER': 'pl',
  'JAV': 'java',
  'TEX': 'txt'
}

def expand(filename):
  source = []
  for line in open(filename, 'r'):
    include = re.search('#include "(.*?)"', line)
    if include is None:
      source.append(line)
    else:
      source.append(open(include.group(1), 'r').read())
  source = ''.join(source)
  return source

def submit(args):
  source = expand(args.code)
  name, ext = args.code.split('.')
  data = [
    ("login_user", args.user),
    ("password", args.password),
    ("file", source),
    ("lang", langcodes[ext]),
    ("problemcode", name)
  ]
  url = 'http://www.spoj.com/submit/complete/'
  html = urllib2.urlopen(url, urllib.urlencode(data)).read()
  message = re.search('<h3>(.*?)</h3>', html)
  if message is None:
    print "Error."
  else:
    print message.group(1)

def parse_status(page):  
  fieldnames = 'probid date problem result time mem lang'.split()
  ans = []
  for line in page.split('\n'):
    if line.count('|') != 8:
      continue
    fields = [x.strip() for x in line.split('|')[1:-1]]
    data = dict(zip(fieldnames, fields))
    if not data['probid'].isdigit():
      continue
    ans.append(data)
  return ans

def spoj_login(args):
  jar = cookielib.CookieJar()
  url = 'http://www.spoj.com'
  opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(jar))
  opener.open(url)
  data = [
      ("login_user", args.user),
      ("password", args.password),
      ("autologin", "1"),
      ("submit", "Log In")]
  r = opener.open('https://www.spoj.com/logout', urllib.urlencode(data))
  return jar

def download(args):
  jar = spoj_login(args)
  status_url = 'http://www.spoj.com/status/ricbit/signedlist/'
  status_page = urllib2.urlopen(status_url).read()
  status_list = parse_status(status_page)
  status_list = filter(lambda x:x['result'] == 'AC', status_list)
  status_list.sort(key=lambda x:x['date'], reverse=True)
  status_list.sort(key=lambda x:float(x['time']))
  status_list.sort(key=lambda x:x['lang'])
  status_list.sort(key=lambda x:x['problem'])

  opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(jar))
  key = lambda x:(x['problem'], x['lang'])
  for _, problem_group in itertools.groupby(status_list, key=key):
    for problem in problem_group:
      url = 'http://www.spoj.com/files/src/save/' + problem['probid']
      source = opener.open(url).read()
      filename = problem['problem'] + "." + langext[problem['lang']] 
      print "Downloading ", filename
      f = open(filename, 'w')
      f.write(source)
      f.close()
      date = datetime.datetime.strptime(problem['date'], '%Y-%m-%d %H:%M:%S')
      utc = time.mktime(date.timetuple())
      os.utime(filename, (utc, utc))
      break


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--user')
  parser.add_argument('--password')
  subparsers = parser.add_subparsers()

  submit_parser = subparsers.add_parser(
      'submit', help='Submit a problem')
  submit_parser.add_argument('code', help='Problem source, such as TEST.cc')
  submit_parser.set_defaults(func=submit)

  download_parser = subparsers.add_parser(
      'download', help='Download all solutions')
  download_parser.set_defaults(func=download)

  args = parser.parse_args()
  args.func(args)
  

if __name__ == '__main__':
  main()
