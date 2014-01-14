package main

import "fmt"
import "net"
import "strconv"
import "strings"
import "io/ioutil"

type WebServer struct {
  base_path string
  listener net.Listener
}

func create_server(port int, base_path string) *WebServer {
  listener, err := net.Listen("tcp", ":" + strconv.Itoa(port))
  if err != nil {
    fmt.Println("Error creating server.")
    return nil
  }
  return &WebServer{base_path, listener}
}

func send_data(s net.Conn, data []byte) {
  left := len(data)
  for left != 0 {
    sent, _ := s.Write(data)
    data = data[sent:left]
    left -= sent
  }
}

func send_string(s net.Conn, data string) {
  send_data(s, []byte(data))
}

func (s *WebServer) serve_page(socket net.Conn) {
  defer socket.Close()
  request := make([]byte, 1024)
  req_size, err := socket.Read(request)
  if err != nil || req_size == 0 {
    return
  }
  headers := strings.Split(string(request[0:req_size]), "\r\n")
  if len(headers) < 1 {
    send_string(socket, "HTTP/1.1 400 Bad Request\r\n")
    return
  }
  action := strings.Split(headers[0], " ")
  if len(action) < 1 {
    send_string(socket, "HTTP/1.1 400 Bad Request\r\n")
    return
  }
  if len(action) < 3 || (action[2] != "HTTP/1.0" && action[2] != "HTTP/1.1") {
    send_string(socket, "HTTP/1.1 505 HTTP Version Not Supported\r\n")
    return
  }
  if action[0] != "GET" {
    send_string(socket, "HTTP/1.1 501 Not Implemented\r\n")
    return
  }
  file, err := ioutil.ReadFile(s.base_path + action[1])
  if err != nil {
    send_string(socket, "HTTP/1.1 404 Not Found\r\n")
    return
  }
  response := "HTTP/1.0 200 OK\r\nContent-Length: "
  response += strconv.Itoa(len(file)) + "\r\n\r\n"
  send_string(socket, response)
  send_data(socket, file)
}

func (s *WebServer) start() {
  for {
    socket, err := s.listener.Accept()
    if err != nil {
      fmt.Println("Error on accept.");
      return;
    }
    go s.serve_page(socket)
  }
}

func main() {
  server := create_server(8080, "/home/ricbit/work/blog/face/")
  server.start()
}
