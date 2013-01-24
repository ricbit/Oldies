package govelha

import "fmt"
import "flag"
import "runtime"
import "os"
import "bufio"
import "time"
import "sort"
import "hash/crc32"
import "bytes"
import "encoding/binary"

// Flags

var dotfile = flag.String("dotfile", "", "File name of dot file")

// Math helpers.

func Product(n int, value func(int) int) int {
  ans := 1
  for i := 0; i < n; i++ {
    ans *= value(i)
  }
  return ans
}

// Calculate x ** n
func Pow(x, n int) int {
  return Product(n, func(int) int {
    return x
  })
}

// Calculate n!
func Factorial(n int) int {
  return Product(n, func(i int) int {
    return i + 1
  })
}

// Create a bitmask with a single bit n.
func Bit(n int) int {
  return int(1 << uint(n))
}

func ConvertBase(x int, b int, ans []int) {
  for i := 0; i < len(ans); i++ {
    ans[i] = x % b
    x /= b
  }
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
      ConvertBase(i, n, set)
      ch <- set
    }
    close(ch)
  }()
  return ch
}

// Returns a list the with first n natural numbers.
func IntegerList(n int) []int {
  list := make([]int, n)
  for i := 0; i < n; i++ {
    list[i] = i
  }
  return list
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
  ConvertBase(pos, sig.Side, vec)
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
  offset := (31 - uint(pos) % 32) * 2
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

func (s State) CopyRotated(sig Signature, rotation []int) State {
  newstate := NewState(sig)
  size := len(rotation)
  for i := 0; i < size; i++ {
    newstate.Set(i, s.Get(rotation[i]))
  }
  return newstate
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

func (s State) RenderHTML(sig Signature) string {
  value := ".XO"
  stride := Pow(sig.Side, sig.Dim / 2)
  size := sig.NumCells()
  out := "<table><tr>"
  for i := 0; i < size; i++ {
    out += "<td>" + string(value[s.Get(int(i))]) + "</td>"
    if i % sig.Side == sig.Side - 1 {
      out += " "
    }
    if i % stride == stride - 1 {
      out += "</tr>"
      if i != size - 1 {
        out += "<tr>"
      }
    }
  }
  out += "</table>"
  return out
}

// Set of states
type Set map[uint32] []StateInfo

type StateInfo struct {
  state State
  value int8
}

func NewSet() Set {
  return make(Set)
}

func (s Set) Present(hash uint32, state State) (int, bool) {
  state_list, ok := s[hash]
  if !ok {
    return 0, false
  }
  for i, cur := range state_list {
    if state.Equal(cur.state) {
      return i, true
    }
  }
  return 0, false
}

func (s Set) Insert(hash uint32, state State) int {
  s[hash] = append(s[hash], StateInfo{state,  0})
  pos := len(s[hash]) - 1
  if pos == 255 {
    panic(fmt.Sprintf("Too many collision on hash %x", hash))
  }
  return pos
}

func (s Set) MaxCollision() int {
  max := 0
  for _, v := range s {
    if len(v) > max {
      max = len(v)
    }
  }
  return max
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
        top = PushStack(<-input, top, stats)
      } else {
        select {
        case unit := <-input:
          top = PushStack(unit, top, stats)
        case output <- top.unit:
          top = top.next
          stats.stack--
        }
      }
    }
  }()
  return output
}

func PushStack(unit Unit, top *StackNode, stats *Stats) *StackNode {
  stats.stack++
  if stats.stack > stats.maxstack {
    stats.maxstack = stats.stack
  }
  return &StackNode{unit, top}
}

// Statistics

type Stats struct {
  accepted, rejected, ignored, endingX, endingO, draw, stack int
  maxstack, maxcollision, drawpruned int
}

func PrintStats(stats *Stats) {
  for {
    fmt.Printf("go %4d acc %8d rej %8d ign %8d end %5d prun %5d stack %4d %c",
        runtime.NumGoroutine(), stats.accepted, stats.rejected,
        stats.ignored, stats.endingX + stats.endingO + stats.draw,
        stats.drawpruned, stats.stack, 13)
    time.Sleep(1 * time.Second)
  }
}

