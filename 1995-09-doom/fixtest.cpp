#include <iostream.h>
#include "fixed.h"

void main (void) {
  obs o;
  vector a,b,c,w;
  fixed n;
  pixel p;

  Assume (0.0,0.0,1.0,o.T);
  Assume (0.0,1.0,0.0,o.Up);
  Assume (1.0,-1.0,0.5,a);
  Assume (0.1,-2.0,-1.0,b);
  Assume (0.0,0.0,0.0,o.F);
  Assume (-1.0,1.0,10.0,w);
  n=ToFixed (-10);
  CrossProduct (&a,&b,&c);
//  ScalarProduct (&a,ToFixed (-1.0),&c);
  FInvert (&n);
  FSetViewer (&o);
  FProject (&o,&w,&p);
  cout << ToFloat (c.dx) << " " << ToFloat (c.dy) << " " << ToFloat (c.dz);
  cout << "\n";
  cout << "Q: " << ToFloat (o.Q.dx) << " " << ToFloat (o.Q.dy) << " " << ToFloat (o.Q.dz);
  cout << "\n";
  cout << "Vd: " << ToFloat (o.Vd.dx) << " " << ToFloat (o.Vd.dy) << " " << ToFloat (o.Vd.dz);
  cout << "\n";
  cout << "Ud: " << ToFloat (o.Ud.dx) << " " << ToFloat (o.Ud.dy) << " " << ToFloat (o.Ud.dz);
  cout << "\n";
  cout << "T: " << ToFloat (o.T.dx) << " " << ToFloat (o.T.dy) << " " << ToFloat (o.T.dz);
  cout << "\n";
  cout << "R: " << ToFloat (o.R.dx) << " " << ToFloat (o.R.dy) << " " << ToFloat (o.R.dz);
  cout << "\n";
  cout << "P: " << ToFloat (o.P.dx) << " " << ToFloat (o.P.dy) << " " << ToFloat (o.P.dz);
  cout << "\n";
  cout << "w: " << ToFloat (w.dx) << " " << ToFloat (w.dy) << " " << ToFloat (w.dz);
  cout << "\n";
  cout << "F: " << ToFloat (o.F.dx) << " " << ToFloat (o.F.dy) << " " << ToFloat (o.F.dz);
  cout << "\n";
  cout << ToFloat (n) << "\n";
  cout << p.x << " " << p.y << " " << (int) p.Valid << "\n";
}
