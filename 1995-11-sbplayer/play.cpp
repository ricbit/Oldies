#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>

typedef unsigned char byte;

typedef struct {
  int octave,attack,decay,sustain,release,volume,timing,egtype;
} channel;

typedef struct {
  unsigned int number;
  byte reg;
  byte value;
} event;

channel c[9];
char *buf,sust[10],pont[10];
int maxchan,atchan,timing,atev,maxfile,atp,atm,atlev,maxev,troca;
char name[100],plyname[100],fmname[100],temp[100];
int op1[9],op2[9],cp;
double corr;
FILE *f;
char ch;
int fh,firstnote;
event *evlist,sw;

void initchannel (channel *c) {
  c->octave=4;
  c->attack=7;
  c->decay=4;
  c->sustain=7;
  c->release=7;
  c->volume=6;
  c->timing=4;
  c->egtype=0;
}

char nextchar () {
  int i;
  while (atp<maxfile && (buf[atp]==32 || buf[atp]==13 || buf[atp]==10)) atp++;
  return buf[atp];
}

int checktiming () {
  char numb[10];
  int i;

  if (nextchar()>='0' && nextchar()<='9') {
    i=0;
    do {
      numb[i++]=buf[atp++];
    } while (atp<maxfile && buf[atp]>='0' && buf[atp]<='9');
    numb[i]=0;
    return atoi(numb);
  }
  else
    return (c[atchan].timing);
}

void checksust () {
  if (nextchar()=='#' || nextchar()=='+') {
    strcpy (sust,"#");
    corr=1.05946309436;
    atp++;
  }
  if (nextchar()=='-') {
    strcpy (sust,"-");
    corr=1.0/1.05946309436;
    atp++;
  }
}

void checkdot () {
  if (nextchar ()=='.') {
    strcpy (pont,".");
    cp=1;
    atp++;
  }
}

void addevent (byte reg, byte value) {
  event e;
  e.number=atev;
  e.reg=reg;
  e.value=value;
  evlist[atlev++]=e;
  printf ("\t\t%d: ($%x,%d)\n",atev,reg,value);
}

void addnote (double freq) {
  int modifreq;

  modifreq=(int)(1.31*freq);
  addevent (0xb0+atchan,0);
  addevent (0xa0+atchan,modifreq & 0xff);
  addevent (0xb0+atchan,(modifreq>>8)+(c[atchan].octave<<2)+0x20);
}

void initchannel () {
  addevent (0xb0+atchan,0);
  addevent (0x20+op1[atchan],1+(c[atchan].egtype<<5));
  addevent (0x20+op2[atchan],1+(c[atchan].egtype<<5));
  addevent (0x40+op1[atchan],c[atchan].volume);
  addevent (0x40+op2[atchan],c[atchan].volume);
  addevent (0x60+op1[atchan],(c[atchan].attack<<4)+c[atchan].decay);
  addevent (0x60+op2[atchan],(c[atchan].attack<<4)+c[atchan].decay);
  addevent (0x80+op1[atchan],(c[atchan].sustain<<4)+c[atchan].release);
  addevent (0x80+op2[atchan],(c[atchan].sustain<<4)+c[atchan].release);
  addevent (0xc0+atchan,0);
  firstnote=0;
}

