// Ray 2.0
// Objects.cpp

#include "Objects.h"

// Procedures da Ponto

Ponto::Ponto (void) {
  Prox=NULL;
  Obj=NULL;
}

void Ponto::Inclui (Float k, Objeto *obj) {
  Ponto *p;
  Float q;
  if (tipo)
    q=0;
  else
    q=eps;
  if (k<q) return;
  if (Obj==NULL) {
    Obj=obj;
    t=k;
  } else {
    p=this;
    while (p->Prox!=NULL)
      p=p->Prox;
    p->Prox=new (Ponto);
    p->Prox->Prox=NULL;
    p->Prox->Obj=obj;
    p->Prox->t=k;
  }
}

Ponto Ponto::First (Reta r) {
  Ponto *p,*s;
  Float k;
  p=s=this;
  k=t;
  while (p!=NULL) {
    p=p->Prox;
    if (p->t < k) {
      k=p->t;
      s=p;
    }
  }
  s->pos=r|k;
  s->n=s->Obj->Normal (s->pos);
  return *s;
}

void Ponto::Limpa (void) {
  Ponto *p,*l;
  p=this;
  while (Prox!=NULL) {
    l=p->Prox;
    p->Prox=l->Prox;
    delete l;
  }
  Obj=NULL;
  Prox=NULL;
}

void Ponto::CalcShadows (void) {
  tipo=1;
}

void Ponto::CalcInter (void) {
  tipo=0;
}

// Procedures da List

List::List (void) {
  Prox=NULL;
  Obj=NULL;
}

void List::SemiReta (Reta r, Ponto *P) {
  List *L;
  L=this;
  while (L!=NULL) {
    L->Obj->Intersect (r,P);
    L=L->Prox;
  }
}

void List::operator+= (Objeto *obj) {
  List *L;
  if (Obj==NULL)
    Obj=obj;
  else {
    L=this;
    while (L->Prox!=NULL)
      L=L->Prox;
    L->Prox=new (List);
    L->Prox->Obj=obj;
    L->Prox->Prox=NULL;
  }
}

ostream& _Cdecl Objeto::operator<< (ostream &a) {
  return a << "Objeto Generico";
}

ostream& _Cdecl operator<< (ostream &a, List &l) {
  List *L;
  ostream_withassign x;
  x=a;
  L=&l;
  while (L->Obj!=NULL) {
    x=(*(L->Obj)) << x;
    L=L->Prox;
  }
  return x;
}

