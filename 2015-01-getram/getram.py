import base64
import gzip
import xml.etree.ElementTree as ET
import zlib
import sys

def getram(filename):
  f = gzip.open(filename).read()
  root = ET.fromstring(f)
  for f in root.iter('MemoryMapper'):
    b64 = bytes(f.find('ram').find('ram').text, 'ascii')
    return zlib.decompress(base64.decodebytes(b64))

def main():
  if len(sys.argv) < 2:
    print("Usage: python3 getram.py savestate.oms ram.bin")
    return
  ram = getram(sys.argv[1])
  f = open(sys.argv[2], "wb")
  f.write(ram)
  f.close()

if __name__ == '__main__':
  main()


