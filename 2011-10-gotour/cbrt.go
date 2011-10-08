package main

import "fmt"
import "cmath"

func Cbrt(x complex128) complex128 {
  z := x
  for i := 0; i < 10; i++ {
    z = z - (z*z*z-x)/(3*x*x)
  }
  return z
}

func main() {
  fmt.Println(cmath.Pow(2, 1.0/3.0))
  fmt.Println(Cbrt(2))
}
