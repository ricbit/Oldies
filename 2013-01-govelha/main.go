package main

//import "fmt"

import "govelha"
import "runtime/pprof"
import "os"

func main() {
  f, _ := os.Create("govelha.pprof")
  f2, _ := os.Create("govelha.mprof")
  pprof.StartCPUProfile(f)
  sig := govelha.NewSignature(4, 4)
  govelha.Engine(sig, 3)
  pprof.WriteHeapProfile(f2)
  pprof.StopCPUProfile()
}
