import cv2
import os
import sys

fisher = cv2.createFisherFaceRecognizer()
fisher.load('ricbit.fisher.xml')
eigen = cv2.createEigenFaceRecognizer()
eigen.load('ricbit.eigen.xml')
cascade = cv2.CascadeClassifier('haarcascade_frontalface_alt.xml')

def DetectFaces(img):
  oy, ox, _ = img.shape
  factor = 1000.0 / ox
  newimg = cv2.resize(img, (1000, int(oy * factor)))
  faces = cascade.detectMultiScale(
      newimg, 1.2, 2, cv2.cv.CV_HAAR_DO_CANNY_PRUNING)
  ans = []
  for face in faces:
    x, y, dx, dy = face
    cropped = cv2.getRectSubPix(newimg, (dx, dy), (x + dx / 2, y + dy / 2))
    grayscale = cv2.cvtColor(cropped, cv2.COLOR_BGR2GRAY)
    resized = cv2.resize(grayscale, (92, 112))
    labelf, conff = fisher.predict(resized)
    labele, confe = eigen.predict(resized)
    if labelf == 0 and labele == 0:
      if conff > 400: continue
      mean, stddev = cv2.meanStdDev(resized)
      if stddev[0] < 30: continue
      print 'found: ', conff, confe
      ans.append(map(lambda x: int(x / factor), face))
  return ans

def output(arg, dirname, names):
  print dirname
  for name in names:
    fullname = os.path.join(dirname, name) 
    print fullname
    if not('jpg' in fullname.lower() or 'jpeg' in fullname.lower()):
      continue
    try:
      img = cv2.imread(fullname)
    except Exception:
      continue
    faces = DetectFaces(img)
    for i, face in enumerate(faces):
      x, y, dx, dy = face
      cropped = cv2.getRectSubPix(
        img, (int(dx * 2), int(dy * 2)), (x + dx / 2, y + dy / 2))
      savename = os.path.join(sys.argv[2], fullname.replace('/', '_') + str(i))
      cv2.imwrite(savename + ".jpg", cropped)


def main():
  arg = []
  os.path.walk(sys.argv[1], output, arg)


if __name__ == '__main__':
  main()
  
