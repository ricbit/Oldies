// Demetrio 1.0
// Bolinha.cpp

#include "bolinha.h"

Bolinha::Bolinha (char *x,char *y) {
  tabelao_ti=0.0;
  tabelao_tf=0.0;
  tabelao_frames = 0;
  tabelao = (bolinha_coords *) malloc (sizeof(bolinha_coords));
  Receive (x,y);
}

void Bolinha::Receive (char *x="",char *y="") {
  xt.Receive (x);
  yt.Receive (y);
}

void Bolinha::Precalculate (double ti, double tf, int frames) {
  int i;
  double
    ta,                        // instante atual
    dt,                        // tempo por quadro
    tif;                       // comprimento do intervalo de tempo

  if ((tabelao_ti != ti)||
      (tabelao_tf != tf)||
      (tabelao_frames != frames)) {
    tabelao=(bolinha_coords *)realloc(tabelao,frames*sizeof(bolinha_coords));
    tif = tf - ti;
    dt = tif/double (frames);
    i = 0;
    for (ta = ti; ta < tf; ta+=dt) {
      // 'T' - 'A' == 19
      xt.Let(19, ta);
      yt.Let(19, ta);
      tabelao[i].x = xt.Evaluate();
      tabelao[i].y = yt.Evaluate();
      if (tabelao[i].x > xmax) xmax = tabelao[i].x;
      if (tabelao[i].y > ymax) ymax = tabelao[i].y;
      if (tabelao[i].x < xmin) xmin = tabelao[i].x;
      if (tabelao[i].y < ymin) ymin = tabelao[i].y;
      i++;
    }
  }
}


void Bolinha::Draw (int frame) {
//  circle((int)tabelao[frame].x, (int)tabelao[frame].y, 10);
  putpixel((int)tabelao[frame].x, (int)tabelao[frame].y,15);
}