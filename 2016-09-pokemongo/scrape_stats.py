import json
import re

html = open('pokemonstats.html', 'r').read().replace('\n',' ')
data = re.findall(r'<tr>\s*<td>\s*(.*?)\s*</td>\s*<td>.*?([0-9.]+)', html)
data = [(name, float(p)) for name, p in data if p != '0.00']
print json.dumps(data, indent=4)
