// Ray 2.0
// Raytest.cpp

#include <iostream.h>
#include "Esfera.h"
#include "Plano.h"
#include "Scene.h"
#include "Render.h"

void main (void) {
  Scene S;
  S.OutRes (320,200);
  S.WinRes (3,3);
  S.Limits (50,70,320-50,150);
  S.AmbLight (Vetor (0.1,0.1,0.1));
  S.Background (Vetor (0,0,0));
  S.Observer (Vetor (0,0,0));
  S.ProjPlane (Plano (-1.5,-1.5,1,1,0,0,0,1,0));
  S+=&Esfera (Vetor (0,0,3),1.1,Surface (Vetor (1,0.0,0.0),0.3,0.7,16));
  S+=&InfPlane (Plano (0,1.1,3,1,0,0,0,0,1),
                Surface (Vetor (0,1,0),0.3,0.7,256));
//  S+=&Esfera (Vetor (1,0,2),0.4,Surface (Vetor (0.6,0.4,0.2),0.5,0.5,256));
  S+=&Light (Vetor (1,1,0),Vetor (1,1,1));
//  S+=&Light (Vetor (-2,1,0),Vetor (1,0,0));
//  S+=&Light (Vetor (0,-2,0),Vetor (1,0,0));
  cout << S;
  Render R(S);
  R.Stat ();
}
