import cv2
import numpy
import os
import sys

def output(arg, dirname, names, i=[2]):
  label = dirname.split("/")[-1]
  print dirname, i[0]
  label = i[0]
  if 'ricbit' in dirname:
    label = 0
  if 'ila' in dirname:
    label = 1
  for name in names:
    if '.' in name:
      fullname = os.path.join(dirname, name) 
      print fullname
      img = cv2.imread(fullname, cv2.IMREAD_GRAYSCALE)
      arg[0].append(img)
      arg[1].append(label)
  i[0] += 1

def main():
  arg = ([], [])
  os.path.walk(sys.argv[1], output, arg)
  print "Training Fisher"
  r = cv2.createFisherFaceRecognizer()
  r.train(arg[0], numpy.array(arg[1]))
  r.save('ricbit.fisher.xml')
  print "Training Eigen"
  s = cv2.createEigenFaceRecognizer(num_components=9)
  s.train(arg[0], numpy.array(arg[1]))
  s.save('ricbit.eigen.xml')

if __name__ == "__main__":
  main()
