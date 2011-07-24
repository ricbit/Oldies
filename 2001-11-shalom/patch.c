#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <stdlib.h>
#include <io.h>

int custom (char *s) {
  int i,count=0;

  for (i=0; i<strlen (s); i++)
    if (s[i]!='~' && s[i]!=39 && s[i]!='^')
      count++;
  return count;
}

int main (int argc, char **argv) {
  FILE *f,*hist;
  char *buf,str[200];
  int addrs,i,space,line,block,blockbase,table[256];
  int bufmax;
  int current_room,addrsave,roomaddr[0x237],roomblock[0x237],used[0x237];

  buf=(char *) malloc (768*1024);
  for (i=0; i<768*1024; i++)
    buf[i]=0;

  for (i=0; i<0x237; i++)
    roomaddr[i]=roomblock[i]=0;

  f=fopen ("shalom.rom","rb");
  fread (buf,256,1024,f);
  fclose (f);

  f=fopen (argv[1],"rt");
  hist=fopen ("hist.bin","wb");
  while (fscanf (f,"%s",str)!=EOF) {
    /*printf ("token %s\n",str);*/
    if (!strcmp (str,"/*")) {
      do {
        fscanf (f,"%s",str);
        /* printf (" ig %s\n",str);*/
      } while (strcmp (str,"*/"));
      fscanf (f,"%s",str);
    }
    addrs=strtol (str,NULL,16);
    printf ("%x:\n",addrs);
    space=0;
    line=0;
    do {
      fscanf (f,"%s",str);
    if (!strcmp (str,"/*")) {
      do {
        fscanf (f,"%s",str);
        /* printf (" ig %s\n",str);*/
      } while (strcmp (str,"*/"));
      fscanf (f,"%s",str);
    }
      if (!strcmp (str,"@ENTER")) {
        buf[addrs++]=0xfe;
        fputc (0xfe,hist);
        space=0;
        line=0;
        printf ("\n");
      } else if (!strcmp (str,"@YOU")) {
        if (line+custom (str)+space>18) {
          buf[addrs++]=0xfe;
          fputc (0xfe,hist);
          space=0;
          line=0;
          printf ("\n");
        }
        if (space) {
          space=0;
          buf[addrs++]=0;
          fputc (0,hist);
          line++;
          printf (" ");
        }
        buf[addrs++]=0xf7;
        buf[addrs++]=0xfc;
        fputc (0xf7,hist);
        fputc (0xfc,hist);
        line+=4;
        space=1;
        printf ("----");
      } else if (!strcmp (str,"@GIRL")) {
        if (line+custom (str)+space>18) {
          buf[addrs++]=0xfe;
          fputc (0xfe,hist);
          space=0;
          line=0;
          printf ("\n");
        }
        if (space) {
          space=0;
          buf[addrs++]=0;
          fputc (0,hist);
          line++;
          printf (" ");
        }
        buf[addrs++]=0xf7;
        buf[addrs++]=0xf9;
        fputc (0xf7,hist);
        fputc (0xf9,hist);
        line+=4;
        space=1;
        printf ("----");
      } else if (!strcmp (str,"@END")) {
        buf[addrs++]=0xff;
        fputc (0xff,hist);
        space=0;
        printf ("\n");
      } else if (!strcmp (str,"@MEND")) {
        buf[addrs++]=0xff;
        fputc (0xff,hist);
        space=0; line=0;
        printf ("\n");
      } else if (!strcmp (str,"@REND")) {
        buf[addrs++]=0xff;
        fputc (0xff,hist);
        space=0; line=0;
        printf ("\n");
      } else if (!strcmp (str,"@SHIFT")) {
        int i,j,max;
        fscanf (f,"%d",&max);
        for (j=0; j<max; j++) {
          for (i=0; i<7; i++)
            buf[addrs+i]=buf[addrs+i+1];
          buf[addrs+7]=0;
          addrs+=8;
        }
      } else if (!strcmp (str,"@MWAITEND")) {
        char str[200],event;

        buf[addrs++]=0xfA;
        fputc (0xfa,hist);
        fscanf (f,"%s",str);
        event=strtol (str,NULL,16);
        buf[addrs++]=event;
        fputc (event,hist);
        buf[addrs++]=0xff;
        fputc (0xff,hist);
        space=0; line=0;
        printf ("\n");
      } else if (!strcmp (str,"@RWAITEND")) {
        char str[200],event;

        buf[addrs++]=0xfA;
        fputc (0xfa,hist);
        fscanf (f,"%s",str);
        event=strtol (str,NULL,16);
        buf[addrs++]=event;
        fputc (event,hist);
        buf[addrs++]=0xff;
        fputc (0xff,hist);
        space=0; line=0;
        printf ("\n");
      } else if (!strcmp (str,"@WAITEND")) {
        buf[addrs++]=0xfA;
        fputc (0xfa,hist);
        space=0;
        printf ("\n");
      } else if (!strcmp (str,"@CLEAR")) {
        line=0;
      } else if (!strcmp (str,"@NOSPACE")) {
        space=0;
      } else if (!strcmp (str,"@ROOMMODE")) {
        addrsave=addrs;
        for (i=0; i<0x237; i++)
          used[i]=0;
      } else if (!strcmp (str,"@INCLUDE")) {
        char str[200];
        int i;
        FILE *bin;

        fscanf (f,"%s",str);
        bin=fopen (str,"rb");
        for (i=0; i<filelength (fileno (bin)); i++) 
          buf[addrs++]=fgetc (bin);
        fclose (bin);
      } else if (!strcmp (str,"@@YOU")) {
        buf[addrs++]=0xfC;
        fputc (0xfc,hist);
        space=0;
        line=0;
        printf ("\n");
      } else if (!strcmp (str,"@@BUTAKO")) {
        buf[addrs++]=0xfb;
        fputc (0xfb,hist);
        space=0;
        line=0;
        printf ("\n");
      } else if (!strcmp (str,"@@SOMEONE")) {
        buf[addrs++]=0xf8;
        fputc (0xf8,hist);
        space=0;
        line=0;
        printf ("\n");
      } else if (str[0]=='&') {
        int i;
        buf[addrs++]=0xf8;
        fputc (0xf8,hist);
        space=0;
        line=0;
        printf ("\n");
        if (strlen (str+1)>4) 
          for (i=0; i<strlen (str+1)-4; i++) {
            buf[addrs++]=str[5+i]-0x20;
            fputc (str[5+i]-0x20,hist);
            line++;
            printf ("%c",str[5+i]);
          }
      } else if (!strcmp (str,"@BLOCKSTART")) {
        char str[200];
        int i;
        space=0;
        printf ("\n");
        fscanf (f,"%s",str);
        for (i=0; i<256; i++)
          table[i]=0;
        blockbase=strtol (str,NULL,16);
        bufmax=0;
      } else if (!strcmp (str,"@ROOMSTART")) {
        char str[200];
        int i;
        space=0;
        printf ("\n");
        fscanf (f,"%s",str);
        for (i=0; i<256; i++)
          table[i]=-1;
        current_room=strtol (str,NULL,16);
        used[current_room]=1;
        bufmax=0;
        addrs=0x80000;
      } else if (!strcmp (str,"@MESG")) {
        char str[200];
        space=0;
        printf ("\n");
        fscanf (f,"%s",str);
        block=strtol (str,NULL,16);
        table[block]=(addrs&0x1FFF)+0x8000;
        printf ("%05X:\n",addrs);
        if (block>bufmax)
          bufmax=block;
      } else if (!strcmp (str,"@RMESG")) {
        char str[200];
        space=0;
        printf ("\n");
        fscanf (f,"%s",str);
        block=strtol (str,NULL,16);
        table[block]=addrs-0x80000;
        printf ("%05X:\n",table[block]);
        if (block>bufmax)
          bufmax=block;
      } else if (!strcmp (str,"@@GIRL")) {
        buf[addrs++]=0xf9;
        fputc (0xf9,hist);
        space=0;
        line=0;
        printf ("\n");
      } else if (!strcmp (str,"@OPEN")) {
        buf[addrs++]=0x3B;
        fputc (0x3b,hist);
        space=0;
        line++;
        printf ("[");
      } else if (!strcmp (str,"@KOPEN")) {
        buf[addrs++]=0xF1;
        fputc (0xF1,hist);
        space=0;
        line++;
        printf ("[");
      } else if (!strcmp (str,"@CLOSE")) {
        buf[addrs++]=0x3C;
        fputc (0x3c,hist);
        line++;
        space=0;
        printf ("]");
      } else if (!strcmp (str,"@KCLOSE")) {
        buf[addrs++]=0xF2;
        fputc (0xf2,hist);
        line++;
        space=0;
        printf ("]");
      } else if (!strcmp (str,"@WAIT")) {
        buf[addrs++]=0xFD;
        fputc (0xfd,hist);
        line=0;
        space=0;
        printf ("\n");
      } else if (!strcmp (str,"@RETURN")) {
        buf[addrs++]=0xF6;
        fputc (0xf6,hist);
        line=-4;
        space=0;
        printf ("\n");
      } else if (!strcmp (str,"@STOP")) {
        space=0;
        printf ("\n");
      } else if (!strcmp (str,"@ROOMMODEEND")) {
        printf ("\n");
      } else if (!strcmp (str,"@BLOCKEND")) {
        int i;
        space=0;
        printf ("\n");
        for (i=0; i<=bufmax; i++) {
          buf[blockbase+i*2]=table[i]%256;
          buf[blockbase+i*2+1]=table[i]/256;
        }
          
      } else if (!strcmp (str,"@ROOMEND")) {
        int i,len;
        space=0;
        printf ("\n");
        len=addrs-0x80000;
        if (((addrsave+bufmax*2+2+len)&(~0X1FFF))!=(addrsave&(~0x1FFF)))
          addrsave=(addrsave+0x1FFF)&(~0X1FFF);
        for (i=0; i<0x237; i++)
          if (used[i]) {
            roomaddr[i]=(addrsave&0x1FFF)+0x8000;
            roomblock[i]=addrsave>>13;
          }
        printf ("real %05X; addr %04X; block %02X\n",
                addrsave,roomaddr[current_room],roomblock[current_room]);
        for (i=0; i<=bufmax; i++) 
          if (table[i]==-1) 
            buf[addrsave+i*2]=buf[addrsave+i*2+1]=0;
          else {
            buf[addrsave+i*2]=
              (2+roomaddr[current_room]+table[i]+bufmax*2)%256;
            buf[addrsave+i*2+1]=
              (2+roomaddr[current_room]+table[i]+bufmax*2)/256;
          }
        memcpy (buf+addrsave+2+bufmax*2,buf+0x80000,len);
        addrsave+=bufmax*2+len+2;
        for (i=0; i<0x237; i++)
          used[i]=0;
      } else if (str[0]=='#') {
        if (str[1]=='X')
          { printf ("%s\n",str); fflush (stdout); buf[addrs++]=strtol (str+2,NULL,16);}
        else
          buf[addrs++]=atoi (str+1);
        space=0;
      } else {
        if (line+custom (str)+space>18) {
          buf[addrs++]=0xfe;
          fputc (0xfe,hist);
          space=0;
          line=0;
          printf ("\n");
        }
        if (space) {
          space=0;
          buf[addrs++]=0;
          fputc (0,hist);
          line++;
          printf (" ");
        }
        for (i=0; i<strlen (str); i++) {
          if (str[i]==':')
            { buf[addrs+i]=0x1c; fputc (0x1c,hist); printf (":");}
          else if (str[i]==',')
            { buf[addrs+i]=0x07; fputc (0x7,hist); printf (",");}
          else if (str[i]=='~') 
            { buf[addrs+i]=0x03; fputc (0x3,hist); }
          else if (str[i]=='`')
            { buf[addrs+i]=0x05; fputc (0x5,hist); }
          else if (str[i]=='^')
            { buf[addrs+i]=0x06; fputc (0x6,hist); }
          else if (str[i]=='-')
            { buf[addrs+i]=0x20; fputc (0x20,hist); printf ("-");}
          else if (str[i]=='?')
            { buf[addrs+i]=0x02; fputc (0x2,hist); printf ("?");}
          else if (str[i]=='$')
            { buf[addrs+i]=0x09; fputc (0xa,hist); printf ("'");}
          else if (str[i]==';')
            { buf[addrs+i]=0x0A; fputc (0xa,hist); printf (";");}
          else if (str[i]=='+')
            { buf[addrs+i]=0xF3; fputc (0xf3,hist); printf ("c");}
          else if (str[i]=='|')
            { buf[addrs+i]=0x72; fputc (0x72,hist); printf ("2");}
          else if (str[i]=='=')
            { buf[addrs+i]=0xF4; fputc (0xf4,hist); printf ("C");}
          else if (str[i]==39)
            {
              buf[addrs+i]=0x04;
              fputc (0x4,hist);
              if (buf[addrs+i-1]==0x49) {
                buf[addrs+i-1]=0x40;
                fputc (0x40,hist);
              }
            }
          else if (str[i]=='.')
            { buf[addrs+i]=0x08; fputc (0x8,hist); printf (".");}
          else  
            {
              buf[addrs+i]=str[i]-0x20;
              fputc (str[i]-0x20,hist); 
              printf ("%c",str[i]);
            }
        }
        addrs+=i;
        line+=custom (str);
        if (line>=18) {
          space=0; line=0;
          printf ("\n");
        } else space=1;
      }
    } while (strcmp ("@END",str) && strcmp ("@STOP",str) && strcmp ("@WAITEND",str) && strcmp ("@ROOMMODEEND",str) && strcmp ("@BLOCKEND",str));
  }
  fclose (f);
  fclose (hist);

  f=fopen (argv[2],"wb");
  fwrite (buf,512,1024,f);
  fclose (f);

  f=fopen ("addr.inc","wt");
  fprintf (f,"MESG_ADDR:\n");
  for (i=0; i<0x237; i++)
    fprintf (f,"\tDW %05Xh\t; %04X\n",roomaddr[i],i);
  fprintf (f,"MESG_BANK:\n");
  for (i=0; i<0x237; i++)
    fprintf (f,"\tDB %03Xh\t\t; %04X\n",roomblock[i],i);
  fclose (f);

  return 0;
}
