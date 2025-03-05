// Ray 2.0
// Render.h

#ifndef kRender
#define kRender

#include "YoMath.h"
#include "Video.h"
#include "Objects.h"
#include "Scene.h"

class Render {
public:
  Ponto p;
  long RaysShooted,PointsShaded;

  // Calcula a cor do primeiro ponto ao longo da reta r
  Vetor ShootRay (Reta r, Scene s, int it);
  // Renderiza a cena
  Render (Scene s);
  // Estatisticas
  void Stat (void);
};

#endif
