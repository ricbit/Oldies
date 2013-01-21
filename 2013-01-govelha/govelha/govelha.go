package govelha

import "fmt"
import "runtime"
import "time"
import "sort"

// Math helpers.

func Product(n int, value func(int) int) int {
  ans := 1
  for i := 0; i < n; i++ {
    ans *= value(i)
  }
  return ans
}

func Pow(x, n int) int {
  return Product(n, func(int) int {
    return x
  })
}

func Factorial(n int) int {
  return Product(n, func(i int) int {
    return i + 1
  })
}

func Bit(n int) int {
  return int(1 << uint(n))
}

// Combinatorial helpers.

// Generate all permutations of a set.
func Permutations(n int) <-chan []int {
  base := make([]int, n)
  ch := make(chan []int)
  go func() {
    GenPerm(base, 0, 0, n, ch)
    close(ch)
  }()
  return ch
}

func GenPerm(vec []int, pos int, mask int, size int, ch chan []int) {
  for i := 0; i < size; i++ {
    if mask & Bit(i) > 0 {
      continue
    }
    vec[pos] = i
    if pos + 1 == size {
      newvec := make([]int, size)
      copy(newvec, vec)
      ch <- newvec
    } else {
      GenPerm(vec, pos + 1, mask | Bit(i), size, ch)
    }
  }
}


// Generate the power set of a set.
func PowerSet(n int) <-chan []bool {
  ch := make(chan []bool)
  go func() {
    for i := 0; i < Bit(n); i++ {
      set := make([]bool, n)
      for j := 0; j < n; j++ {
        set[j] = i & Bit(j) > 0
      }
      ch <- set
    }
    close(ch)
  }()
  return ch
}

// Generate a cartesian product of sets.
func ProductSet(n int, dim int) <-chan []int {
  ch := make(chan []int)
  go func() {
    size := Pow(n, dim)
    for i := 0; i < size; i++ {
      set := make([]int, dim)
      cur := i
      for j := 0; j < dim; j++ {
        set[j] = cur % n
        cur /= n
      }
      ch <- set
    }
    close(ch)
  }()
  return ch
}

// The Signature of a board is a model of its topology.
type Signature struct {
  Side, Dim int
  numCells, vectorSize int
}

func NewSignature(side int, dim int) Signature {
  numcells := Pow(side, dim)
  return Signature{side, dim, numcells, (numcells + 31) / 32}
}

func (sig Signature) NumCells() int {
  return sig.numCells
}

func (sig Signature) VectorSize() int {
  return sig.vectorSize
}

func (sig Signature) NumRotations() int {
  return Pow(2, sig.Dim) * Factorial(sig.Dim)
}

func (sig Signature) Decode(pos int, vec []int) {
  for i := 0; i < sig.Dim; i++ {
    vec[i] = pos % sig.Side
    pos /= sig.Side
  }
}

func (sig Signature) Encode(vec []int) int {
  pos := 0
  for i := 0; i < sig.Dim; i++ {
    pos = pos * sig.Side + vec[sig.Dim - 1 - i]
  }
  return pos
}

// Encodes the state of board.
type State []uint64

func NewState(sig Signature) State {
  return make(State, sig.VectorSize())
}

func (s State) Decode(pos int) (int, uint) {
  index := pos / 32
  offset := uint((31 - pos % 32) * 2)
  return index, offset
}

func (s State) Set(pos int, value int) {
  index, offset := s.Decode(pos)
  mask := uint64(3) << offset
  s[index] = (s[index] &^ mask) | (uint64(value) << offset)
}

func (s State) Get(pos int) int {
  index, offset := s.Decode(pos)
  return int((s[index] >> offset) & 3)
}

func (s State) ApplyRotation(newstate State, sig Signature, rotation []int) {
  //newstate := NewState(sig)
  size := len(rotation)
  for i := 0; i < size; i++ {
    newstate.Set(i, s.Get(rotation[i]))
  }
}

func (s State) Equal(b State) bool {
  for i, v := range b {
    if s[i] != v {
      return false
    }
  }
  return true
}

