#include "rbsocket.h"

int socket_server_open (char *ipaddress, int port, int number_clients) {
  int socket_id;
  struct sockaddr_in socket_name;

  socket_id=socket (AF_INET, SOCK_STREAM, 0);
  if (socket_id<0)  
    return -1;

  bzero ((char *) &socket_name, sizeof (socket_name));
  socket_name.sin_family=AF_INET;
  socket_name.sin_addr.s_addr=inet_addr (ipaddress);
  socket_name.sin_port=htons (port);

  if (bind (socket_id,(struct sockaddr *) &socket_name, 
      sizeof (socket_name))<0) 
    return -1;

  if (listen (socket_id, number_clients)<0)
    return -1;

  return socket_id;
}

int socket_server_connect (int server_socket_id) {
  int client_length;
  int client_id;
  struct sockaddr_un client_name;
 
  client_length=sizeof (client_name);
  client_id=
    accept (server_socket_id, (struct sockaddr *) &client_name, 
   	    &client_length);

  return client_id;
}

int socket_server_close (int server_socket_id) {
  close (server_socket_id);
  return 0; 
}

int socket_client_connect (char *ipaddress, int port) {
  struct sockaddr_in client_name;
  int client_id;

  client_id=socket (AF_INET, SOCK_STREAM, 0);
  if (client_id<0)
    return -1;  

  bzero ((char *) &client_name, sizeof (client_name));
  client_name.sin_family=AF_INET;
  client_name.sin_addr.s_addr=inet_addr (ipaddress);
  client_name.sin_port=htons (port);
  
  if (connect (client_id, (struct sockaddr *) &client_name, 
      sizeof (client_name))<0)
    return -1;

  return client_id;
}

int socket_client_close (int client_socket_id) {
  close (client_socket_id);
}

int socket_send (int socket_id, void *buffer, int length) {
  int total=length;
  int sent=0;
  
  while (total>0) {
    sent=send (socket_id, buffer, length, 0);
    if (sent<0) {
      total=-1;
      break; 
    }
    total-=sent;
    buffer+=sent;
  }
  return total;
}

int socket_recv (int socket_id, void *buffer, int length) {
  int total=length;
  int sent;

  while (total>0) {
    sent=recv (socket_id, buffer, length, 0);
    if (sent<0) { 
      total=-1;
      break;
    }
    total-=sent; 
    buffer+=sent;
  }
  return total;
}

