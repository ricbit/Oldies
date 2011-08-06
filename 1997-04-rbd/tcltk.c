#include "opsys.h"

#ifdef SYS_LINUX

#include <stdio.h>
#include <malloc.h>
#include <tcl/tcl.h>
#include <tcl/tk.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include "video.h"

Tcl_Interp *interp;
Tk_Window window;
Tk_Window canvas;
XImage *ximage=NULL;
char *image_data;
void (*gen_image)();

void install_tcltk (void) {

  printf ("Video interface: TCL/TK\n");

  interp=Tcl_CreateInterp ();

  if (Tcl_Init (interp)==TCL_ERROR) {
    printf ("Error in tcl interpreter init\n");
    exit (1);
  }

  if (Tcl_EvalFile (interp,"/usr/lib/tcl/init.tcl")==TCL_ERROR) {
    printf ("init.tcl script error <%s>\n",interp->result);
    exit (1);
  }

  window=Tk_CreateMainWindow (interp,NULL,"rbd","rbd");

  if (Tcl_EvalFile (interp,"/usr/lib/tk/tk.tcl")==TCL_ERROR) {
    printf ("tk.tcl script error <%s>\n",interp->result);
    exit (1);
  }

}

int tcltk_check_mode (int resx, int resy) {
  FILE *script;

  printf ("Mode: %dx%d\n",resx,resy);
 
  script=fopen ("rbd.tcl","w");
  fprintf (script,"wm geometry . %dx%d\n",resx+20,resy+60);
  fprintf (script,". configure -background White\n\n");

  fprintf (script,"canvas .c\n");
  fprintf (script,".c configure -background Black\n");
  fprintf (script,".c configure -height %d\n",resy);
  fprintf (script,".c configure -width %d\n",resx);
  fprintf (script,"pack .c\n");
  fprintf (script,"place .c -x 10 -y 10\n\n");

  fprintf (script,"button .b1 -background White -foreground Black\n");
  fprintf (script,".b1 configure -text \"Draw\"\n");
  fprintf (script,"pack .b1\n");
  fprintf (script,"place .b1 -x %d -y %d\n",resx/2-10,resy+20);
  fprintf (script,"bind .b1 <ButtonPress> {drawimage}\n\n");

  fprintf (script,"button .b2 -background White -foreground Black\n");
  fprintf (script,".b2 configure -text \"Close\"\n");
  fprintf (script,".b2 configure -command \"destroy .\"\n");
  fprintf (script,"pack .b2\n");
  fprintf (script,"place .b2 -x %d -y %d\n",10,resy+20);

  fclose (script);
  return 1;
}

void expose_handler (ClientData cd, XEvent *ev) {
  Display *display;
  Window window;
  Visual *visual;
  GC gc;
  int screen;
  int depth;
  Tk_Window tkwin;

  tkwin=(Tk_Window) cd;
  display=Tk_Display (tkwin);
  window=Tk_WindowId (tkwin);
  gc=Tk_GetGC (tkwin,0,NULL);
  visual=Tk_Visual (tkwin);
  if (ximage==NULL) {
    screen=DefaultScreen (display);
    depth=DisplayPlanes (display,screen);
    image_data=(char *) malloc (RESX*RESY);
    ximage=XCreateImage 
      (display,visual,depth,ZPixmap,0,image_data,RESX,RESY,8,0);
    gen_image ();
  }
}

int draw_image (ClientData cd, Tcl_Interp *interp, int argc, char **argv) {
  Tk_Window tkwin;
  Display *display;
  Window window;
  GC gc;
  Tk_Window interpWin;

  interpWin=(Tk_Window) cd;
  tkwin=Tk_NameToWindow (interp,".c",interpWin);
  display=Tk_Display (tkwin);
  window=Tk_WindowId (tkwin);
  gc=Tk_GetGC (tkwin,0,NULL);
  if (ximage!=NULL) {
    XPutImage (display,window,gc,ximage,0,0,0,0,RESX,RESY);
  }
  return 0;
}

void tcltk_set_graph_mode (int mode, void (*drawimage)()) {
  if (Tcl_EvalFile (interp,"rbd.tcl")==TCL_ERROR) {
    printf ("rbd.tcl script error <%s>\n",interp->result);
    exit (1);
  }

  canvas=Tk_NameToWindow (interp,".c",window);
  if (canvas==NULL) {
    printf ("Error: <%s>\n",interp->result);
  }

  gen_image=drawimage;
  
  Tcl_CreateCommand 
    (interp,"drawimage",draw_image,(ClientData)window,NULL);
  Tk_CreateEventHandler 
    (canvas,ExposureMask,(Tk_EventProc *)expose_handler,(ClientData)canvas);
  Tk_MainLoop ();
}

void tcltk_blit (short *buffer) {
  int i,j;

  for (j=0; j<RESY; j++)
    for (i=0; i<RESX; i++) {
      XPutPixel (ximage,i,j,(*buffer++)%16);
    }
}

#endif
