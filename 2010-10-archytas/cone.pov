#include "base.pov"

Axis
CircleY

isosurface {
  function { y*y + z*z - x*x }
  contained_by { box { <0, -10, -10>, <10, 10, 10> } }
  max_gradient 100
  pigment { color Yellow transmit 0.3 } 
}

