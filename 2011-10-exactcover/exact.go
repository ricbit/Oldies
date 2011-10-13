package main

import "fmt"

type matrix [][]bool
type solution []bool

func PrintListener(out chan *solution) {
  for {
    s := <-out
    if s == nil {
      break
    }
    output := "Solution: "
    for i, value := range *s {
      if (value) {
        output += fmt.Sprintf("%d ", i)
      }
    }
    fmt.Println(output)
  }
}

type state struct {
  m matrix
  sol solution
  cover_row []bool
  cover_col []bool
}

func findMinCol(s state) int {
  count := make([]int, len(s.cover_col))
  min_col := 0
  for j := 0; j < len(s.cover_row); j++ {
    if !s.cover_row[j] {
      for i := 0; i < len(s.cover_col); i++ {
        if !s.cover_col[i] && s.m[j][i] {
          min_col = i
          count[i]++
        }
      }
    }
  }
  for i := 0; i < len(s.cover_col); i++ {
    if !s.cover_col[i] && count[i] < count[min_col] {
      min_col = i
    }
  }
  return min_col
}

func allCovered(s state) bool {
  cols_covered := 0
  for _, value := range s.cover_col {
    if value {
      cols_covered++
    }
  }
  return cols_covered == len(s.m[0])
}

func cover(s state, row int) state {
  var next state
  next.m = s.m
  next.cover_col = make([]bool, len(s.cover_col))
  next.cover_row = make([]bool, len(s.cover_row))
  next.sol = make(solution, len(s.sol))
  copy(next.cover_col, s.cover_col)
  copy(next.cover_row, s.cover_row)
  copy(next.sol, s.sol)
  for i := 0; i < len(s.cover_col); i++ {
    if s.m[row][i] {
      next.cover_col[i] = true
    }
  }
  next.cover_row[row] = true
  next.sol[row] = true
  for j := 0; j < len(s.cover_row); j++ {
    if !s.cover_row[j] {
      for i := 0; i < len(s.cover_col); i++ {
        if next.cover_col[i] && s.m[j][i] {
          next.cover_row[j] = true
          break
        }
      }
    }
  }
  return next
}

func solveRecursive(s state, out chan *solution, finish chan bool) {
  defer func() {
    finish <- true
  }()
  if allCovered(s) {
    out <- &s.sol
    return
  }
  min_col := findMinCol(s)
  inner := make(chan bool)
  count := 0
  for j := 0; j < len(s.cover_row); j++ {
    if !s.cover_row[j] && s.m[j][min_col] {
      count++
      next := cover(s, j)
      go solveRecursive(next, out, inner)
    }
  }
  for i := 0; i < count; i++ {
    <-inner
  }
}

func SolveExactCover(m matrix, out chan *solution, finish chan bool) {
  var s state
  s.m = m
  s.sol = make(solution, len(m))
  s.cover_row = make([]bool, len(m))
  s.cover_col = make([]bool, len(m[0]))
  solveRecursive(s, out, finish)
}

func ReadMatrix() matrix {
  var rows, columns int
  fmt.Scan(&rows, &columns)
  m := make(matrix, rows)
  for j := 0; j < rows; j++ {
    m[j] = make([]bool, columns)
    var s string
    fmt.Scan(&s)
    for i := 0; i < columns; i++ {
      if s[i] == '1' {
        m[j][i] = true
      }
    }
  }
  return m
}

func main() {
  m := ReadMatrix()
  out := make(chan *solution)
  go PrintListener(out)
  finish := make(chan bool)
  go SolveExactCover(m, out, finish)
  <-finish
  out <- nil
}