void main (void) {
  buf=(char *) malloc (50000);
  evlist=(event *) malloc (10000*sizeof (event));
  op1[0]=0x00;
  op1[1]=0x01;
  op1[2]=0x02;
  op1[3]=0x08;
  op1[4]=0x09;
  op1[5]=0x0a;
  op1[6]=0x10;
  op1[7]=0x11;
  op1[8]=0x12;
  op2[0]=0x03;
  op2[1]=0x04;
  op2[2]=0x05;
  op2[3]=0x0b;
  op2[4]=0x0c;
  op2[5]=0x0d;
  op2[6]=0x13;
  op2[7]=0x14;
  op2[8]=0x15;
  printf ("\nMusic (*.ply): ");
  scanf ("%s",name);
  strcpy (plyname,name);
  strcat (plyname,".ply");
  f=fopen (plyname,"r");
  temp[0]=ch;
  temp[1]=0;
  maxchan=atoi (temp);
  printf ("<%s>\n",plyname);
  atchan=-1;
  timing=16;
  maxfile=0;
  atlev=0;
  firstnote=0;
  while (!feof (f)) {
    fscanf (f,"%c",&buf[maxfile++]);
  }
  fclose (f);
  atp=0;
  do {
    ch=toupper (buf[atp++]);
    strcpy (sust,"");
    corr=1.0;
    strcpy (pont,"");
    cp=0;
    switch (ch) {
      case '|':
        atchan++;
        atev=0;
        initchannel (&c[atchan]);
        printf ("Channel %d:\n",atchan);
        firstnote=1;
        break;
      case 'C':
        checksust();
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:O%dC%s%d%s\n",atev,c[atchan].octave,sust,atm,pont);
        if (firstnote) initchannel ();
        addnote (261.6*corr);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'D':
        checksust();
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:O%dD%s%d%s\n",atev,c[atchan].octave,sust,atm,pont);
        if (firstnote) initchannel ();
        addnote (293.7*corr);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'E':
        checksust();
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:O%dE%s%d%s\n",atev,c[atchan].octave,sust,atm,pont);
        if (firstnote) initchannel ();
        addnote (329.6*corr);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'F':
        checksust();
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:O%dF%s%d%s\n",atev,c[atchan].octave,sust,atm,pont);
        if (firstnote) initchannel ();
        addnote (349.2*corr);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'G':
        checksust();
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:O%dG%s%d%s\n",atev,c[atchan].octave,sust,atm,pont);
        if (firstnote) initchannel ();
        addnote (392.0*corr);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'A':
        checksust();
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:O%dA%s%d%s\n",atev,c[atchan].octave,sust,atm,pont);
        if (firstnote) initchannel ();
        addnote (440.0*corr);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'B':
        checksust();
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:O%dB%s%d%s\n",atev,c[atchan].octave,sust,atm,pont);
        if (firstnote) initchannel ();
        addnote (466.2*corr);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'R':
        atm=checktiming();
        checkdot();
        printf ("\tevent %d:R%d%s\n",atev,atm,pont);
        atev+=timing/atm+cp*(timing/atm/2);
        break;
      case 'T':
        atm=checktiming();
        printf ("Timing set to %d\n",atm);
        timing=atm;
        break;
      case 'V':
        atm=checktiming();
        printf ("\tevent %d:V%d\n",atev,atm);
        c[atchan].volume=(15-atm)<<2;
        addevent (0x40+op1[atchan],c[atchan].volume);
        addevent (0x40+op2[atchan],c[atchan].volume);
        break;
      case 'L':
        atm=checktiming();
        printf ("\tChannel timing set to %d\n",atm);
        c[atchan].timing=atm;
        break;
      case 'O':
        atm=checktiming();
        printf ("\tChannel octave set to %d\n",atm);
        c[atchan].octave=atm;
        break;
      case '>':
        c[atchan].octave++;
        printf ("\tChannel octave is now %d\n",c[atchan].octave);
        break;
      case '<':
        c[atchan].octave--;
        printf ("\tChannel octave is now %d\n",c[atchan].octave);
        break;
      case '\\':
        atp=maxfile;
        printf ("End of file.\n");
        break;
      case '_':
        printf ("Instrument set to continuous mode\n");
        c[atchan].egtype=1;
        break;
    }
  } while (atp!=maxfile);
  printf ("\nSorting...\n");
  maxev=atlev;
  do {
    troca=0;
    for (atlev=0; atlev<maxev-1; atlev++) {
      if (evlist[atlev+1].number<evlist[atlev].number) {
        sw=evlist[atlev+1];
        evlist[atlev+1]=evlist[atlev];
        evlist[atlev]=sw;
        troca=1;
      }
    }
    printf (".");
  } while (troca);
  strcpy (fmname,name);
  strcat (fmname,".fm");
  printf ("Writing file <%s>\n",fmname);
  remove (fmname);
  fh=open (fmname,O_BINARY|O_CREAT|O_WRONLY,S_IWRITE);
  for (atlev=0; atlev<maxev; atlev++) {
    printf ("\t%d: ($%x,%d)\n",evlist[atlev].number,evlist[atlev].reg,evlist[atlev].value);
    write (fh,&evlist[atlev],sizeof (event));
  }
  close (fh);
  printf ("Total events: %d\n",maxev);
}