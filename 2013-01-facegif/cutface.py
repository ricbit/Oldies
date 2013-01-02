import cv
import os
import sys

def DetectFaces(image):
  cascade = cv.Load('haarcascade_frontalface_alt.xml')
  storage = cv.CreateMemStorage(0)
  return cv.HaarDetectObjects(
      image, cascade, storage, 1.2, 2, cv.CV_HAAR_DO_CANNY_PRUNING)

def cut_image(image):
  grayscale = cv.CreateImage(cv.GetSize(image), 8, 1)
  cv.CvtColor(image, grayscale, cv.CV_BGR2GRAY)
  #cv.EqualizeHist(grayscale, grayscale)

  faces = DetectFaces(grayscale)
  ans = []
  for face in faces:
    x, y, dx, dy = face[0]
    cropped = cv.CreateMat(dx, dy, cv.CV_8UC1)
    cv.GetRectSubPix(grayscale, cropped, (x + dx / 2, y + dy / 2))
    resized = cv.CreateImage((92, 112), 8, 1)
    cv.Resize(cropped, resized)
    ans.append(resized)
  return ans

def main():
  path = sys.argv[1]
  i = 0
  for filename in os.listdir(path):
    fullpath = os.path.join(path, filename) 
    print fullpath
    image = cv.LoadImage(fullpath)
    
    for cut in cut_image(image):
      output = os.path.join(sys.argv[2], '%d.jpg' % i)
      cv.SaveImage(output, cut)
      i += 1


if __name__ == '__main__':
  main()
  
