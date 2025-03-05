// Ray 2.0
// Objects.h

#ifndef kObjects
#define kObjects

#include <iostream>
#include "YoMath.h"
#include "Surface.h"

using namespace std;

class Objeto;

class Ponto {
public:
  Float t;
  int tipo;
  Vetor pos,n;
  Objeto *Obj;
  Ponto *Prox;

  // constructor
  Ponto (void);
  // Inclui um ponto na lista
  void Inclui (Float k, Objeto *obj);
  // Retorna o ponto da lista com menor t
  Ponto First (Reta r);
  // Modo de calculo
  void CalcShadows (void);
  void CalcInter (void);
  // Limpa a lista
  void Limpa (void);
};

class Objeto {
public:
  Surface s;
  // Interseccao
  virtual void Intersect (Reta r, Ponto *p) {Reta x; x=r; p->Limpa ();}
  // Vetor normal
  // Atencao: esta rotina deve voltar um vetor normalizado
  virtual Vetor Normal (Vetor v) {return v;}
  // Saida para texto
  virtual ostream& _Cdecl operator<< (ostream &a);
};

class List {
public:
  List *Prox;
  Objeto *Obj;

  // Constructor
  List (void);
  // Constroi uma lista de pontos de interseccao da reta
  // com todos os objetos
  void SemiReta (Reta r, Ponto *P);
  // Acrescenta um objeto `a lista
  void operator+= (Objeto *obj);
};

ostream& _Cdecl operator<< (ostream &a, Objeto &o);
ostream& _Cdecl operator<< (ostream &a, List &l);

#endif
