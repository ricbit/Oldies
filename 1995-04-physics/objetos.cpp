#include "objetos.h"

void Scene::Animate (void) {
  int i;
  int gm, gd = DETECT;

  initgraph(&gd, &gm, "");
  for (i=0; i<frames; i++) {
    obj->Draw(i);
  }
//  closegraph();
}

void Scene::Precalculate (double ti, double tf, int fr) {
  obj->Precalculate (ti,tf,fr);
  frames=fr;
}