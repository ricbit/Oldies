#include "base.pov"

Axis

isosurface {
  function { y*y + z*z - x*x }
  contained_by { box { <0, -10, -10>, <10, 10, 10> } }
  max_gradient 100
  pigment { color Blue transmit 0.3 } 
}

isosurface {
  function { z*z + x*x - 2*x }
  contained_by { box { <0, -5, -1>, <2, 5, 1> } }
  max_gradient 10
  pigment { color Red filter 0.3 }
}


isosurface {
  function { pow(x*x + y*y + z*z, 2) - 4*(x*x + z*z) }
  contained_by { box { <-2, -2, -2>, <2, 2, 2> } }
  max_gradient 100
  no_shadow
  pigment { color Green transmit 0.3 } 
}

