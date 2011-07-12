// Ray 2.0
// Scene.cpp

#include "Scene.h"

// Procedures da Scene

void Scene::OutRes (int x, int y) {
  Rx=x;
  Ry=y;
}

void Scene::WinRes (int x, int y) {
  Wx=x;
  Wy=y;
}

void Scene::Limits (int X1, int Y1, int X2, int Y2) {
  x1=X1;
  y1=Y1;
  x2=X2;
  y2=Y2;
}

void Scene::AmbLight (Vetor l) {
  la=l;
}

void Scene::Observer (Vetor o) {
  Obs=o;
}

void Scene::ProjPlane (Plano p) {
  Proj=p;
}

void Scene::Background (Vetor b) {
  Back=b;
}

void Scene::operator+= (Objeto *o) {
  l+=o;
}

void Scene::operator+= (Light *l) {
  ll+=l;
}

ostream& _Cdecl operator<< (ostream &a, Scene &s) {
  ostream_withassign x;
  x=a << "--- Cena atual\n";
  x=x << "Resolucao de saida: (" << s.Rx << "," << s.Ry << ")\n";
  x=x << "Tamanho da janela: (" << s.Wx << "," << s.Wy << ")\n";
  x=x << "Janela de renderizacao: (" << s.x1 << "," << s.y1;
  x=x << ")-(" << s.x2 << "," << s.y2 << ")\n";
  x=x << "Observador: " << s.Obs << "\n";
  x=x << "Plano de projecao: " << s.Proj << "\n";
  x=x << "Cor de fundo: " << s.Back << "\n";
  x=x << "Luz ambiente: " << s.la << "\n";
  x=x << s.ll;
  x=x << s.l;
  return x;
}