// PSG player 1.0
// by Ricardo Bittencourt

#include <stdio.h>
#include <dos.h>
#include <conio.h>
#include <io.h>
#include <fcntl.h>
#include <math.h>
#include <string.h>
#include <dir.h>

#include <general.h>
#include <error.h>
#include <xms.h>
#include <linmem.h>
#include <timer.h>
#include <sb.h>

Array music;
byte  psg[16],
      *msxTable1,*msxTable2,
      ChanActive[4],
      DecayOn[4],
      VolumeBar[16][32],
      Volume[4];
word  Period[4],
      Counter,
      StartMeasure;
dword TotalSize,
      ActualBlock,
      ActualOffset,
      ActualPos,
      ActualInt,
      TotalInts,
      SpeedMeasure,
      Resources,
      IntsPerStep,
      IntsAccum,
      ActualStep,
      TimerTicks,
      TimerSeconds,
      TimerMinutes;
byte  *MainScreen,
      *SlideScreen,
      *VideoMem;
char  FileName[256];

void ReadFile (char *name) {
  int file;
  dword size,blocks,i,blocksize,j,k;

  printf ("Reading <%s>\n",name);
  file=open (name,O_BINARY | O_RDONLY);
  if (file==-1)
    ReportError (ERROR_FATAL,"Cannot open file");
  strcpy (FileName,name);
  size=filelength (file);
  TotalSize=size;
  blocks=(size+8191)>>13;
  music.Alloc (blocks,8192);
  j=k=0;
  TotalInts=0;
  for (i=0; i<blocks; i++) {
    if (size>8192)
      blocksize=8192;
    else
      blocksize=size;
    read (file,music[i],blocksize);
    do {
      if (music[i][j]!=0xFF && music[i][j]>15)
        ReportError (ERROR_FATAL,"File is corrupt");
      if (music[i][j]==0xFF) {
        j++; k++;
        TotalInts++;
      } else {
        j+=6; k+=6;
      }
    } while (j<8192 && k<TotalSize);
    j%=8192;
    size-=8192;
  }
  IntsPerStep=TotalInts/78;
  close (file);
  printf ("Press ENTER to start.\n");
}

void InitPSG (void) {
  int i;

  for (i=0; i<16; i++)
    psg[i]=0;
  for (i=0; i<4; i++)
    ChanActive[i]=Period[i]=Volume[i]=DecayOn[i]=0;
}

void InitMusic (void) {
  int i;

  ActualPos=ActualBlock=ActualOffset=ActualInt=0;
  TimerTicks=0;
  TimerSeconds=0;
  TimerMinutes=0;
  IntsAccum=0;
  ActualStep=0;
  for (i=1; i<=78; i++)
    VideoMem[6*160+i*2+1]=BLUE*16+CYAN;
}

void InitScreen (void) {
  int i;
  byte buffer[200];
  char drive[MAXDRIVE],dir[MAXDIR],file[MAXFILE],ext[MAXEXT];

  for (i=0; i<16; i++) {
    memcpy (VolumeBar[i],(SlideScreen+i*160),32);
  }
  puttext (1,1,80,24,MainScreen);
  textcolor (LIGHTGRAY);
  textbackground (BLACK);
  gotoxy (62,4);
  cprintf ("%8ld",TotalSize);
  gotoxy (71,5);
  cprintf ("%2ld:%02ld",TotalInts/3600,(TotalInts/60)%60);
  fnsplit (FileName,drive,dir,file,ext);
  gotoxy (64,3);
  strupr (file);
  strupr (ext);
  cprintf ("%8s%s",file,ext);
  gotoxy (55,1);
  textcolor (CYAN);
  textbackground (BLUE);
  cprintf ("%8s%s",file,ext);
  gotoxy (75,1);
  cprintf ("%2ld:%02ld",TotalInts/3600,(TotalInts/60)%60);
  VideoMem=(byte *) MK_FP (0xB800,0);
}

