// Ray 2.0
// YoMath.h

#ifndef kYoMath
#define kYoMath

#include "Compiler.h"

#define eps 0.00001
#define true 1
#define false 0

typedef double Float;

class Vetor {
public:
  Float v[4];

  // Constructor
  Vetor (Float xx, Float yy, Float zz);
  // Constructor vazio
  Vetor () {};
  // Produto escalar
  inline Float operator* (Vetor a);
  // Multiplicacao por escalar
  inline Vetor operator* (Float lambda);
  // Multiplicacao das coordenadas
  inline Vetor operator& (Vetor a);
  // Soma vetorial
  inline Vetor operator+ (Vetor a);
  // Subtracao vetorial
  inline Vetor operator- (Vetor a);
  // Produto vetorial
  inline Vetor operator^ (Vetor a);
  // Igualdade, a menos de epsilon
  inline int operator== (Vetor a);
  // Atribuicao
  inline void operator= (Vetor a);
  // Soma
  inline void operator+= (Vetor a);
  // Subtracao
  inline void operator-= (Vetor a);
  // Multiplicacao por escalar
  inline void operator*= (Float lambda);
  // Normalizacao
  inline Vetor operator! (void);
  // Divide o vetor pelo maior componente
  Vetor operator~ (void);
};

class Reta {
public:
  Vetor o, r;
  // Constructors
  Reta (Float xo=0, Float yo=0, Float zo=0,
	Float xr=1, Float yr=0, Float zr=0);
  Reta (Vetor a, Vetor b);
  // Calcula a reta que comeca em V1 e passa por V2
  // Atencao: o vetor diretor nao esta normalizado
  void TwoPoints (Vetor V1, Vetor V2);
  // Normaliza o vetor diretor da reta
  void Normalize (void);
  // Calcula o vetor dado pelo parametro t
  Vetor operator| (Float t);
};

class Plano {
public:
  Vetor u,v,o;
  // Constructors
  Plano (Float xo=0, Float yo=0, Float zo=0,
	 Float xu=1, Float yu=0, Float zu=0,
         Float xv=0, Float yv=1, Float zv=0);
  Plano (Vetor a, Vetor b, Vetor c);
};

// Redefinicoes para cout
ostream& operator<< (ostream &a, Vetor &v);
ostream& operator<< (ostream &a, Reta &r);
ostream& operator<< (ostream &a, Plano &p);

#endif
