package main

import (
  "image"
  "tour/pic"
)

type Image struct{}

func (i Image) ColorModel() image.ColorModel {
  return image.RGBAColorModel
}

func (i Image) Bounds() image.Rectangle {
  return image.Rectangle{image.Point{0, 0}, image.Point{255, 255}}
}

func (i Image) At(x, y int) image.Color {
  return image.RGBAColor{uint8(x ^ y), uint8(y * x), uint8(x), 255}
}

func main() {
  m := Image{}
  pic.ShowImage(m)
}
