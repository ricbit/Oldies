package main

//import "fmt"

import "flag"
import "govelha"
import "runtime/pprof"
import "os"

func main() {
  flag.Parse()
  f, _ := os.Create("govelha.pprof")
  f2, _ := os.Create("govelha.mprof")
  pprof.StartCPUProfile(f)
  sig := govelha.NewSignature(3, 2)
  engine := govelha.NewEngine(sig)
  engine.Run(20, false)
  pprof.WriteHeapProfile(f2)
  pprof.StopCPUProfile()
}
