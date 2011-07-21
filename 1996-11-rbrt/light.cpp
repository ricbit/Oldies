// RBRT 1.0
// by Ricardo Bittencourt
// Module LIGHT.CPP

#include <stdio.h>
#include "light.h"

// class Light

void Light::SetColor (Vector c) {
  Color=c;
}

// class PunctualLight

void PunctualLight::SetPosition (Vector Pos) {
  Position=Pos;
}

Vector PunctualLight::Shade (Vector P, Vector Normal, Object *Scene) {
  double shade;
  PointList *Q;
  Reta S;

  shade=(!(Position-P))*Normal;
  shade=(shade<0.0)?0.0:shade;
  Q=new PointList;
  S.O=P;
  S.R=Position-S.O;
  Scene->Intersect (S,Q);
  if (Q->Shadow ()) {
    delete Q;
    return Vector (0,0,0);
  }
  else {
    delete Q;
    return Color*shade;
  }
}

void PunctualLight::Print (void) {
  printf ("PLight: %f %f %f\n",Position.dx,Position.dy,Position.dz);
}

// class LightList

LightList::LightList () {
  list=last=NULL;
}

void LightList::Insert (Light *l) {
  if (list==NULL) {
    list=new LightElement;
    list->light=l;
    list->next=NULL;
    last=list;
  }
  else {
    last->next=new LightElement;
    last=last->next;
    last->light=l;
    last->next=NULL;
  }
}

Vector LightList::Shade (Vector P, Vector Normal, Object *scene) {
  LightElement *l;
  Vector shade (0,0,0);

  l=list;
  while (l!=NULL) {
    shade+=l->light->Shade (P,Normal,scene);
    l=l->next;
  }
  return shade;
}

void LightList::Print (void) {
  LightElement *l=list;

  while (l!=NULL) {
    l->light->Print ();
    l=l->next;
  }
}