func PrintFinalStats(stats *Stats) {
  fmt.Printf("\n\naccepted %d\n", stats.accepted)
  fmt.Printf("rejected %d\n", stats.rejected)
  fmt.Printf("ignored %d\n", stats.ignored)
  fmt.Printf("endings X %d\n", stats.endingX)
  fmt.Printf("endings O %d\n", stats.endingO)
  fmt.Printf("draws %d\n", stats.draw)
  fmt.Printf("final stack %d\n", stats.stack)
  fmt.Printf("max stack %d\n", stats.maxstack)
  fmt.Printf("max collision %d\n", stats.maxcollision)
  fmt.Printf("pruned by draw %d\n", stats.drawpruned)
  var m runtime.MemStats
  runtime.ReadMemStats(&m)
  fmt.Printf("memory in use %d Mb\n", m.Alloc / 1048576)
}

// Engine

type Unit struct {
  level int
  ending bool
  draw bool
  canonical int
  state State
  hash uint32
}

type Engine struct {
  geom Geometry
  set Set
  accept chan Unit
  result chan bool
  stats Stats
}

func NewEngine(sig Signature) *Engine {
  eng := new(Engine)
  eng.geom = NewGeometry(sig)
  eng.set = NewSet()
  eng.accept = make(chan Unit, sig.NumCells())
  eng.result = make(chan bool)
  return eng
}

func (eng *Engine) Run(maxlevel int, prune bool) Stats {
  stack := NewStack(eng.accept, &eng.stats)
  empty := NewState(eng.geom.sig)
  eng.accept <- Unit{0, false, false, 0, empty, HashState(empty)}
  go PrintStats(&eng.stats)
  for count := 1; count > 0; count-- {
    unit := <-stack
    if _, ok := eng.set.Present(unit.hash, unit.state); ok {
      eng.stats.ignored++
    } else {
      _ = eng.set.Insert(unit.hash, unit.state)
      if !(prune && eng.PruneUnit(unit)) {
        branched, rejected := eng.Branch(unit, maxlevel)
        count += branched
        eng.UpdateStats(unit, rejected)
      }
    }
  }
  eng.stats.maxcollision = eng.set.MaxCollision()
  PrintFinalStats(&eng.stats)
  eng.RenderDotOutput()
  return eng.stats
}

func (eng *Engine) RenderDotOutput() {
  if *dotfile == "" {
    return
  }
  f, _ := os.Create(*dotfile)
  defer f.Close()
  w := bufio.NewWriter(f)
  defer w.Flush()
  w.WriteString("digraph velha {\n")
  for hash, value := range eng.set {
    for index, stateInfo := range value {
      fmt.Printf("state %08X %d\n", hash, index)
      w.WriteString(fmt.Sprintf("x%08x_%d [label=<%s>]\n",
          hash, index, stateInfo.state.RenderHTML(eng.geom.sig)))
      parents := make([]State, 0)
      for parent := range eng.Parents(stateInfo.state) {
        parentHash := HashState(parent)
        _, ok := eng.set.Present(parentHash, parent)
        if ok {
          parents = append(parents, parent)
        }
      }
      if len(parents) > 0 {
        parentHash := HashState(parents[0])
        parentIndex, _ := eng.set.Present(parentHash, parents[0])
        w.WriteString(fmt.Sprintf("x%08x_%d -> x%08x_%d;\n",
            parentHash, parentIndex, hash, index))
      }
    }
  }
  w.WriteString("}")
}

