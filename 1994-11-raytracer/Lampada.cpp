// Ray 2.0
// Lampada.cpp

#include "Lampada.h"

// procedures da Lampada

Light::Light (Vetor O, Vetor C) {
  o=O;
  cor=C;
}

LightList::LightList (void) {
  Prox=NULL;
  L=NULL;
}

void LightList::operator+= (Light *l) {
  LightList *x;
  if (L==NULL) {
    L=l;
    Prox=NULL;
  } else {
    x=this;
    while (x->Prox!=NULL)
      x=x->Prox;
    x->Prox=new (LightList);
    x->Prox->L=l;
    x->Prox->Prox=NULL;
  }
}

int LightList::Shadow (Vetor pos, Vetor lamp, List list) {
  Ponto P;
  Ponto *p;
  Reta r;
  r.TwoPoints (pos,lamp);
  P.CalcShadows ();
  list.SemiReta (r,&P);
  p=&P;
  while (p!=NULL) {
    if ((p->t > eps) && (p->t < 1)) {
      P.Limpa ();
      return 1;
    }
    p=p->Prox;
  }
  P.Limpa ();
  return 0;
}

Vetor LightList::LightSources (Ponto P, Reta r, List list) {
  LightList *L;
  Vetor cor (0,0,0),d;
  L=this;
  while (L!=NULL) {
    if (!Shadow (P.pos,L->L->o,list)) {
      d=L->L->o - P.pos;
      // Reflexao difusa
      cor+=P.Obj->s.cor & ((L->L->cor)*fabs ((d*P.n)/(d*d)*P.Obj->s.kdl));
      // Reflexao especular
      if (P.Obj->s.ksl!=0)
        cor+=L->L->cor*(P.Obj->s.ksl*exp(P.Obj->s.csl*log(fabs(!((!d)-r.r)*P.n)))/sqrt(d*d));
    }
    L=L->Prox;
  }
  return cor;
}

ostream& _Cdecl operator<< (ostream &a, Light &l) {
  return a << "Lampada pontual\n\tPosicao " << l.o
           << "\n\tCor " << l.cor << "\n";
}

ostream& _Cdecl operator<< (ostream &a, LightList &l) {
  LightList *L;
  L=&l;
  while (L!=NULL) {
    a << (*(L->L));
    L=L->Prox;
  }
  return a;
}
