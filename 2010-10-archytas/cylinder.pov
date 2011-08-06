#include "base.pov"

Axis
CircleX

isosurface {
  function { z*z + x*x - 2*x }
  contained_by { box { <0, -5, -1>, <2, 5, 1> } }
  max_gradient 10
  pigment { color Yellow filter 0.3 }
}


