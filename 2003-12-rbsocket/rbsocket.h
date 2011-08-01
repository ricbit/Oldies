#ifndef __RBSOCKET_H
#define __RBSOCKET_H

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int socket_server_open (char *ipaddress, int port, int number_clients);
int socket_server_connect (int server_socket_id);
int socket_server_close (int server_socket_id);

int socket_client_connect (char *ipaddress, int port);
int socket_client_close (int client_socket_id);

int socket_send (int socket_id, void *buffer, int length);
int socket_recv (int socket_id, void *buffer, int length);

#endif

