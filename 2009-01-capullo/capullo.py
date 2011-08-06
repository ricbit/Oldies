# Script to draw Ricbits in random positions, using pyOpenGL.
# Warning: This is a dirty hack of NeHe's lesson 06, may not be pretty.
# Ricardo Bittencourt 2009

from OpenGL.GL import *
from OpenGL.GLU import *
import random
import pygame
import sys
import PIL.Image
from pygame.locals import *

textures = [1,2]

def resize((width, height)):
  if height==0:
    height=1
  glViewport(0, 0, width, height)
  glMatrixMode(GL_PROJECTION)
  glLoadIdentity()
  gluPerspective(45, 1.0*width/height, 0.1, 100.0)
  glMatrixMode(GL_MODELVIEW)
  glLoadIdentity()

def init():
  glEnable(GL_TEXTURE_2D)
  glEnable(GL_BLEND)                      
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
  load_textures()
  glShadeModel(GL_SMOOTH)
  glClearColor(0.7, 0.7, 1.0, 0.0)
  glClearDepth(1.0)
  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)

def check_pixel(surface, x, y):
  if x<0 or y<0 or x>=surface.get_width() or y>=surface.get_height():
    return False
  color = surface.get_at((x,y))
  return color[1] < 0xA0 and color[0] > 0xA0

def check_region(surface, x, y):
  for i in range(-1,2):
    for j in range(-1,2):
      if check_pixel(surface,x+i,y+j):
        return True
  return False

def load_textures():
  textureSurface = PIL.Image.new('RGBA',(8,8))
  texBuffer = textureSurface.load()
  for i in xrange(8):
    for j in xrange(8):
      if (i+j)%2 == 0:
        texBuffer[i,j] = (0x20, 0x80, 0x20, 0xFF)
      else:
        texBuffer[i,j] = (0x50, 0xB0, 0x50, 0xFF)
  textureRicbit = pygame.image.load("ricbit.jpg").convert_alpha()
  alpha = pygame.surfarray.pixels_alpha(textureRicbit)
  alpha[:,:] = 255
  for i in xrange(textureRicbit.get_width()):
    for j in xrange(textureRicbit.get_height()):
      if check_region(textureRicbit,i,j):
        alpha[i,j] = 0
  textureData = pygame.image.tostring(textureRicbit, "RGBA", 1)

  glBindTexture(GL_TEXTURE_2D, textures[1])
  glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, textureRicbit.get_width(),
                textureRicbit.get_height(), 0,
                GL_RGBA, GL_UNSIGNED_BYTE, textureData);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glBindTexture(GL_TEXTURE_2D, textures[0])
  glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, textureSurface.size[0],
                textureSurface.size[1], 0,
                GL_RGBA, GL_UNSIGNED_BYTE, textureSurface.tostring());
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

def draw_ricbit(i):
  z,x = i
  glTranslate(x, 0, z)
  glBindTexture( GL_TEXTURE_2D, textures[1])
  glBegin(GL_QUADS)
  glTexCoord2f(0.0, 0.0); 
  glVertex3f(-0.5, 0.0, 0.0)
  glTexCoord2f(1.0, 0.0); 
  glVertex3f(0.5, 0.0, 0.0)
  glTexCoord2f(1.0, 1.0); 
  glVertex3f(0.5, 3.0, 0.0)
  glTexCoord2f(0.0, 1.0); 
  glVertex3f(-0.5, 3.0, 0.0)
  glEnd()

  glTranslate(-x, 0, -z)

def draw():
  random.seed(sys.argv[1])
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
  glLoadIdentity()
  glBindTexture( GL_TEXTURE_2D, textures[0] )

  glTranslatef(0.0, -1.5, 0.0)

  glBegin(GL_QUADS)
  glTexCoord2f(0.0, 0.0); 
  glVertex3f(-5.0, 0.0, 1.0)
  glTexCoord2f(1.0, 0.0);
  glVertex3f(5.0, 0.0, 1.0)
  glTexCoord2f(1.0, 1.0); 
  glVertex3f(5.0, 0.0, -20.0)
  glTexCoord2f(0.0, 1.0); 
  glVertex3f(-5.0, 0.0, -20.0)
  glEnd()

  pos = [(random.uniform(-3, -18), i) for i in range(-3,4)]
  pos.sort()
  for i in pos:
    draw_ricbit(i)

def main():
  video_flags = OPENGL
    
  pygame.init()
  pygame.display.set_mode((640,480), video_flags)

  resize((640,480))
  init()
  draw()
  surface = pygame.display.get_surface()
  pygame.image.save(surface, "sshot.jpg")

if __name__ == '__main__': main()

