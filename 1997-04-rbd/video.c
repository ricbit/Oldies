#include "opsys.h"
#include "video.h"
#include "vesa.h"
#include "tcltk.h"

int RESX,RESY;
int selected_board;

void install_video (video_boards board) {
  switch (board) {
    case AUTODETECT:

#ifdef SYS_MSDOS
      install_video (VESA);
      break;
#endif
#ifdef SYS_LINUX
      install_video (TCLTK);
      break;
#endif

    case VESA:

#ifdef SYS_MSDOS
      install_vesa ();
      selected_board=VESA;
      break;
#endif

    case TCLTK:

#ifdef SYS_LINUX
      install_tcltk ();
      selected_board=TCLTK;
      break;
#endif

  }
}

int video_check_mode (int resx, int resy) {
  RESX=resx;
  RESY=resy;
  
  switch (selected_board) {
    case VESA:

#ifdef SYS_MSDOS
      return vesa_check_mode (resx,resy);
#endif

    case TCLTK:

#ifdef SYS_LINUX
      return tcltk_check_mode (resx,resy);
#endif

  }

  return -1;

}

void set_graph_mode (int mode, void (*drawimage)()) {
  switch (selected_board) {
    case VESA:

#ifdef SYS_MSDOS
      vesa_set_graph_mode (mode,drawimage);
      break;
#endif

    case TCLTK:

#ifdef SYS_LINUX
      tcltk_set_graph_mode (mode,drawimage);
      break;
#endif

  }
}

void blit (short *buffer) {
  switch (selected_board) {
    case VESA:

#ifdef SYS_MSDOS
      vesa_blit (buffer);
      break;
#endif

    case TCLTK:

#ifdef SYS_LINUX
      tcltk_blit (buffer);
      break;
#endif

  }
}
