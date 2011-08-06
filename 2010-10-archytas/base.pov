// Scripts to render Archytas solution to the Delian problem.
// Ricardo Bittencourt 2010

#include "colors.inc"

#declare axis_radius = 0.01;

background { color Cyan }

camera {
  direction <0, 0, 1>
  rotate <15, -25, 0>
  location <0, 0.5, -5>
}

#declare Axis = union {
  // X Axis
  cylinder {
    <-3, 0, 0>,
    <3, 0, 0>,
    axis_radius
    pigment { color Black }
  }

  // Y Axis
  cylinder {
    <0, -3, 0>,
    <0, 3, 0>,
    axis_radius
    pigment { color Black }
  }

  // Z Axis
  cylinder {
    <0, 0, -3>,
    <0, 0, 3>,
    axis_radius
    pigment { color Black }
  }
  no_shadow
}

#declare CircleY = torus {
  1, axis_radius
  rotate <0, 0, 90>
  translate <1, 0, 0>
  no_shadow
  pigment { color Red }
}

#declare CircleX = torus {
  1, axis_radius
  translate <1, 0, 0>
  no_shadow
  pigment { color Red }
}

#declare CircleZ = torus {
  1, axis_radius
  rotate <90, 0, 0>
  translate <1, 0, 0>
  no_shadow
  pigment { color Red }
}

light_source { <0, 2, -4> color White }

