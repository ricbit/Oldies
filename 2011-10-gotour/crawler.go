package main

import (
  "os"
  "fmt"
)

type UrlResponse struct {
  url string
  ans chan bool
}

var unique chan UrlResponse

func UniqueURL() {
  urlset := make(map[string]int)
  for {
    urlresponse := <-unique
    urlresponse.ans <- urlset[urlresponse.url] == 0
    urlset[urlresponse.url]++
  }
}

type Fetcher interface {
  // Fetch returns the body of URL and
  // a slice of URLs found on that page.
  Fetch(url string) (body string, urls []string, err os.Error)
}

// Crawl uses fetcher to recursively crawl
// pages starting with url, to a maximum of depth.
func Crawl(url string, depth int, fetcher Fetcher, finish chan int) {
  defer func() {
    finish <- 1
  }()
  resp := UrlResponse{url, make(chan bool)}
  unique <- resp
  if !<-resp.ans {
    return
  }
  if depth <= 0 {
    return
  }
  body, urls, err := fetcher.Fetch(url)
  if err != nil {
    fmt.Println(err)
    return
  }
  fmt.Printf("found: %s %q\n", url, body)
  parallel := make(chan int)
  for _, u := range urls {
    go Crawl(u, depth-1, fetcher, parallel)
  }
  for i := 0; i < len(urls); i++ {
    <-parallel
  }
  return
}

func main() {
  unique = make(chan UrlResponse)
  go UniqueURL()
  finish := make(chan int)
  go Crawl("http://golang.org/", 4, fetcher, finish)
  <-finish
}

// fakeFetcher is Fetcher that returns canned results.
type fakeFetcher map[string]*fakeResult

type fakeResult struct {
  body string
  urls []string
}

func (f *fakeFetcher) Fetch(url string) (string, []string, os.Error) {
  if res, ok := (*f)[url]; ok {
    return res.body, res.urls, nil
  }
  return "", nil, fmt.Errorf("not found: %s", url)
}

// fetcher is a populated fakeFetcher.
var fetcher = &fakeFetcher{
  "http://golang.org/": &fakeResult{
    "The Go Programming Language",
    []string{
      "http://golang.org/pkg/",
      "http://golang.org/cmd/",
    },
  },
  "http://golang.org/pkg/": &fakeResult{
    "Packages",
    []string{
      "http://golang.org/",
      "http://golang.org/cmd/",
      "http://golang.org/pkg/fmt/",
      "http://golang.org/pkg/os/",
    },
  },
  "http://golang.org/pkg/fmt/": &fakeResult{
    "Package fmt",
    []string{
      "http://golang.org/",
      "http://golang.org/pkg/",
    },
  },
  "http://golang.org/pkg/os/": &fakeResult{
    "Package os",
    []string{
      "http://golang.org/",
      "http://golang.org/pkg/",
    },
  },
}
