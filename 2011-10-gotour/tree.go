package main

import "fmt"
import "tour/tree"

// Walk walks the tree t sending all values
// from the tree to the channel ch.
func Walk(t *tree.Tree, ch chan int) {
  Walk1(t, ch)
  close(ch)
}

func Walk1(t *tree.Tree, ch chan int) {
  if t.Left != nil {
    Walk1(t.Left, ch)
  }
  ch <- t.Value
  if t.Right != nil {
    Walk1(t.Right, ch)
  }
}

// Same determines whether the trees
// t1 and t2 contain the same values.
func Same(t1, t2 *tree.Tree) bool {
  ch1 := make(chan int)
  ch2 := make(chan int)
  go Walk(t1, ch1)
  go Walk(t2, ch2)
  for {
    n1, ok1 := <-ch1
    n2, ok2 := <-ch2
    if ok1 != ok2 {
      return false
    }
    if !ok1 {
      return true
    }
    if n1 != n2 {
      return false
    }
  }
  return false
}

func main() {
  fmt.Println(Same(tree.New(1), tree.New(1)))
  fmt.Println(Same(tree.New(1), tree.New(2)))
}
