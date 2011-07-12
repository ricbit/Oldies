#include <conio.h>
#include <general.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>
#include <ctype.h>

int x=1,y=1;
char name[80],screen[80*24*2],chosen=65,buffer[2];

void realput (char c) {
  int x,y;

  gettext (1,25,1,25,buffer);
  buffer[0]=c;
  x=wherex ();
  y=wherey ();
  puttext (x,y,x,y,buffer);
  gotoxy (x+1,y);
}

int nibble (char c) {
  if (c>='0' && c<='9')
    return (c-48);
  else
    return (toupper (c)-65+10);
}

void sampleline (void) {
  gotoxy (1,25);
  cprintf ("Sample text ");
  realput (chosen);
  textcolor (LIGHTGRAY);
  textbackground (BLACK);
  gotoxy (20,25);
  cprintf ("%2d %2d                                   ",x,y);
}

void myscanf (void) {
  int i,end=0;
  char c;

  for (i=0; i<80; i++)
    name[i]=0;
  i=0;
  do {
    c=getch ();
    if (c==13) {
      end=1;
    }
    else {
      putch (c);
      name[i++]=c;
    }
  } while (!end);
}

void main (void) {
  int editing=1,file;
  int fore=LIGHTGRAY,back=BLACK,ix,iy;
  char c,color;

  textcolor (fore);
  textbackground (back);
  clrscr ();
  sampleline ();
  do {
    textcolor (fore);
    textbackground (back);
    sampleline ();
    gotoxy (x,y);
    c=getch ();
    switch (c) {
      case 0:
        switch (getch ()) {
          case 75: x--; break;
          case 77: x++; break;
          case 72: y--; break;
          case 80: y++; break;
          case 58+1:
            gettext (1,1,80,24,screen);
            gotoxy (1,1);
            textcolor (LIGHTGRAY);
            textbackground (BLACK);
            cprintf ("  0 1 2 3 4 5 6 7 8 9 A B C D E F\n\r");
            for (iy=0; iy<16; iy++) {
              cprintf ("%X ",iy);
              for (ix=0; ix<16; ix++) {
                realput (ix+iy*16);
                realput (32);
              }
              cprintf ("\n\r");
            }
            if (getch ()==0) getch ();
            puttext (1,1,80,24,screen);
            break;
          case 58+2:
            gotoxy (30,25);
            cprintf ("Save: ");
            myscanf ();
            gettext (1,1,80,24,screen);
            file=open (name,O_BINARY|O_WRONLY|O_CREAT,
                       S_IREAD|S_IWRITE|S_IFREG|S_IFMT);
            if (file!=-1) {
              write (file,screen,80*24*2);
              close (file);
            }
            break;
          case 58+3:
            gotoxy (30,25);
            cprintf ("Load: ");
            myscanf ();
            file=open (name,O_BINARY|O_RDONLY,
                       S_IREAD|S_IWRITE|S_IFREG|S_IFMT);
            if (file!=-1) {
              read (file,screen,80*24*2);
              close (file);
              puttext (1,1,80,24,screen);
            }
            break;
          case 58+4:
            gotoxy (30,25);
            cprintf ("Hex: ");
            chosen=nibble (getche ());
            chosen=chosen*16+nibble (getche ());
            break;
          case 58+5:
            fore--;
            break;
          case 58+6:
            fore++;
            break;
          case 58+7:
            back--;
            break;
          case 58+8:
            back++;
            break;
          case 58+9:
            textcolor (fore);
            textbackground (back);
            realput (chosen);
            x++;
            break;
          case 92:
            gettext (wherex(),wherey(),wherex(),wherey(),buffer);
            chosen=buffer[0];
            break;
          case 58+10:
            gettext (1,25,1,25,buffer);
            color=buffer[1];
            gettext (wherex(),wherey(),wherex(),wherey(),buffer);
            buffer[1]=color;
            puttext (wherex(),wherey(),wherex(),wherey(),buffer);
            x++;
            break;
          case 93:
            gettext (wherex(),wherey(),wherex(),wherey(),buffer);
            fore=buffer[1]%16;
            back=(buffer[1]&0x70)>>4;
            break;
        }
        if (fore<0) fore=0;
        if (fore>15) fore=15;
        if (back<0) back=0;
        if (back>7) back=7;
        break;
      case 9:
        x--;
        break;
      case 27:
        editing=0;
        break;
      default:
        textcolor (fore);
        textbackground (back);
        putch (c);
        x++;
        break;
    }
    if (x<1) x=80;
    if (x>80) x=1;
    if (y<1) y=24;
    if (y>24) y=1;
  } while (editing);
}