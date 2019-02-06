# -*- coding: utf-8 -*-
# Usage: python gplus.py Takeout/Stream do Google+/Fotos/Fotos com você/

import json
import requests
import os
import sys

for dirpath, dirnames, filenames in os.walk(sys.argv[1]):
  for filename in filenames:
    fullpath = os.path.join(dirpath, filename)
    try:
      print "Reading ", filename
      metadata = json.loads(open(fullpath).read())
      data = requests.get(metadata['url'])
      imagename = metadata['title']
      f = open(imagename, 'wb')
      f.write(data.content)
      f.close()
      os.utime(imagename, (int(metadata['creationTime']['timestamp']),) * 2)
    except:
      print "Failed."

