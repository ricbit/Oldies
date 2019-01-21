import re
import sys

current = None
output = ["#include <iostream>", "#include <fstream>"]
for line in open(sys.argv[1]):
  if current is None:
    m = re.search(r"(?:struct|class)\s*(\w+)\s*:\s*public\s*serializer", line)
    if m is not None:
      current = {'name' : m.group(1), 'fields': []}
  else:
    m = re.search(r'save<\S+>\s*(\w+);', line)
    if m is not None:
      current['fields'].append(m.group(1))
    if re.match(r'^};', line):
      output.append('#include "%s.h"' % current['name'])
      output.append("void %s::serialize(std::string f) {" % current['name'])
      output.append("  std::ofstream of(f);")
      for field in current['fields']:
        output.append("  of << %s << ' ';" % field)
      output.append("  of.close();");
      output.append("}");
      output.append("void %s::deserialize(std::string f) {" % current['name'])
      output.append("  std::ifstream inf(f);")
      for field in current['fields']:
        output.append("  inf >> %s ;" % field)
      output.append("  inf.close();");
      output.append("}");
      current = None

f = open(sys.argv[2], "wt")
f.write("\n".join(output))
f.close()
  

