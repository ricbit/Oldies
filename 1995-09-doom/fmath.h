/* Fast vector math header file */
/* Ricardo Bittencourt (9/95) */

typedef float real;
typedef struct {
  real dx,dy,dz;
} vector;

vector init;

#define add_vector(a,b,v) \
{\
  (v).dx=(a).dx+(b).dx;\
  (v).dy=(a).dy+(b).dy;\
  (v).dz=(a).dz+(b).dz;\
}

#define self_add_vector(v,a) \
{\
  (v).dx+=(a).dx;\
  (v).dy+=(a).dy;\
  (v).dz+=(a).dz;\
}

#define sub_vector(a,b,v) \
{\
  (v).dx=(a).dx-(b).dx;\
  (v).dy=(a).dy-(b).dy;\
  (v).dz=(a).dz-(b).dz;\
}

#define self_sub_vector(v,a) \
{\
  (v).dx-=(a).dx;\
  (v).dy-=(a).dy;\
  (v).dz-=(a).dz;\
}

#define dot_product(a,b) \
  ((a).dx*(b).dx+(a).dy*(b).dy+(a).dz*(b).dz)

#define scalar_product(a,n,v) \
{\
  (v).dx=(n)*(a).dx;\
  (v).dy=(n)*(a).dy;\
  (v).dz=(n)*(a).dz;\
}

#define self_scalar_product(v,n) \
{\
  (v).dx*=(n);\
  (v).dy*=(n);\
  (v).dz*=(n);\
}

#define cross_product(a,b,v) \
{\
  (v).dx=(a).dy*(b).dz-(a).dz*(b).dy;\
  (v).dy=(a).dz*(b).dx-(a).dx*(b).dz;\
  (v).dz=(a).dx*(b).dy-(a).dy*(b).dx;\
}

#define Vector(x,y,z) \
  (init.dx=(x),init.dy=(y),init.dz=(z),init)

#define assume_vector(x,y,z,v) \
{\
  (v).dx=(x);\
  (v).dy=(y);\
  (v).dz=(z);\
}

#define compose_vector(a,n,b,v) \
{\
  (v).dx=(a).dx*(n)-(b).dx;\
  (v).dy=(a).dy*(n)-(b).dy;\
  (v).dz=(a).dz*(n)-(b).dz;\
}