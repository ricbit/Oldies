/* RBD 2.0 */
/* Ricardo Bittencourt */
/* module: rbdmain.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "graphics.h"
#include "opsys.h"

#ifdef SYS_MSDOS
#include <conio.h>
#endif

#include "pentium.h"
#include "video.h"
#include "runloop.h"

#define DEMO_DEFAULT            0
#define DEMO_TESTVIDEO          1
#define DEMO_LANDSCAPE          2

char scene_name[80];
int resx=640,resy=480;
int loop_type=DEMO_DEFAULT;

void parse_command_line (int argc, char **argv) {
  int argument_number=0;

  argv++;
  while (--argc) {

    if (!strcmp (*argv,"-resx")) {
      if (!--argc) {
        printf ("resx without argument\n");
        exit (1);
      }
      resx=atoi (*++argv);  
      argv++;
      continue;
    }
    
    if (!strcmp (*argv,"-resy")) {
      if (!--argc) {
        printf ("resy without argument\n");
        exit (1);
      }
      resy=atoi (*++argv);  
      argv++;
      continue;
    }
    
    if (!strcmp (*argv,"-testvideo")) {    
      loop_type=DEMO_TESTVIDEO;
      argv++;
      continue;
    }

    if (!strcmp (*argv,"-landscape")) {    
      loop_type=DEMO_LANDSCAPE;
      argv++;
      continue;
    }

    switch (argument_number) {
      case 0:
        strcpy (scene_name,*argv++);
        argument_number++;
        break;
    }

  }
  
  if (!argument_number && loop_type==DEMO_DEFAULT) {
    printf ("You must give a file name\n");
    exit (1);
  }
}

void install_os (void) {
#ifdef SYS_MSDOS
  printf ("Operational system: DOS\n");
#else
  printf ("Operational system: Linux\n");
#endif
}

int main (int argc, char **argv) {
  int video_mode;

  printf ("RBD 2.0 \n");
  printf ("by Ricardo Bittencourt \n\n");

  parse_command_line (argc,argv);

  printf ("] CPU Summary \n\n");
  install_pentium ();
  install_os ();
  
  printf ("\n] Video Summary \n\n");
  install_video (AUTODETECT);
  video_mode=video_check_mode (resx,resy);
  if (loop_type==DEMO_DEFAULT) {
    printf ("Scene name: %s\n",scene_name);
    model=read_object (scene_name);
  }
  
  printf ("\nPress ENTER to start ...");
  fflush (stdout);
  getc (stdin);
  switch (loop_type) {  
    case DEMO_DEFAULT:
      set_graph_mode (video_mode,run_loop);
      break;
    case DEMO_TESTVIDEO:
      set_graph_mode (video_mode,test_video);
      break;
    case DEMO_LANDSCAPE:
      set_graph_mode (video_mode,landscape_demo);
      break;
  }

#ifdef SYS_MSDOS
  textmode (C80);
#endif               

  return 0;
}
