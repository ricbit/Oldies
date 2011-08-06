#include "base.pov"

Axis
CircleZ

isosurface {
  function { pow(x*x + y*y + z*z, 2) - 4*(x*x + z*z) }
  contained_by { box { <-2, -2, -2>, <2, 2, 2> } }
  max_gradient 100
  no_shadow
  pigment { color Yellow transmit 0.3 } 
}

