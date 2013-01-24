package govelha

import "fmt"
import "testing"

func TestPermutations(t *testing.T) {
  for i := 3; i < 6; i++ {
    count := make(map[string] bool)
    for perm := range Permutations(i) {
      if len(perm) != i {
        t.Errorf("len(%v) != %d", perm, i)
      }
      mask := 0
      for j := 0; j < i; j++ {
        mask |= Bit(perm[j])
      }
      if mask != Bit(i) - 1 {
        t.Errorf("Not a permutation: %v", perm)
      }
      count[fmt.Sprint(perm)] = true
    }
    if len(count) != Factorial(i) {
      t.Errorf("Total permutations %d != %d", count, Factorial(i))
    }
  }
}

func TestPowerSet(t *testing.T) {
  for i := 3; i < 6; i++ {
    count := make(map[string] bool)
    for perm := range PowerSet(i) {
      if len(perm) != i {
        t.Errorf("len(%v) != %d", perm, i)
      }
      count[fmt.Sprint(perm)] = true
    }
    if len(count) != Pow(2, i) {
      t.Errorf("Size of power set %d != %d", count, Pow(2, i))
    }
  }
}

func TestProductSet(t *testing.T) {
  for i := 3; i < 6; i++ {
    count := make(map[string] bool)
    for perm := range ProductSet(6, i) {
      if len(perm) != i {
        t.Errorf("len(%v) != %d", perm, i)
      }
      count[fmt.Sprint(perm)] = true
    }
    if len(count) != Pow(6, i) {
      t.Errorf("Size of product set %d != %d", count, Pow(6, i))
    }
  }
}

func TestGeometryRotations(t *testing.T) {
  expected_vec := [][]int {
    {8, 7, 6, 5, 4, 3, 2, 1, 0},
    {6, 7, 8, 3, 4, 5, 0, 1, 2},
    {2, 1, 0, 5, 4, 3, 8, 7, 6},
    {0, 1, 2, 3, 4, 5, 6, 7, 8},
    {8, 5, 2, 7, 4, 1, 6, 3, 0},
    {6, 3, 0, 7, 4, 1, 8, 5, 2},
    {2, 5, 8, 1, 4, 7, 0, 3, 6},
    {0, 3, 6, 1, 4, 7, 2, 5, 8},
  }
  expected := make(map[string] bool)
  for vec := range expected_vec {
    expected[fmt.Sprint(vec)] = true
  }
  geometry := NewGeometry(NewSignature(3, 2))
  count := 0
  for rot := range geometry.Rotations {
    if !expected[fmt.Sprint(rot)] {
      t.Errorf("Wrong rotation: %v", rot)
    } else {
      count++
    }
  }
  if count != len(expected) {
    t.Errorf("Wrong number of rotations: %d != %d", count, len(expected))
  }
}

func CheckSet(t *testing.T, set Set, hash uint32, s State, expected bool) {
  if _, ok := set.Present(hash, s); ok != expected {
    t.Errorf("%d:%v != %t on %v", hash, s, expected, set)
  }
}

func TestSet(t *testing.T) {
  set := NewSet()
  s1 := State{1, 2, 3}
  CheckSet(t, set, 1, s1, false)
  set.Insert(1, s1)
  CheckSet(t, set, 1, s1, true)
  CheckSet(t, set, 2, s1, false)
  s2 := State{1, 2, 4}
  CheckSet(t, set, 1, s2, false)
  CheckSet(t, set, 2, s2, false)
  set.Insert(2, s2)
  CheckSet(t, set, 2, s2, true)
}

func buildState(sig Signature, values []int) State {
  s := NewState(sig)
  for i, v := range values {
    s.Set(i, v)
  }
  return s
}

func TestRotation(t *testing.T) {
  sig := NewSignature(3, 2)
  geom := NewGeometry(sig)
  s1 := buildState(sig, []int{1,2,1, 1,2,0, 0,2,0})
  s2 := buildState(sig, []int{1,2,1, 0,2,1, 0,2,0})
  found := false
  for _, rot := range geom.Rotations {
    if s1.Equal(s2.CopyRotated(sig, rot)) {
      found = true
    }
  }
  if !found {
    t.Errorf("Rotation not found")
  }
}

func TestEngine(t *testing.T) {
  sig := NewSignature(3, 2)
  engine := NewEngine(sig)
  stats := engine.Run(20, false)
  if stats.endingX != 91 {
    t.Errorf("Wrong number of endings for X: %d != %d", stats.endingX, 91)
  }
  if stats.endingO != 44 {
    t.Errorf("Wrong number of endings for O: %d != %d", stats.endingO, 44)
  }
  if stats.draw != 3 {
    t.Errorf("Wrong number of draws: %d != %d", stats.draw, 3)
  }
}

func TestCanonical(t *testing.T) {
  sig := NewSignature(3, 2)
  geom := NewGeometry(sig)
  state := buildState(sig, []int{0,1,2, 0,0,0, 0,0,0})
  canonical, _ := Canonical(state, &geom)
  expected := buildState(sig, []int{0,0,0, 0,0,0, 0,1,2})
  if !expected.Equal(canonical) {
    t.Errorf("Canonical error:\n%s\n%s\n",
        expected.Render(sig), canonical.Render(sig))
  }
}

func TestDraw(t *testing.T) {
  sig := NewSignature(3, 2)
  geom := NewGeometry(sig)
  state := buildState(sig, []int{2,1,2, 2,1,0, 1,2,1})
  _, draw := isSolution(&geom, state)
  if !draw {
    t.Errorf("Draw not detected")
  }
}
