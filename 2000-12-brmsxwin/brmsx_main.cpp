//---------------------------------------------------------------------------
#include <vcl.h>
#include <string.h>
#include <mmsystem.h>
#include <stdio.h>
#pragma hdrstop
#include <ddraw.h>
#include <dinput.h>

#include "fudebug_window.h"
#include "brmsx_main.h"
#include "timer.h"
#include "brmsx_z80.h"
#include "brmsx_vdp.h"
#include "brmsx_engine.h"
#include "runvdp.h"
#include "about_window.h"
#include "scanline_window.h"
#include "keyboard_window.h"
#include "msxrom.h"
#include "diskrom.h"
#include "joystick_window.h"
#include "mount_window.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
Tmain_window *main_window;

// DirectDraw
LPDIRECTDRAW7 DX7interface=NULL;
LPDIRECTDRAWCLIPPER clipper=NULL;
LPDIRECTDRAWSURFACE7 primary_surface=NULL;
LPDIRECTDRAWSURFACE7 blitbuffer=NULL;

// DirectInput
LPDIRECTINPUT dinput_interface=NULL;
LPDIRECTINPUTDEVICE dinput_keyboard=NULL;

// generic
int timer_id;
int countdown=0;
volatile int running=0,time_enabled=0;
unsigned char *ram,*vram,*cartA=NULL,*diskA=NULL;
unsigned char keyindex[256],keybit[256];


//---------------------------------------------------------------------------

void init_keyboard (void);
void main_loop (void);

void CALLBACK timer_callback
  (UINT wTimerID, UINT msg, DWORD dwUser, DWORD dw1, DWORD dw2)
{

    main_loop();
}