void InitMSXTable () {
  long int period,freqint,oitava,defreq;
  double freq,ln2,freqln,freqfrac;

  msxTable1=new byte[0x1000];
  msxTable2=new byte[0x1000];
  ln2=log (2.0);
  for (period=1; period<0x1000; period++) {
    freq=111861.0/(double)period;
    freqln=log (freq)/ln2;
    freqint=floor (freqln);
    oitava=freqint-4;
    freqfrac=(freqln-freqint+8.0)*ln2;
    freq=1.31*exp ((double)freqfrac);
    defreq=(int)freq;
    msxTable1[period]=defreq%256;
    msxTable2[period]=(((defreq/256)&0x3)+(oitava<<2))&0x1f;
  }
  msxTable1[0]=msxTable1[1];
  msxTable2[0]=msxTable2[1];
}

void Decode (...) {
  byte command,argument,newvolume,i;
  word period;
  struct text_info ti;

  gettextinfo (&ti);
  do {
    command=music[ActualBlock][ActualOffset];
    if (command!=0xFF) {
      if (command>15) {
        gotoxy (1,21);
        cprintf ("Bug: %d  ",command);
      }
      else {
        if (ActualOffset==8191)
          argument=music[ActualBlock+1][0];
        else
          argument=music[ActualBlock][ActualOffset+1];
        psg[command]=argument;
        gotoxy (13,9+command);
        textcolor (BROWN);
        textbackground (BLACK);
        cprintf ("%02X",argument);
        switch (command) {
          case 0: // Frequency of channel 1
          case 1:
            Period[0]=((psg[1]&0xf)<<8)+psg[0];
            if (Period[0]==0) {
              SetRegister (0xb0,0);
            }
            else {
              SetRegister (0xa0,msxTable1[Period[0]]);
              SetRegister (0xb0,msxTable2[Period[0]]+ChanActive[0]);
            }
            break;
          case 2: // Frequency of channel 1
          case 3:
            Period[1]=((psg[3]&0xf)<<8)+psg[2];
            if (Period[1]==0) {
              SetRegister (0xb1,0);
            }
            else {
              SetRegister (0xa1,msxTable1[Period[1]]);
              SetRegister (0xb1,msxTable2[Period[1]]+ChanActive[1]);
            }
            break;
          case 4: // Frequency of channel 2
          case 5:
            Period[2]=((psg[5]&0xf)<<8)+psg[4];
            if (Period[2]==0) {
              SetRegister (0xb2,0);
            }
            else {
              SetRegister (0xa2,msxTable1[Period[2]]);
              SetRegister (0xb2,msxTable2[Period[2]]+ChanActive[2]);
            }
            break;
          case 6: // Frequency of noise (!)
            Period[3]=(psg[6]&0x1f)<<7;
            SetRegister (0xa3,msxTable1[Period[3]]);
            SetRegister (0xb3,msxTable2[Period[3]]+ChanActive[3]);
            break;
          case 7:
            // Select channel 0
            if ((psg[7]&0x01)!=0) {
              if (ChanActive[0]==0x20) {
                VideoMem[2*160+29*2+1]=GREEN;
                ChanActive[0]=0;
                SetRegister (0xb0,msxTable2[Period[0]]+ChanActive[0]);
              }
            }
            else {
              if (ChanActive[0]==0) {
                VideoMem[2*160+29*2+1]=LIGHTRED;
                ChanActive[0]=0x20;
                SetRegister (0xb0,msxTable2[Period[0]]+ChanActive[0]);
              }
            }
            // Select channel 1
            if ((psg[7]&0x02)!=0) {
              if (ChanActive[1]==0x20) {
                VideoMem[3*160+29*2+1]=GREEN;
                ChanActive[1]=0;
                SetRegister (0xb1,msxTable2[Period[1]]+ChanActive[1]);
              }
            }
            else {
              if (ChanActive[1]==0) {
                VideoMem[3*160+29*2+1]=LIGHTRED;
                ChanActive[1]=0x20;
                SetRegister (0xb1,msxTable2[Period[1]]+ChanActive[1]);
              }
            }
            // Select channel 2
            if ((psg[7]&0x04)!=0) {
              if (ChanActive[2]==0x20) {
                VideoMem[4*160+29*2+1]=GREEN;
                ChanActive[2]=0;
                SetRegister (0xb2,msxTable2[Period[2]]+ChanActive[2]);
              }
            }
            else {
              if (ChanActive[2]==0) {
                VideoMem[4*160+29*2+1]=LIGHTRED;
                ChanActive[2]=0x20;
                SetRegister (0xb2,msxTable2[Period[2]]+ChanActive[2]);
              }
            }
            // Select noise channel
            if ((psg[7]&0x08)!=0) {
              VideoMem[2*160+30*2+1]=GREEN;
            }
            else {
              VideoMem[2*160+30*2+1]=LIGHTRED;
            }
            if ((psg[7]&0x10)!=0) {
              VideoMem[3*160+30*2+1]=GREEN;
            }
            else {
              VideoMem[3*160+30*2+1]=LIGHTRED;
            }
            if ((psg[7]&0x20)!=0) {
              VideoMem[4*160+30*2+1]=GREEN;
            }
            else {
              VideoMem[4*160+30*2+1]=LIGHTRED;
            }
            break;
          case 8: // Control volume of channel 0
            newvolume=(32-(psg[8]&0xf));
            if (newvolume==32) {
              newvolume=63;
              DecayOn[0]=1;
              SetRegister (0xb0,msxTable2[Period[0]]);
              SetRegister (0x43,newvolume);
            }
            else {
              SetRegister (0x43,newvolume);
              if (DecayOn[0]) {
                SetRegister (0xb0,msxTable2[Period[0]]+0x20);
                DecayOn[0]=0;
              }
            }
            if ((psg[8]&0x10)==0) {
              VideoMem[2*160+31*2+1]=GREEN;
            }
            else {
              VideoMem[2*160+31*2+1]=LIGHTRED;
            }
            puttext (14,3,14+14,3,VolumeBar[psg[8]&0x0f]);
            break;
          case 9: // Control volume of channel 1
            newvolume=(32-(psg[9]&0x0f));
            if (newvolume==32) {
              newvolume=63;
              DecayOn[1]=1;
              SetRegister (0xb1,msxTable2[Period[1]]);
              SetRegister (0x44,newvolume);
            }
            else {
              SetRegister (0x44,newvolume);
              if (DecayOn[1]) {
                SetRegister (0xb1,msxTable2[Period[1]]+0x20);
                DecayOn[1]=0;
              }
            }
            if ((psg[9]&0x10)==0) {
              VideoMem[3*160+31*2+1]=GREEN;
            }
            else {
              VideoMem[3*160+31*2+1]=LIGHTRED;
            }
            puttext (14,4,14+14,4,VolumeBar[psg[9]&0x0f]);
            break;
          case 10: // Control volume of channel 2
            newvolume=(32-(psg[10]&0x0f));
            if (newvolume==32) {
              newvolume=63;
              DecayOn[2]=1;
              SetRegister (0xb2,msxTable2[Period[2]]);
              SetRegister (0x45,newvolume);
            }
            else {
              SetRegister (0x45,newvolume);
              if (DecayOn[2]) {
                SetRegister (0xb2,msxTable2[Period[2]]+0x20);
                DecayOn[2]=0;
              }
            }
            if ((psg[10]&0x10)==0) {
              VideoMem[4*160+31*2+1]=GREEN;
            }
            else {
              VideoMem[4*160+31*2+1]=LIGHTRED;
            }
            puttext (14,5,14+14,5,VolumeBar[psg[10]&0x0f]);
            break;
        }
      }
      ActualOffset+=5;
      ActualPos+=5;
    }
    ActualPos++;
    ActualOffset++;
    if (ActualOffset>=8192) {
      ActualBlock++;
      ActualOffset%=8192;
    }
  } while (ActualPos<TotalSize && music[ActualBlock][ActualOffset]!=0xFF);
  ActualInt++;
  TimerTicks++;
  IntsAccum++;
  if (IntsAccum>=IntsPerStep) {
    IntsAccum=0;
    ActualStep++;
    VideoMem[6*160+ActualStep*2+1]=BLUE*16+YELLOW;
  }
  if (TimerTicks==60) {
    gotoxy (69,1);
    textcolor (CYAN);
    textbackground (BLUE);
    TimerTicks=0;
    TimerSeconds++;
    if (TimerSeconds==60) {
      TimerSeconds=0;
      TimerMinutes++;
    }
    cprintf ("%2ld:%02ld",TimerMinutes,TimerSeconds);
    gotoxy (76,24);
    textcolor (LIGHTGRAY);
    textbackground (BLACK);
    cprintf ("%3ld",100*Resources/SpeedMeasure);
  }
  if (ActualPos>=TotalSize) InitMusic ();
  textcolor (ti.attribute%16);
  textbackground ((ti.attribute&0x70)>>4);
  Resources=0;
}

