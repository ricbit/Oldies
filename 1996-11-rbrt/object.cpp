// RBRT 1.0
// by Ricardo Bittencourt
// Module OBJECT.CPP

#include <stdio.h>
#include <stdlib.h>
#include "object.h"

// class PointList

PointList::PointList () {
  list=last=NULL;
}

void PointList::Insert (double dist, Object *owner) {
  if (list==NULL) {
    list=new Point;
    list->t=dist;
    list->next=NULL;
    list->owner=owner;
    last=list;
  }
  else {
    last->next=new Point;
    last=last->next;
    last->t=dist;
    last->owner=owner;
    last->next=NULL;
  }
}

void PointList::Print (void) {
  Point *p=list;

  while (p!=NULL) {
    printf ("Intersect on %f\n",p->t);
    p=p->next;
  }
}

PointList::~PointList () {
  while (list!=NULL) {
    last=list;
    list=list->next;
    delete last;
  }
}

Point *PointList::First (void) {
  Point *p,*first=NULL;

  if (list==NULL)
    return NULL;

  p=list;
  while (p->t<0.0 && p->next!=NULL)  
    p=p->next;
  if (p->t<0.0)
    return NULL;

  first=p;
  while (p->next!=NULL) {
    p=p->next;
    if (p->t>0.0 && p->t<first->t)
      first=p;
  }

  return first;
}

int PointList::Shadow (void) {
  Point *p;

  p=list;
  while (p!=NULL) {
    if (p->t>epsilon && p->t<1.0) 
      return 1;
    p=p->next;
  }
  return 0;
}

// class ObjectList

ObjectList::ObjectList () {
  list=last=NULL;
}

void ObjectList::Insert (Object *o) {
  if (list==NULL) {
    list=new ObjectElement;
    list->obj=o;
    list->next=NULL;
    last=list;
  }
  else {
    last->next=new ObjectElement;
    last=last->next;
    last->obj=o;
    last->next=NULL;
  }
}

void ObjectList::Print (void) {
  ObjectElement *o;

  o=list;
  printf ("Object List:\n");
  while (o!=NULL) {
    o->obj->Print ();
    o=o->next;
  }
}
  
void ObjectList::Intersect (Reta R, PointList *P) {
  ObjectElement *o=list;

  while (o!=NULL) {
    o->obj->Intersect (R,P);
    o=o->next;
  }
}

Vector ObjectList::Normal (Vector v) {
  return v;
}

void ObjectList::Init (void) {
  ObjectElement *o=list;

  while (o!=NULL) {
    o->obj->Init ();
    o=o->next;
  }
}

