// Ray 2.0
// Render.cpp

#include "Render.h"

// procedures do Render

Vetor Render::ShootRay (Reta r, Scene s, int it) {
  Ponto P,F;
  Vetor c;
//  Vetor k,c,v,rrn;
//  Reta rf;
  P.CalcInter ();
  RaysShooted++;
  it++;
  s.l.SemiReta (r,&P);
  if (P.Obj==NULL) {
    P.Limpa ();
    return s.Back;
  }
  F=P.First (r);
  c = (F.Obj->s.cor & s.la)             // Luz ambiente
    + s.ll.LightSources (F,r,s.l);      // Iluminacao direta das lampadas
/*
    if ((it<1) && (F.Obj->s.ks!=0)) {
    rf.o=F.pos;
    rf.r=r.r-F.n*((F.n*r.r)*2);
    v=(ShootRay (rf,s,it+1))*F.Obj->s.ks;
  }
*/
  P.Limpa ();
  return (~c);
}

Render::Render (Scene s) {
  int i,j;
  Video v;
  Reta r;
  Vetor du,dv;
  Vetor ini,pos;
  PointsShaded=0;
  RaysShooted=0;
  du=s.Proj.u*(Float (s.Wx)/Float (s.Rx));
  dv=s.Proj.v*(Float (s.Wy)/Float (s.Ry));
  ini=s.Proj.o+dv*s.y1;
  v.WaitForKey ();
  v.Init ();
  for (j=s.y1; j<=s.y2; j++) {
    pos=ini+du*s.x1;
    for (i=s.x1; i<=s.x2; i++) {
      r.TwoPoints (s.Obs,pos);
      r.Normalize ();
      v.Point (i,j,v.Inclui (Cor (ShootRay (r,s,0))));
      PointsShaded++;
      pos+=du;
      if (v.KeyPressed ()) {
        v.Close ();
        return;
      }
    }
    ini+=dv;
  }
  v.WaitForKey ();
  v.Close ();
}

void Render::Stat (void) {
  cout << "Raios disparados: " << RaysShooted << "\n";
  cout << "Pontos calculados: " << PointsShaded << "\n";
  cout << "Raios/Ponto: "
       << Float (RaysShooted)/Float (PointsShaded) << "\n";
}