func (s State) Less(b State) bool {
  for i, v := range b {
    if v > s[i] {
      return true
    }
    if v < s[i] {
      return false
    }
  }
  return false
}

func (s State) Copy() State {
  newstate := make(State, len(s))
  copy(newstate, s)
  return newstate
}

func (s State) Render(sig Signature) string {
  value := ".XO"
  stride := Pow(sig.Side, sig.Dim / 2)
  size := sig.NumCells()
  out := ""
  for i := 0; i < size; i++ {
    out += string(value[s.Get(int(i))])
    if i % sig.Side == sig.Side - 1 {
      out += " "
    }
    if i % stride == stride - 1 {
      out += "\n"
      if i / stride % sig.Side == sig.Side - 1 {
        out += "\n"
      }
    }
  }
  return out
}


// Set of states
type Set map[uint64] []State

func NewSet() Set {
  return make(Set)
}

func (s Set) Present(hash uint64, state State) bool {
  state_list, ok := s[hash]
  if !ok {
    return false
  }
  for _, cur := range state_list {
    if state.Equal(cur) {
      return true
    }
  }
  return false
}

func (s Set) Insert(hash uint64, state State) {
  s[hash] = append(s[hash], state)
}

// Geometry = Topology + Precalculation
type Geometry struct {
  sig Signature
  Rotations [][]int
  Solutions [][]int
}

func NewGeometry(sig Signature) Geometry {
  rotations := make([][]int, 0, sig.NumRotations())
  for perm := range Permutations(sig.Dim) {
    for sign := range PowerSet(sig.Dim) {
      rotations = append(rotations, boardPermutation(sig, perm, sign))
    }
  }
  solutions := make([][]int, 0, Pow(sig.Side + 2, sig.Dim))
  unique := make(map[string] bool)
  for prod := range ProductSet(sig.Side + 2, sig.Dim) {
    if validSolution(prod) {
      sol := buildSolution(sig, prod)
      hash := fmt.Sprint(sol)
      if !unique[hash] {
        unique[hash] = true
        solutions = append(solutions, sol)
      }
    }
  }
  return Geometry{sig, rotations, solutions}
}

func buildSolution(sig Signature, prod []int) []int {
  ans := make([]int, sig.Dim)
  sol := make([]int, sig.Side)
  for i := 0; i < sig.Side; i++ {
    for j := 0; j < sig.Dim; j++ {
      switch prod[j] {
        case 0:
          ans[j] = i
        case 1:
          ans[j] = sig.Side - 1 - i
        default:
          ans[j] = prod[j] - 2
      }
    }
    sol[i] = sig.Encode(ans)
  }
  sort.Ints(sol)
  return sol
}

func validSolution(sol []int) bool {
  for _, v := range sol {
    if v < 2 {
      return true
    }
  }
  return false
}

func boardPermutation(sig Signature, perm []int, sign []bool) []int {
  size := sig.NumCells()
  ans := make([]int, size)
  pos := make([]int, sig.Dim)
  newpos := make([]int, sig.Dim)
  for i := 0; i < size; i++ {
    sig.Decode(i, pos)
    for j := 0; j < sig.Dim; j++ {
      if sign[j] {
        newpos[j] = pos[perm[j]]
      } else {
        newpos[j] = sig.Side - 1 - pos[perm[j]]
      }
    }
    ans[i] = sig.Encode(newpos)
  }
  return ans
}

// Stack-based buffer.

type Unit struct {
  level int
  ending bool
  state State
}

type StackNode struct {
  unit Unit
  next *StackNode
}

func NewStack(input chan Unit, stats *Stats) chan Unit {
  output := make(chan Unit)
  go func() {
    var top *StackNode = nil
    stats.stack = 0
    for {
      if top == nil {
        unit := <-input
        node := &StackNode{unit, top}
        top = node
        stats.stack++
      } else {
        select {
        case unit := <-input:
          node := &StackNode{unit, top}
          top = node
          stats.stack++
        case output <- top.unit:
          top = top.next
          stats.stack--
        }
      }
    }
  }()
  return output
}