func (eng *Engine) Parents(state State) chan State {
  out := make(chan State)
  go func() {
    var mark int
    if isXTurn(state, eng.geom.sig) {
      mark = 2
    } else {
      mark = 1
    }
    set := make(map[string] bool)
    for i := 0; i < eng.geom.sig.NumCells(); i++ {
      if state.Get(i) == mark {
        newstate := state.Copy()
        newstate.Set(i, 0)
        canonical, _ := Canonical(newstate, &eng.geom)
        s := fmt.Sprint(canonical)
        if _, ok := set[s]; !ok {
          set[s] = true
          out <- canonical
        }
      }
    }
    close(out)
  }()
  return out
}

func isXTurn(state State, sig Signature) bool {
  var count [3]int
  for i := 0; i < sig.NumCells(); i++ {
    count[state.Get(i)]++
  }
  return count[1] == count[2]
}

func (eng *Engine) UpdateStats(unit Unit, rejected int) {
  eng.stats.accepted++
  eng.stats.rejected += rejected
  if unit.ending {
    if unit.level % 2 == 0 {
      eng.stats.endingO++
    } else {
      eng.stats.endingX++
    }
  } else {
    if unit.level == eng.geom.sig.NumCells() {
      eng.stats.draw++
    }
  }
}

func (eng *Engine) PruneUnit(unit Unit) bool {
  if unit.draw {
    eng.stats.drawpruned++
    return true
  }
  return false
}

func (eng *Engine) Branch(unit Unit, maxlevel int) (int, int) {
  accepted, rejected, launched := 0, 0, 0
  if unit.level < maxlevel && !unit.ending {
    for pos := 0; pos < eng.geom.sig.NumCells(); pos++ {
      if unit.state.Get(pos) == 0 {
        eng.LaunchBranch(unit, pos)
        launched++
      }
    }
    for i := 0; i < launched; i++ {
      if <-eng.result {
        accepted++
      } else {
        rejected++
      }
    }
  }
  return accepted, rejected
}

func (eng *Engine) LaunchBranch(unit Unit, pos int) {
  newstate := unit.state.Copy()
  newstate.Set(pos, unit.level % 2 + 1)
  go eng.Check(newstate, unit.level, pos, unit.canonical)
}

func (eng *Engine) Check(state State, level, p, prevcan int) {
  // I think p and prevcan can be used to optimize Canonical.
  // Must think more about it.
  chosen, canonical := Canonical(state, &eng.geom)
  hash := HashState(chosen)
  if _, ok := eng.set.Present(hash, chosen); ok {
    eng.result <- false
  } else {
    ending, draw := isSolution(&eng.geom, chosen)
    eng.accept <- Unit{level + 1, ending, draw, canonical, chosen, hash}
    eng.result <- true
  }
}

func Canonical(state State, geom *Geometry) (State, int) {
  candidate := IntegerList(len(geom.Rotations))
  end := len(geom.Rotations) - 1
  for pos := 0; end > 0 && pos < geom.sig.NumCells(); pos++ {
    min, next := 3, 0
    for i := 0; i <= end; i++ {
      v := state.Get(geom.Rotations[candidate[i]][pos])
      switch {
      case v < min:
        min = v
        candidate[0] = candidate[i]
        next = 1
      case v == min:
        candidate[next] = candidate[i]
        next++
      }
    }
    end = next - 1
  }
  chosen := state.CopyRotated(geom.sig, geom.Rotations[candidate[0]])
  return chosen, candidate[0]
}

func isSolution(geom *Geometry, s State) (ending, draw bool) {
  ending, draw = false, true
  for _, sol := range geom.Solutions {
    hist := matchSolution(sol, s)
    for i := 1; i <= 2; i++ {
      if hist[i] == geom.sig.Side {
        ending, draw = true, false
        return
      }
      if hist[i] + hist[0] == geom.sig.Side {
        draw = false
      }
    }
  }
  return
}

func matchSolution(sol []int, s State) [3]int {
  var ans [3]int
  for _, x := range sol {
    ans[s.Get(x)]++
  }
  return ans
}

func HashState(state State) uint32 {
  buf := new(bytes.Buffer)
  binary.Write(buf, binary.LittleEndian, state)
  return crc32.ChecksumIEEE(buf.Bytes())
}
