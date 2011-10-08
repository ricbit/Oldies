package main

import (
  "io"
  "os"
  "strings"
)

type rot13Reader struct {
  r io.Reader
}

func Rotate(c, start, end byte) byte {
  if c >= start && c <= end {
    return ((c-start)+13)%26 + start
  }
  return c
}

func (r rot13Reader) Read(p []byte) (n int, err os.Error) {
  n, err = r.r.Read(p)
  for i, _ := range p {
    p[i] = Rotate(p[i], 'A', 'Z')
    p[i] = Rotate(p[i], 'a', 'z')
  }
  return n, err
}

func main() {
  s := strings.NewReader(
    "Lbh penpxrq gur pbqr!")
  r := rot13Reader{s}
  io.Copy(os.Stdout, &r)
}