void ReadScreens (void) {
  int file;

  MainScreen=new byte[3840];
  file=open ("psgp.asc",O_BINARY|O_RDONLY);
  read (file,MainScreen,3840);
  close (file);

  SlideScreen=new byte[3840];
  file=open ("slide.asc",O_BINARY|O_RDONLY);
  read (file,SlideScreen,3840);
  close (file);
}

void SelectInstrument (int voice) {
  byte voic2;

  if (voice==3)
    voic2=8;
  else
    voic2=voice;
  SetRegister (0xb0+voice,0);
  SetRegister (0x23+voic2,0x01+0x20+0x80); //vibrato
  SetRegister (0x20+voic2,0x01+0x20+0x80); //vibrato
  SetRegister (0x43+voic2,0x3f);           //volume
  SetRegister (0x40+voic2,0x3f);           //volume
  SetRegister (0x63+voic2,(15<<4)+0);      //attack,decay
  SetRegister (0x83+voic2,(7<<4)+15);       //sustain,release
  SetRegister (0xc0+voice,1);
  SetRegister (0xbd+voice,1<<6);
}

void SpeedFunction (...) {
  Counter++;
  if (StartMeasure==1) StartMeasure=0;
  if (Counter==3) StartMeasure=1;
}

void main (int argc, char **argv) {
  char c;
  int handle;

  _setcursortype (_NOCURSOR);
  printf ("PSG player 1.0\n");
  printf ("Copyright (C) 1996 by Ricardo Bittencourt\n");
  printf ("This file is under GNU GPL, ");
  printf ("see file COPYING.TXT for details\n");
  printf ("See file README.TXT for instructions\n\n");
  InstallErrorHandler ();
  InstallXMS ();
  ReadScreens ();
  if (argc<2) {
    ReportError (ERROR_FATAL,"You must give a file name");
  }
  ReadFile (argv[1]);
  getch ();
  InitPSG ();
  InitMSXTable ();
  InitScreen ();
  InitMusic ();
  InitSoundBlaster (0x388);
  SelectInstrument (0);
  SelectInstrument (1);
  SelectInstrument (2);
  SelectInstrument (3);
  gotoxy (1,20);
  InstallTimer (180);
  handle=RegisterFunction (60,SpeedFunction);
  DisableInterrupts ();
  SpeedMeasure=0;
  StartMeasure=0;
  Counter=0;
  EnableInterrupts ();
  while (!StartMeasure);
  do {
    SpeedMeasure++;
    if (kbhit ());
  } while (StartMeasure);
  RemoveFunction (handle);
  RegisterFunction (60,Decode);
  c=0;
  do {
    Resources++;
    if (kbhit ())
      c=getch ();
  } while (c!=27);
  RemoveTimer ();
  ResetSoundBlaster ();
  _setcursortype (_NORMALCURSOR);
  textcolor (LIGHTGRAY);
  textbackground (BLACK);
  clrscr ();
}
