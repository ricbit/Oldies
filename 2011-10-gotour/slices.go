package main

import "tour/pic"

func Pic(dx, dy int) [][]uint8 {
  img := make([][]uint8, dy)
  for i := 0; i < dy; i++ {
    img[i] = make([]uint8, dx)
    for j := 0; j < dx; j++ {
      img[i][j] = uint8(i/2 + j ^ i/2)
    }
  }
  return img
}

func main() {
  pic.Show(Pic)
}
