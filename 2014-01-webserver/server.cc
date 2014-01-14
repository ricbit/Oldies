#include <cerrno>
#include <cstring>
#include <string>
#include <iostream>
#include <sstream>
#include <vector>

#include <fcntl.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/sendfile.h>

using namespace std;

template<typename T>
class ScopeGuard {
 public:
  ScopeGuard(T callback) : callback_(callback) {
  }
  ~ScopeGuard() {
    callback_();
  }
 private:
  T callback_;
};

template<typename T>
ScopeGuard<T> scope_guard(T callback) {
  return ScopeGuard<T>(callback);
}

class WebServer {
 public:
  WebServer(int port, string base_path) 
      : port_(port), socket_(0), base_path_(base_path) {
  }

  bool start() {
    socket_ = socket(AF_INET, SOCK_STREAM, 0);
    if (socket_ == -1) {
      return error("Failed to create socket.");
    }

    int one = 1;
    if (setsockopt(
        socket_, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(int)) == -1) {
      return error("Failed to call setsockopt.");
    }

    struct sockaddr_in server_addr{AF_INET, htons(port_), htonl(INADDR_ANY)};
    if (bind(socket_, 
             reinterpret_cast<struct sockaddr*>(&server_addr),
             sizeof(server_addr)) == -1) {
      return error("Failed to bind.");
    }

    if (listen(socket_, 16) == -1){
      return error("Failed to listen.");
    }

    while (true) {
      int connection = accept(socket_, NULL, NULL);
      if (connection == -1) {
        error("Failed to connect.");
        continue;
      }
      serve_page(connection);
    }
    return true;
  }

 private:
  bool error(string error_string) {
    int saved_error = errno;
    cout << error_string << "\n" << strerror(saved_error) << "\n";
    return false;
  }

  vector<string> split(string original, char delim, char strip=0) {
    vector<string> output;
    stringstream input(original);
    for (string item; getline(input, item, delim);) {
      if (strip) {
        int start = item.find_first_not_of(strip);
        int end = item.find_last_not_of(strip);
        if (start == end) {
          output.push_back("");
        } else {
          output.push_back(string(item, start, end - start + 1));
        }
      } else {
        output.push_back(item);
      }
    }
    return output;
  }

  void send_string(int connection, string response) {
    int left = response.size();
    while (left) {
      int sent = send(connection, 
                      response.data() + response.size() - left, left, 0);
      left -= sent;
    }
  }

  void bad_request(int connection) {
    send_string(connection, "HTTP/1.1 400 Bad Request\r\n");
  }

  void not_found(int connection) {
    send_string(connection, "HTTP/1.1 404 Not Found\r\n");
  }

  void not_implemented(int connection) {
    send_string(connection, "HTTP/1.1 501 Not Implemented\r\n");
  }

  void http_version_not_supported(int connection) {
    send_string(connection, "HTTP/1.1 505 HTTP Version Not Supported\r\n");
  }

  void serve_page(int connection) {
    auto x = scope_guard([=]() {
      close(connection);
    });
    const int max_request_size = 1024;
    string request(max_request_size, 0);
    int size = recv(connection, &request[0], max_request_size, 0);
    if (size <= 0) {
      return;
    }
    vector<string> headers = split(request, '\n', '\r');
    if (headers.empty()) {
      bad_request(connection);
      return;
    }
    vector<string> action = split(headers[0], 32);
    if (action.empty()) {
      bad_request(connection);
      return;
    }
    if (action.size() < 3 || 
        (action[2] != "HTTP/1.0" && action[2] != "HTTP/1.1")) {
      http_version_not_supported(connection);
      return;
    }
    if (action[0] != "GET") {
      not_implemented(connection);
      return;
    }
    string file_name = base_path_ + action[1];
    int file = open(file_name.c_str(), O_RDONLY);
    if (file == -1) {
      not_found(connection);
      return;
    }
    auto y = scope_guard([=]() {
      close(file);
    });
    int file_size = lseek(file, 0, SEEK_END);
    if (!file_size) {
      not_found(connection);
      return;
    }
    stringstream ss;
    ss << "HTTP/1.0 200 OK\r\nContent-Length: " << file_size << "\r\n\r\n";
    send_string(connection, ss.str());
    off_t offset = 0;
    sendfile(connection, file, &offset, file_size);
  }

  int port_;
  int socket_;
  string base_path_;
};

int main() {
  WebServer server(8080, "/home/ricbit/work/blog/face/");
  server.start(); 
  return 0;
}
