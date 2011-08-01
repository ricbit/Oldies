#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rbsocket.h"

int server_socket, client_socket;
int acessos=0;

void caifora (void) {
    socket_server_close (server_socket);
}

int main (int argc, char **argv) {
  char buffer[2];
  char bigbuffer[4000];
  char bigbuffer2[4000];
  char bigbuffer3[4000];
  char bigbuffer4[4000];
  char bigbuffer5[4000];
  char bigbuffer6[4000];
  char bigpointer=0;
  char *output1="<html><head><title>Pagina Inteligente</title></head>"
		"<body>Digite alguma coisa:<p><form name=ricardo method=GET>"
		"<input type=text name=cell></form>";
  char *output2="</body></html>\015\012\015\012";
  int exitnow=0;
  int flag=0;

  server_socket=socket_server_open (argv[1],atoi(argv[2]),1);
  if (server_socket<0) {
    printf ("erro no server socket\n");
    exit (1);
  }
  atexit (caifora);
  do {
    client_socket=socket_server_connect (server_socket);
    acessos++;
  if (client_socket<0) {
    exit (1);
  } else {
    if (fork()==0) {
    flag=0; exitnow=0; strcpy (bigbuffer,""); bigpointer=0; buffer[1]=0;
    do {
      socket_recv (client_socket,buffer,1);
      strcat (bigbuffer,buffer);
      fflush (stdout);
      switch (flag) {
        case 0: if (buffer[0]==0xd) flag++; else flag=0; break;
        case 1: if (buffer[0]==0xa) flag++; else flag=0; break;
        case 2: if (buffer[0]==0xd) flag++; else flag=0; break;
        case 3: if (buffer[0]==0xa) {exitnow=1;flag=0;} else flag=0; break;
      }
    } while (!exitnow);
    strcpy (bigbuffer2,output1);
    sprintf (bigbuffer3,"N&uacute;mero de acessos: %d <p>",acessos);
    strcat (bigbuffer2,bigbuffer3);
    if (strstr (bigbuffer,"cell=")!=NULL) {
      char *s,*p=bigbuffer6;
      strcpy (bigbuffer4,strstr(bigbuffer,"cell=")+5);
      *strstr (bigbuffer4," ")=0;
      for (s=bigbuffer4; *s; s++)
   	if (*s=='+') *s=' ';
      sprintf (bigbuffer5,"</pre><p>Voce digitou <pre>%s<p>",bigbuffer4);
      if (strstr (bigbuffer4,"alguma coisa")!=NULL)
	sprintf (bigbuffer5,"Parabens! Voce descobriu a senha secreta!!");
      strcpy (bigbuffer6,"");
      for (s=bigbuffer5; *s;) {
	if (*s!='%') 
 	  *p++=*s++;
	else
	  *p++=16*(*++s>'9'?*s-'A'+10:*s-'0')+(*++s>'9'?*s++-'A'+10:*s++-'0');
      }
      *p=0;
      strcat (bigbuffer2,bigbuffer6);
    }
    strcat (bigbuffer2,output2);
    socket_send (client_socket,bigbuffer2,strlen(bigbuffer2)+1);
    socket_client_close (client_socket);
    socket_server_close (server_socket);
    }
    else 
    socket_client_close (client_socket);

  }
  } while (1);
}
