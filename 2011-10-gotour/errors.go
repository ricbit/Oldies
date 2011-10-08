package main

import (
  "fmt"
  "os"
)

type ErrNegativeSqrt float64

func (e ErrNegativeSqrt) String() string {
  s := fmt.Sprintf("%f", float64(e))
  return "cannot Sqrt negative number: " + s

}

func Sqrt(x float64) (float64, os.Error) {
  if x < 0.0 {
    return 0, ErrNegativeSqrt(-2)
  }
  z := 1.0
  for i := 0; i < 10; i++ {
    z = z - ((z*z - x) / (2 * x))
  }
  return z, nil
}

func main() {
  fmt.Println(Sqrt(2))
  fmt.Println(Sqrt(-2))
}
