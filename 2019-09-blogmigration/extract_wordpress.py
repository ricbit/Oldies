import xml.etree.ElementTree as ET
from datetime import datetime
import os
import re
import requests
import sys

def replace_mathurl(text):
  for img_tag, url in re.findall(r'(<img.*?src="(http://mathurl.com/.*?)\.png".*?/>)', text):
    req = requests.get(url)
    match = re.search(r'(?ms)<meta name="twitter:description" content="(.*?)">', req.text)
    text = text.replace(img_tag, "$$%s$$" % match.group(1))
    print(url, match.group(1), file=sys.stderr)
  return text

namespace = {
    "wp": "http://wordpress.org/export/1.2/",
    "content": "http://purl.org/rss/1.0/modules/content/"
}

tree = ET.parse(sys.argv[1])
images = set()
for post in tree.findall("./channel/item"):
  guid = post.find("guid")
  if re.search(r"\?p=\d+$", guid.text) is None:
    continue
  content = post.find("content:encoded", namespace)
  if content is None:
    continue
  iso_date = post.find("wp:post_date", namespace).text 
  full_date = datetime.fromisoformat(iso_date)
  date = full_date.strftime("%Y-%m-%d")
  print("%s\n%s\n\n" % (date, post.find("title").text))
  text = content.text
  for url in re.findall(r'"(http://scienceblogs.*?\.(?:png|jpg|svg))"', text):
    images.add(url)
    new_url = re.sub(r"^.*/(.*\.(?:png|jpg|svg))$",
        r"https://www.ilafox.com.br/ricbit/images/\1", url)
    text = text.replace(url, new_url)
  f = open("posts/" + date, "w")
  f.write(replace_mathurl(text))
  f.close()
for image in images:
  name = re.search(r"[^/]+\.(?:png|jpg|svg)$", image).group(0)
  print(name, file=sys.stderr)
  filename = "images/" + name
  if not os.path.isfile(filename):
      req = requests.get(image)
      f = open(filename, "wb")
      f.write(req.content)
      f.close()