//---------------------------------------------------------------------------
__fastcall Tmain_window::Tmain_window(TComponent* Owner)
        : TForm(Owner)
{
  int ret,ii,jj;
  DDSURFACEDESC2 ddsd;
  DDPIXELFORMAT ddpf;
  TIMECAPS tc;

  // request DX7 Interface
  ret=DirectDrawCreateEx(NULL,(VOID**)&DX7interface,IID_IDirectDraw7,NULL);
  if (ret!=DD_OK) {
    Application->MessageBox
      (AnsiString("Cannot open DirectDraw").c_str(),"BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // Set windowed mode
  ret = DX7interface->SetCooperativeLevel(main_window->Handle, DDSCL_NORMAL);
  if (ret!=DD_OK) {
    Application->MessageBox
      ("Cannot set windowed mode","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // get handle to primary surface
  memset (&ddsd,0,sizeof(ddsd));
  ddsd.dwSize=sizeof(ddsd);
  ddsd.dwFlags=DDSD_CAPS;
  ddsd.ddsCaps.dwCaps=DDSCAPS_PRIMARYSURFACE;
  ret=DX7interface->CreateSurface(&ddsd,&primary_surface,NULL);
  if (ret!=DD_OK) {
    Application->MessageBox
      ("Cannot get primary surface","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // check color depth of primary surface
  memset (&ddpf,0,sizeof(ddpf));
  ddpf.dwSize  = sizeof(DDPIXELFORMAT);
  primary_surface->GetPixelFormat(&ddpf);
  if (ddpf.dwRGBBitCount==16 && ddpf.dwRBitMask==0xF800 &&
      ddpf.dwGBitMask==0x7E0 && ddpf.dwBBitMask==0x1F)
  {
    bitdepth=16;
  } else if (ddpf.dwRGBBitCount==32 && ddpf.dwRBitMask==0xFF0000 &&
             ddpf.dwGBitMask==0xFF00 && ddpf.dwBBitMask==0xFF)
  {
    bitdepth=32;
  } else {
    Application->MessageBox
      ((AnsiString("Color depth not supported\nR:")+
       IntToHex((int)ddpf.dwRBitMask,8)+
       AnsiString(" G:")+IntToHex((int)ddpf.dwGBitMask,8)+
       AnsiString(" B:")+IntToHex((int)ddpf.dwBBitMask,8)).c_str(),
       "BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // request a clipper from DX7
  ret=DX7interface->CreateClipper(0,&clipper,NULL);
  if (ret!=DD_OK) {
    Application->MessageBox
      ("Cannot request a clipper","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // assign a window handle to the clipper
  ret=clipper->SetHWnd(0,main_window->Handle);
  if (ret!=DD_OK) {
    Application->MessageBox
      ("Cannot assign a window","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // assign the clipper to the primary surface
  ret=primary_surface->SetClipper(clipper);
  if (ret!=DD_OK) {
    Application->MessageBox
      ("Cannot assign a clipper","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // create an off-screen buffer for fast blitting
  memset (&ddsd,0,sizeof(ddsd));
  ddsd.dwSize  = sizeof(ddsd);
  ddsd.dwFlags = DDSD_CAPS | DDSD_HEIGHT | DDSD_WIDTH | DDSD_PIXELFORMAT;
  ddsd.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN;//|DDSCAPS_SYSTEMMEMORY;
  ddsd.dwHeight = 480;
  ddsd.dwWidth  = 592;
  ddsd.ddpfPixelFormat.dwSize  = sizeof(DDPIXELFORMAT);
  ddsd.ddpfPixelFormat.dwFlags = DDPF_RGB;
  ddsd.ddpfPixelFormat.dwRGBBitCount = ddpf.dwRGBBitCount; //32;
  ddsd.ddpfPixelFormat.dwRBitMask = ddpf.dwRBitMask; //0x00FF0000;
  ddsd.ddpfPixelFormat.dwGBitMask = ddpf.dwGBitMask; //0x0000FF00;
  ddsd.ddpfPixelFormat.dwBBitMask = ddpf.dwBBitMask; //0x000000FF;
  ret=DX7interface->CreateSurface(&ddsd,&blitbuffer,NULL);
  if (ret!=DD_OK) {
    Application->MessageBox
      ("Cannot create offscreen buffer","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // Get timer capabilities
  if (timeGetDevCaps(&tc, sizeof(TIMECAPS)) != TIMERR_NOERROR) {
    Application->MessageBox
      ("Cannot create timer","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  if (timeBeginPeriod(16) != TIMERR_NOERROR) {
    Application->MessageBox
      ("Cannot create timer","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  timer_id=timeSetEvent(16,0,timer_callback,0,TIME_PERIODIC);
  if (timer_id==NULL) {
    Application->MessageBox
      ("Cannot create timer","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // Get DirectInput
  ret=DirectInputCreateEx (
        (HINSTANCE)GetWindowLong(main_window->Handle,GWL_HINSTANCE),
        DIRECTINPUT_VERSION,IID_IDirectInput7,
        (void**)&dinput_interface, NULL);
  if (ret!=DI_OK) {
    Application->MessageBox
      ("Cannot create DirectInput interface","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // Get keyboard
  ret=dinput_interface->CreateDevice(GUID_SysKeyboard,&dinput_keyboard,NULL);
  if (ret!=DI_OK) {
    Application->MessageBox
      ("Cannot create keyboard interface","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // Set keyboard data format
  ret=dinput_keyboard->SetDataFormat(&c_dfDIKeyboard);
  if (ret!=DI_OK) {
    Application->MessageBox
      ("Cannot set keyboard data format","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // Set keyboard exclusive mode
  ret=dinput_keyboard->SetCooperativeLevel(main_window->Handle,
        DISCL_EXCLUSIVE | DISCL_FOREGROUND );
  if (ret!=DI_OK) {
    Application->MessageBox
      ("Cannot set keyboard exclusive mode","BrMSX",MB_OK);
    Application->Terminate ();
    return;
  }

  // Init the keyboard mapping
  init_keyboard ();


  FILE *f;
  ram=(unsigned char *) malloc (65536);
  vram=(unsigned char *) malloc (16384);
  memset (vram,0,16384);

  slot[0*16+0]=(unsigned int)rom+8192*0;
  slot[0*16+2]=(unsigned int)rom+8192*1;
  slot[0*16+4]=(unsigned int)rom+8192*2;
  slot[0*16+6]=(unsigned int)rom+8192*3;
  slot[3*16+4]=(unsigned int)diskrom+8192*0;
  slot[3*16+6]=(unsigned int)diskrom+8192*1;
  for (ii=0; ii<8; ii++) {
    slot[2*16+ii*2+0]=(unsigned int)ram+8192*ii;
    slot[2*16+ii*2+1]=0;
  }
  resetZ80();

  // create windows
//  Keyboard=new TKeyboard(Application);
//  if (Keyboard!=NULL) Keyboard->CreateWnd();

//  time_enabled=1;
}

//---------------------------------------------------------------------------

void blit_window (void) {
  RECT r1;
  DDBLTFX ddbltfx;
  int ret;
  HDC *mydc;

  memset (&ddbltfx,0,sizeof(ddbltfx));
  ddbltfx.dwSize=sizeof(ddbltfx);
  ddbltfx.dwDDFX=DDBLTFX_NOTEARING;

  TPoint T=main_window->Image1->ClientOrigin;
  r1.top=T.y;
  r1.left=T.x;
  r1.right=T.x+592;
  r1.bottom=T.y+480;
  ret=primary_surface->Blt(&r1,blitbuffer,NULL,DDBLT_WAIT|DDBLT_DDFX,&ddbltfx);
  if (ret==DDERR_SURFACELOST) {
    DX7interface->RestoreAllSurfaces();
  }
}

//---------------------------------------------------------------------------

void read_keyboard (void) {
  unsigned char keybuf[256];
  int ret,i;

  ret=dinput_keyboard->GetDeviceState(256,keybuf);
  if (ret!=DI_OK) {
    dinput_keyboard->Acquire();
    return;
  }
  for (i=0; i<16; i++)
    keymatrix[i]=0xFF;

  for (i=0; i<256; i++)
    if (keybuf[i]&0x80)
      keymatrix[keyindex[i]]&=~keybit[i];
}

//---------------------------------------------------------------------------

void main_loop (void) {
  static unsigned int tick_counter=0,startclock,endclock,start,end;
  static unsigned int cputime=0,z80time=0,vdptime=0,blittime=0,bordertime=0;


  if (time_enabled) {
    running=1;
    endclock=rdtsc();
    cputime+=(endclock-startclock);
    startclock=endclock;

    if (tick_counter++%60==0) {
      main_window->StatusBar1->Panels->Items[0]->Text=
        AnsiString ((cputime/1000000)*16666/16000);
      main_window->StatusBar1->Panels->Items[1]->Text=
        "Z80:"+FormatFloat ("0.00",(double)z80time/(double)cputime*100.0)+"%";
      main_window->StatusBar1->Panels->Items[2]->Text=
        "VDP:"+FormatFloat ("0.00",(double)vdptime/(double)cputime*100.0)+"%";
      main_window->StatusBar1->Panels->Items[3]->Text=
        "Blit:"+FormatFloat ("0.00",(double)blittime/(double)cputime*100.0)+"%";
      main_window->StatusBar1->Panels->Items[4]->Text=
        "Border:"+FormatFloat ("0.00",(double)bordertime/(double)cputime*100.0)+"%";
      cputime=0;
      z80time=0;
      vdptime=0;
      blittime=0;
      bordertime=0;
    }

    // Read keyboard
    read_keyboard ();

    // Run the MSX engine
    run_msx(&z80time,&vdptime,&bordertime);

    // Blit the window
    start=rdtsc();
    blit_window();
    end=rdtsc();
    blittime+=(end-start);

    running=0;
  }
}

//---------------------------------------------------------------------------



void __fastcall Tmain_window::FormPaint(TObject *Sender)
{
  blit_window();
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::Exit1Click(TObject *Sender)
{
  Close();
}
//---------------------------------------------------------------------------


void __fastcall Tmain_window::FormDestroy(TObject *Sender)
{
  time_enabled=0;
  timeEndPeriod(16);
  timeKillEvent (timer_id);
  if (clipper!=NULL)
    clipper->Release();
  if (primary_surface!=NULL)
    primary_surface->Release();
  if (blitbuffer!=NULL)
    blitbuffer->Release();
  if (DX7interface!=NULL)
    DX7interface->Release();
  if (dinput_interface!=NULL)
    dinput_interface->Release();
  if (dinput_keyboard!=NULL) {
    dinput_keyboard->Unacquire();
    dinput_keyboard->Release();
  }
}
//---------------------------------------------------------------------------


void __fastcall Tmain_window::FuDebug1Click(TObject *Sender)
{
  Fudebug->Show();
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::FormClose(TObject *Sender,
      TCloseAction &Action)
{
  time_enabled=0;
  while (running) {}
}
//---------------------------------------------------------------------------

void Tmain_window::load_cartA (void) {
  FILE *f;
  int size,i;

  dinput_keyboard->Unacquire();

  time_enabled=0;
  while (running) {}

  generic_load_dialog->Filter=
    "Cartridge (*.rom)|*.rom";
  if (generic_load_dialog->Execute()) {

  if (cartA!=NULL) {
    free (cartA);
    for (i=0; i<8; i++) {
      slot[1*16+i*2+0]=idlerom;
      slot[1*16+i*2+1]=1;
    }
  }


  f=fopen (generic_load_dialog->FileName.c_str(),"rb");
  fseek (f,0,SEEK_END);
  size=ftell (f);
  fseek (f,0,SEEK_SET);
  if (size%8192!=0) {
    Application->MessageBox
      ("Not a valid ROM file","BrMSX",MB_OK);
    time_enabled=1;
    Application->Terminate();
  }
  if (size>32768) {
    Application->MessageBox
      ("Not a valid ROM file","BrMSX",MB_OK);
    time_enabled=1;
    Application->Terminate();
  }
  cartA=(unsigned char *) malloc (size);
  fread (cartA,size,1,f);
  fclose (f);
  if (size==8192) {
    // 8192 cart
    for (i=0; i<8; i++) {
      slot[1*16+(i)*2+0]=(int)(cartA);
      slot[1*16+(i)*2+1]=1;
    }

  } else {
    if (*(unsigned char *)(cartA+3)==0) {
      if (*(unsigned short *)(cartA+8)==0) {
        // 0000 cart - mirror in all pages
        for (i=0; i<4; i++) {
          slot[1*16+(i)*4+0]=(int)(cartA);
          slot[1*16+(i)*4+1]=1;
          slot[1*16+(i)*4+2]=(int)(cartA+8192);
          slot[1*16+(i)*4+3]=1;
        }
      } else {
        // basic cartridge
        slot[1*16+(2)*4+0]=(int)(cartA);
        slot[1*16+(2)*4+1]=1;
        slot[1*16+(2)*4+2]=(int)(cartA+8192);
        slot[1*16+(2)*4+3]=1;
      }
    } else {
      // normal 16/32 cart
      unsigned char k=*(unsigned char *)(cartA+3);
      k>>=6; k*=2;
      for (i=0; i<size/8192; i++) {
        slot[1*16+(i+k)*2+0]=(int)(cartA+i*8192);
        slot[1*16+(i+k)*2+1]=1;
      }
    }
  }
  resetZ80();
  }

  time_enabled=1;
  dinput_keyboard->Acquire();

}

//---------------------------------------------------------------------------

void Tmain_window::load_diskA (void) {
  FILE *f;
  int size,i;

  dinput_keyboard->Unacquire();

  time_enabled=0;
  while (running) {}

  generic_load_dialog->Filter=
    "Disk Image (*.dsk)|*.dsk";
  if (generic_load_dialog->Execute()) {

  f=fopen (generic_load_dialog->FileName.c_str(),"rb");
  fseek (f,0,SEEK_END);
  size=ftell (f);
  fseek (f,0,SEEK_SET);
  if (size!=720*1024) {
    Application->MessageBox
      ("Not a valid DSK file","BrMSX",MB_OK);
    time_enabled=1;
    Application->Terminate();
  }

  if (diskA!=NULL)
    free (diskA);

  diskA=(unsigned char *) malloc (size);
  fread (diskA,size,1,f);
  fclose (f);
  }

  time_enabled=1;
  dinput_keyboard->Acquire();

}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::LoadCartridge1Click(TObject *Sender)
{
  load_cartA();
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::FormActivate(TObject *Sender)
{
  if (dinput_keyboard!=NULL)
    dinput_keyboard->Acquire();
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::FormDeactivate(TObject *Sender)
{
  if (dinput_keyboard!=NULL)
    dinput_keyboard->Unacquire();
}

//---------------------------------------------------------------------------

void __fastcall Tmain_window::About1Click(TObject *Sender)
{
  time_enabled=0;
  while (running) {}
  if (About==NULL)
    Application->CreateForm(__classid(TAbout), &About);
  time_enabled=1;

  About->Show();
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::Scanlines1Click(TObject *Sender)
{
  time_enabled=0;
  while (running) {}
  if (Scanline==NULL)
    Application->CreateForm(__classid(TScanline), &Scanline);
  time_enabled=1;

  Scanline->Show();
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::Keyboard1Click(TObject *Sender)
{
  time_enabled=0;
  while (running) {}
  if (Keyboard==NULL)
    Application->CreateForm(__classid(TKeyboard), &Keyboard);
  Keyboard->ShowModal ();
  time_enabled=1;
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::Joystick1Click(TObject *Sender)
{
  Joystick->Show ();

}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::SpeedButton1Click(TObject *Sender)
{
  load_cartA();

}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

void init_keyboard (void) {
  int ii;

  for (ii=0; ii<256; ii++)
    keyindex[ii]=keybit[ii]=0;

  keyindex[0x48]=keyindex[0xC8]=8; // up
  keybit[0x48]=keybit[0xC8]=0x20;

  keyindex[0x50]=keyindex[0xD0]=8; // down
  keybit[0x50]=keybit[0xD0]=0x40;

  keyindex[0x4B]=keyindex[0xCB]=8; // left
  keybit[0x4B]=keybit[0xCB]=0x10;

  keyindex[0x4D]=keyindex[0xCD]=8; // right
  keybit[0x4D]=keybit[0xCD]=0x80;

  keyindex[0x39]=8; // space
  keybit[0x39]=0x01;

  keyindex[0x0C]=1; // -
  keybit[0x0C]=0x04;

  keyindex[0x0D]=1; // =
  keybit[0x0D]=0x08;

  keyindex[0x0E]=7; // bs
  keybit[0x0E]=0x20;

  keyindex[0x0F]=7; // tab
  keybit[0x0F]=0x08;

  keyindex[0x1A]=1; // [
  keybit[0x1A]=0x20;

  keyindex[0x1B]=1; // ]
  keybit[0x1B]=0x40;

  keyindex[0x27]=1; // ;
  keybit[0x27]=0x80;

  keyindex[0x28]=2; // '
  keybit[0x28]=0x01;

  keyindex[0x29]=2; // ~
  keybit[0x29]=0x20;

  keyindex[0x2B]=1; // barra
  keybit[0x2B]=0x10;

  keyindex[0xC7]=8; // home
  keybit[0xC7]=0x02;

  keyindex[0xCF]=2; // end
  keybit[0xCF]=0x02;

  keyindex[0xB8]=6; // right alt
  keybit[0xB8]=0x10;

  keyindex[0xC9]=7; // page up
  keybit[0xC9]=0x10;

  keyindex[0xD1]=7; // page down
  keybit[0xD1]=0x40;

  keyindex[0xD2]=8; // insert
  keybit[0xD2]=0x04;

  keyindex[0xD3]=8; // delete
  keybit[0xD3]=0x08;

  keyindex[0x33]=2; // ,
  keybit[0x33]=0x04;

  keyindex[0x34]=2; // .
  keybit[0x34]=0x08;

  keyindex[0x35]=2; // /
  keybit[0x35]=0x10;

  keyindex[0x3A]=6; // caps
  keybit[0x3A]=0x08;

  keyindex[0x38]=6; // left alt
  keybit[0x38]=0x04;

  keyindex[0x3B]=6; // F1
  keybit[0x3B]=0x20;

  keyindex[0x3C]=6; // F2
  keybit[0x3C]=0x40;

  keyindex[0x3D]=6; // F3
  keybit[0x3D]=0x80;

  keyindex[0x3E]=7; // F4
  keybit[0x3E]=0x01;

  keyindex[0x3F]=7; // F5
  keybit[0x3F]=0x02;

  keyindex[0x0B]=0; // 0
  keybit[0x0B]=0x01;

  keyindex[0x02]=0; // 1
  keybit[0x02]=0x02;

  keyindex[0x03]=0; // 2
  keybit[0x03]=0x04;

  keyindex[0x04]=0; // 3
  keybit[0x04]=0x08;

  keyindex[0x05]=0; // 4
  keybit[0x05]=0x10;

  keyindex[0x06]=0; // 5
  keybit[0x06]=0x20;

  keyindex[0x07]=0; // 6
  keybit[0x07]=0x40;

  keyindex[0x08]=0; // 7
  keybit[0x08]=0x80;

  keyindex[0x09]=1; // 8
  keybit[0x09]=0x01;

  keyindex[0x0A]=1; // 9
  keybit[0x0A]=0x02;

  keyindex[0x10]=4; // Q
  keybit[0x10]=0x40;

  keyindex[0x11]=5; // W
  keybit[0x11]=0x10;

  keyindex[0x12]=3; // E
  keybit[0x12]=0x04;

  keyindex[0x13]=4; // R
  keybit[0x13]=0x80;

  keyindex[0x14]=5; // T
  keybit[0x14]=0x02;

  keyindex[0x15]=5; // Y
  keybit[0x15]=0x40;

  keyindex[0x16]=5; // U
  keybit[0x16]=0x04;

  keyindex[0x17]=3; // I
  keybit[0x17]=0x40;

  keyindex[0x18]=4; // O
  keybit[0x18]=0x10;

  keyindex[0x19]=4; // P
  keybit[0x19]=0x20;

  keyindex[0x1E]=2; // A
  keybit[0x1E]=0x40;

  keyindex[0x1F]=5; // S
  keybit[0x1F]=0x01;

  keyindex[0x20]=3; // D
  keybit[0x20]=0x02;

  keyindex[0x21]=3; // F
  keybit[0x21]=0x08;

  keyindex[0x22]=3; // G
  keybit[0x22]=0x10;

  keyindex[0x23]=3; // H
  keybit[0x23]=0x20;

  keyindex[0x24]=3; // J
  keybit[0x24]=0x80;

  keyindex[0x25]=4; // K
  keybit[0x25]=0x01;

  keyindex[0x26]=4; // L
  keybit[0x26]=0x02;

  keyindex[0x2C]=5; // Z
  keybit[0x2C]=0x80;

  keyindex[0x2D]=5; // X
  keybit[0x2D]=0x20;

  keyindex[0x2E]=3; // C
  keybit[0x2E]=0x01;

  keyindex[0x2F]=5; // V
  keybit[0x2F]=0x08;

  keyindex[0x30]=2; // B
  keybit[0x30]=0x80;

  keyindex[0x31]=4; // N
  keybit[0x31]=0x08;

  keyindex[0x32]=4; // M
  keybit[0x32]=0x04;

  keyindex[0x1C]=7; // enter
  keybit[0x1C]=0x80;

  keyindex[0x2A]=keyindex[0x36]=6; // shift
  keybit[0x2A]=keybit[0x36]=0x01;

  keyindex[0x1D]=keyindex[0x9D]=6; // control
  keybit[0x1D]=keybit[0x9D]=0x02;

  keyindex[0x01]=7; // esc
  keybit[0x01]=0x04;

  keyindex[0x4E]=9; // + keypad
  keybit[0x4E]=0x01;

  keyindex[0x4A]=9; // - keypad
  keybit[0x4A]=0x02;

  keyindex[0x37]=9; // * keypad
  keybit[0x37]=0x04;

  keyindex[0xB5]=9; // / keypad
  keybit[0xB5]=0x08;

}



void __fastcall Tmain_window::SpeedButton3Click(TObject *Sender)
{
  load_diskA();
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::LoadDiskImage1Click(TObject *Sender)
{
  load_diskA();

}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::MountDirectory1Click(TObject *Sender)
{
  time_enabled=0;
  while (running) {}
  if (Mount==NULL)
    Application->CreateForm(__classid(TMount), &Mount);

  Mount->ShowModal();
  time_enabled=1;
}
//---------------------------------------------------------------------------

void __fastcall Tmain_window::ApplicationEvents1Exception(TObject *Sender,
      Exception *E)
{
    if (( dynamic_cast<EInOutError*> ( E )) &&
	( E->Message == "I/O error 21" ))
    {
	Application->MessageBox( "No media in drive.",
        "BrMSX Warning", MB_ICONEXCLAMATION | MB_OK );
    }
    else
    {
	throw;
    }
}
//---------------------------------------------------------------------------