type Stats struct {
  accepted, rejected, ignored, endingX, endingO, draw, stack int
}

func PrintStats(stats *Stats) {
  for {
    fmt.Printf("gorot %4d acc %8d rej %8d ign %8d end %5d stack %5d %c",
        runtime.NumGoroutine(), stats.accepted, stats.rejected,
        stats.ignored, stats.endingX + stats.endingO + stats.draw,
        stats.stack, 13)
    time.Sleep(1 * time.Second)
  }
}

// Engine

func Engine(sig Signature, maxlevel int) Stats {
  geom := NewGeometry(sig)
  set := NewSet()
  count := 1
  accept := make(chan Unit, sig.NumCells())
  accept <- Unit{0, false, NewState(sig)}
  trych := make(chan bool)
  numcells := sig.NumCells()
  stats := Stats{}
  stack := NewStack(accept, &stats)
  go PrintStats(&stats)
  for count > 0 {
    select {
    case unit := <-stack:
      hash := HashState(unit.state)
      if !set.Present(hash, unit.state) {
        set.Insert(hash, unit.state)
        if unit.level < maxlevel && !unit.ending {
          tries := 0
          for i := 0; i < numcells; i++ {
            if unit.state.Get(i) == 0 {
              newstate := unit.state.Copy()
              newstate.Set(i, unit.level % 2 + 1)
              go Check(&geom, &set, newstate, unit.level + 1,
                       accept, trych)
              tries++
            }
          }
          for i := 0; i < tries; i++ {
            if <-trych {
              count++
              stats.rejected++
            }
          }
        }
        if unit.ending {
          if unit.level % 2 == 0 {
            stats.endingO++
          } else {
            stats.endingX++
          }
        } else {
          if unit.level == numcells {
            stats.draw++
          }
        }
        stats.accepted++
      } else {
        stats.ignored++
      }
      count--
    }
  }
  fmt.Printf("\n\naccepted %d\n", stats.accepted)
  fmt.Printf("rejected %d\n", stats.rejected)
  fmt.Printf("ignored %d\n", stats.ignored)
  fmt.Printf("endings X %d\n", stats.endingX)
  fmt.Printf("endings O %d\n", stats.endingO)
  fmt.Printf("draws %d\n", stats.draw)
  fmt.Printf("stack %d\n", stats.stack)
  return stats
}

func Check(geom *Geometry, set *Set, state State, level int,
           accept chan Unit, try chan bool) {
  chosen := Canonical(state, geom)
  hash := HashState(chosen)
  if set.Present(hash, chosen) {
    try <- false
  } else {
    accept <- Unit{level, isSolution(geom, chosen), chosen}
    try <- true
  }
}

func Canonical(state State, geom *Geometry) State {
  candidate := make([]int, len(geom.Rotations))
  for i := range geom.Rotations {
    candidate[i] = i
  }
  end := len(geom.Rotations) - 1
  for pos := 0; end > 0 && pos < geom.sig.NumCells(); pos++ {
    min := 3
    start := 0
    for i := 0; i <= end; i++ {
      v := state.Get(geom.Rotations[candidate[i]][pos])
      switch {
      case v < min:
        min = v
        candidate[0] = candidate[i]
        start = 1
      case v == min:
        candidate[start] = candidate[i]
        start++
      }
    }
    end = start - 1
  }
  chosen := state.Copy()
  state.ApplyRotation(chosen, geom.sig, geom.Rotations[candidate[0]])
  return chosen
}

func isSolution(geom *Geometry, s State) bool {
  for _, sol := range geom.Solutions {
    if matchSolution(sol, s) {
      return true
    }
  }
  return false
}

func matchSolution(sol []int, s State) bool {
  v := s.Get(sol[0])
  if v == 0 {
    return false
  }
  for _, x := range sol {
    if v != s.Get(x) {
      return false
    }
  }
  return true
}

func HashState(state State) uint64 {
  ans := uint64(0)
  for _, v := range state {
    ans ^= v
  }
  return ans
}
