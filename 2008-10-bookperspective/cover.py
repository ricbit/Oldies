# Book Cover Desentortator
# Ricardo Bittencourt 2008

import math
import sys
from PIL import Image
from PIL import ImageFilter
from PIL import ImageMath

def resize(image):
  return image.resize((256, 256), Image.ANTIALIAS)

def hough(image):
  size = 256
  transform = [0.0] * (size*256*4)
  for i, data in enumerate(image.getdata()):
    if data < 32:
      continue
    y, x = divmod(i, 256)
    last = x
    for j in xrange(size):
      theta = math.pi / size * j
      r = int(x*math.cos(theta) + y*math.sin(theta))
      for k in xrange(min(r,last), 1+max(r,last)):
        transform[(512+k)*size + j] += data
      last = r
  m = max(transform)
  output = Image.new('F', (size, 256*4))
  output.putdata([i * 256 / m for i in transform])
  return output

def region_growing(image):
  pix = image.load()
  next = [(0,0)]
  visited = set(next)
  edge = []
  while next:
    x,y = next.pop()
    def check(i, j):
      if i<0 or i>255 or j<0 or j>255 or (i,j) in visited:
        return
      if sum((a-b)**2 for a,b in zip(pix[x,y],pix[i,j])) < 8**2:
        next.append((i,j))
        visited.add((i,j))
      else:
        edge.append((i,j))
    check(x-1, y)
    check(x+1, y)
    check(x, y-1)
    check(x, y+1)
  output = Image.new('L', (256,256))
  pix = output.load()
  for pixel in edge:
    pix[pixel]=255
  return output

def find_edges(transform):
  scratch = transform.copy()
  pix = scratch.load()
  edges = []
  for i in xrange(4):
    data = scratch.getdata()
    vertex = max(enumerate(data), key=lambda x:x[1])
    y, x = divmod(vertex[0], 256)
    x1 = max(0, x-10)
    x2 = min(255, x+10)
    for i in xrange(x1, 1+x2):
      for j in xrange(y-10, 1+ y+10):
        pix[i,j] = 0
    theta = x / 256.0 * math.pi
    a = -math.cos(theta) / math.sin(theta)
    b = (y - 512) / math.sin(theta)
    edges.append((a,b))
  return edges

def draw_edges(original, edges):
  output = original.copy()
  pix = output.load()
  for edge in edges:
    a, b = edge
    for i in xrange(256*10):
      j = a*i/10 + b
      if j >=0 and j < 256:
        pix[i/10,j] = (255, 0, 0)
  return output

def find_vertices(edges):
  points = []
  for i in xrange(len(edges)):
    for j in xrange(i+1, len(edges)):
      if edges[j][0] == edges[i][0]:
        continue
      x = (edges[i][1] - edges[j][1]) / (edges[j][0] - edges[i][0])
      y = edges[i][0]*x + edges[i][1]
      points.append((x,y))
  points.sort(key=lambda x:(x[0]-128)**2 + (x[1]-128)**2)
  vertices = points[:4]
  vertices.sort(key=lambda x:math.atan2(x[0]-128, x[1]-128))
  return vertices

def affine_transform(image, vertices):
  size = image.size
  resized = [[a/256*size[0], b/256*size[1]] for a,b in vertices]
  points = reduce(lambda x,y:x+y, resized, [])
  return image.transform((400,600), Image.QUAD, points, Image.BICUBIC)

def inverse_perspective(image, vertices):
  size = image.size
  resized = [[a/256*size[0], b/256*size[1]] for a,b in vertices]
  xa = resized[2][0] - resized[1][0]
  xb = resized[3][0] - resized[0][0]
  y = resized[1][1] - resized[0][1]
  aspect_ratio = y / xb
  width = 400
  height = int(width*aspect_ratio)
  output = Image.new('RGB', (width, height))
  z = xa / xb
  outpix = output.load()
  imgpix = image.load()
  for j in xrange(height):
    zm = (z-1) * j / height + 1
    ym = y * (xa - xa/zm) / (xa-xb)
    xm = xa / zm
    startx = (resized[2][0] + resized[1][0]) /2 - xm/2
    for i in xrange(width):
      x = startx + i * xm / width
      outpix[i,height-1-j] = imgpix[x,resized[1][1] - ym]
  return output      

def pipeline(image):
  resized = resize(image)
  border = region_growing(resized)
  points = hough(border)
  edges = find_edges(points)
  vertices = find_vertices(edges)
  incorrect = affine_transform(image, vertices)
  correct = inverse_perspective(image, vertices)
  return correct

def main(args):
  if len(args) < 3:
    print "Usage: python cover.py input.jpg output.jpg"
    return
  output = pipeline(Image.open(args[1]))
  output.save(args[2])

if __name__ == "__main__":
  main(sys.argv)
