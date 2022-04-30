# Download models from Loot Studios
# Ricardo Bittencourt 2022
#
# Usage:
#
# 1. Log into Loot Studios on Chrome
# 2. Save the cookies to a file, using the Developer Tools
# 3. Run python getloot.py
#
# The script will download all models from the months you own,
# and will skip over models already downloaded.

from bs4 import BeautifulSoup as BS
import multiprocessing
import os
import re
import requests
import sys
import urllib

cookie_file = open("cookies", "rt").read().split()
cookies = dict([tuple(line.strip().split("=", 1)) for line in cookie_file])
cpus = 7
session = requests.Session()
retries = requests.adapters.Retry(total=5, backoff_factor=3)
session.mount("https://", requests.adapters.HTTPAdapter(max_retries=retries))

def urljoin(root, relative_page):
  if relative_page:
    return urllib.parse.urljoin(root, relative_page.get("href"))
  return None

def sanitize(name):
  return name.replace("/", " ").replace("\\", " ").strip()

def parse_root(root_link):
  root_html = session.get(root_link, cookies=cookies).text
  soup = BS(root_html, 'html.parser')
  bases = []
  for pack in soup.find_all('div', class_="col-md-12"):
    cells = pack.find_all("div", class_="panel__cell")
    tag = cells[1].find('a')
    link = urljoin(root_link, tag)
    name = sanitize(tag.text)
    bases.append((name, link))
  next_page = soup.find('a', class_="pag__link--next")
  next_link = urljoin(root_link, next_page)
  return bases, next_link

def parse_all_roots(root_link):
  while root_link:
    base, root_link = parse_root(root_link)
    yield from base

def parse_base(base_link):
  base_html = session.get(base_link, cookies=cookies).text
  soup = BS(base_html, 'html.parser')
  for pack in soup.find_all("div", class_="syllabus__item"):
    link = urljoin(base_link, pack.find("a"))
    name = pack.find("p", class_="syllabus__title")
    if name is not None:
      yield sanitize(name.text), link

def parse_all_bases(base_links):
  for title, base in base_links:
    for name, link in parse_base(base):
      yield title, name, link

def parse_model(link):
  model_html = session.get(link, cookies=cookies).text
  soup = BS(model_html, 'html.parser')
  for pack in soup.find_all("a", class_="downloads__download"):
    model_name = sanitize(pack.find("div", class_="media-body").text)
    model_link = pack.get("href")
    if not model_name.startswith("All_") and model_name.endswith(".zip"):
      yield model_name, model_link

def skip_model(name, size):
  if not os.path.exists(name):
    return False
  if os.path.getsize(name) != size:
    return False
  return True

def download_model(params):
  title, base, model_name, model_link = params
  with session.get(model_link, stream=True) as request:
    zip_name = re.search(r"=(.*)$", request.headers['Content-Disposition'])
    if model_name != zip_name.group(1):
      print("Bad name for ", model_name)
      return
    path = os.path.join(title, base)
    os.makedirs(path, exist_ok = True)
    file_name = os.path.join(path, model_name)
    content_size = int(request.headers['content-length'])
    if skip_model(file_name, content_size):
      print("Skipping existing ", model_name)
      return
    print("Downloading ", model_name)
    data = request.content
    with open(file_name, "wb") as f:
      f.write(data)

def all_models():
  base_links = parse_all_roots("https://www.loot-studios.com/library")
  for title, base, link in parse_all_bases(base_links):
    for model_name, model_link in parse_model(link):
      yield title, base, model_name, model_link

with multiprocessing.Pool(cpus) as pool:
  for p in pool.imap_unordered(download_model, all_models(), 1):
    pass
